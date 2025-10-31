module cache #(
  parameter ADDR_WIDTH = 32,
  parameter CACHE_SIZE_BYTES = 128 * 1024,
  parameter BLOCK_SIZE_BYTES = 64,
  parameter WAYS = 4
)(
  input logic clk,
  input logic rst_n,
  input logic read,
  input logic write,
  input logic [ADDR_WIDTH-1:0] addr,
  input logic [31:0] wdata,
  output logic [31:0] rdata,
  output logic hit,
  output logic miss
);

  localparam BLOCKS_PER_WAY = CACHE_SIZE_BYTES / (BLOCK_SIZE_BYTES * WAYS);
  localparam INDEX_WIDTH = $clog2(BLOCKS_PER_WAY);
  localparam OFFSET_WIDTH = $clog2(BLOCK_SIZE_BYTES);
  localparam TAG_WIDTH = ADDR_WIDTH - INDEX_WIDTH - OFFSET_WIDTH;

  // Tag and valid arrays
  logic [TAG_WIDTH-1:0] tag_array[WAYS][BLOCKS_PER_WAY];
  logic [WAYS-1:0][BLOCKS_PER_WAY-1:0] valid_array;
  logic [31:0] data_array[WAYS][BLOCKS_PER_WAY][BLOCK_SIZE_BYTES/4];

  // Tree-based pseudo-LRU: 3 bits/set for 4 ways
  logic [2:0] plru_bits[BLOCKS_PER_WAY];

  // Address decode
  logic [TAG_WIDTH-1:0] addr_tag;
  logic [INDEX_WIDTH-1:0] addr_index;
  logic [OFFSET_WIDTH-1:0] addr_offset;
  assign addr_tag    = addr[ADDR_WIDTH-1:ADDR_WIDTH-TAG_WIDTH];
  assign addr_index  = addr[ADDR_WIDTH-TAG_WIDTH-1:OFFSET_WIDTH];
  assign addr_offset = addr[OFFSET_WIDTH-1:0];

  integer i, w;
  logic found;
  logic [WAYS-1:0] way_hit;
  logic [1:0] replace_way;

  always_comb begin
    found = 0;
    way_hit = 0;
    hit = 0;
    miss = 1;
    for (w = 0; w < WAYS; w++) begin
      if (valid_array[w][addr_index] && tag_array[w][addr_index] == addr_tag) begin
        way_hit[w] = 1;
        found = 1;
        hit = 1;
        miss = 0;
      end
    end
  end

  // Efficient Tree-based PLRU (documented logic):
  // For 4 ways (A,B,C,D): root (plru[0]), left child (plru[1]), right child (plru[2])
  function automatic [1:0] plru_get_victim(input logic [2:0] plru);
    return plru[0] ? (plru[2] ? 3 : 2) : (plru[1] ? 1 : 0);
  endfunction

  task automatic plru_update(
    inout logic [2:0] plru,
    input logic [1:0] accessed_way
  );
    case (accessed_way)
      0: begin plru[0]=0; plru[1]=0; end
      1: begin plru[0]=0; plru[1]=1; end
      2: begin plru[0]=1; plru[2]=0; end
      3: begin plru[0]=1; plru[2]=1; end
      default: ;
    endcase
  endtask

  // Main cache controller
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (w = 0; w < WAYS; w++)
        for (i = 0; i < BLOCKS_PER_WAY; i++) begin
          valid_array[w][i] <= 0;
          tag_array[w][i]   <= 0;
        end
    end else begin
      if (read || write) begin
        if (hit) begin
          for (w = 0; w < WAYS; w++) begin
            if (way_hit[w]) plru_update(plru_bits[addr_index], w[1:0]);
          end
          if (read) begin
            for (w = 0; w < WAYS; w++)
              if (way_hit[w])
                rdata <= data_array[w][addr_index][addr_offset/4];
          end
          if (write) begin
            for (w = 0; w < WAYS; w++)
              if (way_hit[w]) begin
                data_array[w][addr_index][addr_offset/4] <= wdata;
              end
          end
        end else begin
          replace_way = plru_get_victim(plru_bits[addr_index]);
          tag_array[replace_way][addr_index]    <= addr_tag;
          valid_array[replace_way][addr_index]  <= 1;
          if (write)
            data_array[replace_way][addr_index][addr_offset/4] <= wdata;
          else
            rdata <= data_array[replace_way][addr_index][addr_offset/4];
          plru_update(plru_bits[addr_index], replace_way);
        end
      end
    end
  end
endmodule
