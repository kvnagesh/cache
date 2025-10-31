module cache_tb;
  logic clk, rst_n;
  logic read, write;
  logic [31:0] addr, wdata, rdata;
  logic hit, miss;

  cache dut (
    .clk   (clk),
    .rst_n (rst_n),
    .read  (read),
    .write (write),
    .addr  (addr),
    .wdata (wdata),
    .rdata (rdata),
    .hit   (hit),
    .miss  (miss)
  );

  initial begin
    clk = 0; forever #5 clk = ~clk;
  end

  initial begin
    rst_n = 0;
    #20;
    rst_n = 1;
    // Read miss
    addr = 32'h0000_1000; read = 1; write = 0;
    #10;
    $display("Read addr 0x%08x: hit=%0d, miss=%0d, data=0x%08x", addr, hit, miss, rdata);

    // Write, then hit
    addr = 32'h0000_1000; read = 0; write = 1; wdata = 32'hDEADBEEF;
    #10;
    $display("Write addr 0x%08x: hit=%0d, miss=%0d", addr, hit, miss);

    // Read hit
    addr = 32'h0000_1000; read = 1; write = 0;
    #10;
    $display("Read addr 0x%08x: hit=%0d, miss=%0d, data=0x%08x", addr, hit, miss, rdata);

    #100 $finish;
  end
endmodule
