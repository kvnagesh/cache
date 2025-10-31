# 128KB 4-Way Set-Associative Cache

A fully parameterized SystemVerilog implementation of a 128KB, 4-way set-associative cache with tree-based pseudo-LRU (PLRU) replacement policy.

## Features

- **Cache Size**: 128KB total capacity
- **Associativity**: 4-way set-associative
- **Block Size**: Configurable (default 64 bytes)
- **Address Width**: 32-bit physical addresses
- **Replacement Policy**: Efficient tree-based pseudo-LRU (PLRU)
- **Interface**: Standard read/write with hit/miss signals
- **Reset**: Asynchronous active-low reset

## Architecture Overview

### Cache Organization

```
Total Cache Size: 128KB
Ways: 4
Block Size: 64 bytes (default)
Sets per Way: 128KB / (64 bytes × 4 ways) = 512 sets

Address Breakdown (32-bit):
- Tag: bits [31:15] (17 bits)
- Index: bits [14:6] (9 bits for 512 sets)
- Offset: bits [5:0] (6 bits for 64-byte blocks)
```

### Tree-Based Pseudo-LRU (PLRU)

The cache implements an efficient tree-based PLRU replacement policy for 4-way associativity:

```
        plru[0]
       /        \
   plru[1]    plru[2]
   /    \      /    \
 Way0  Way1  Way2  Way3
```

**PLRU Bits (3 bits per set)**:
- `plru[0]`: Root - points to left (0) or right (1) subtree
- `plru[1]`: Left child - points to Way0 (0) or Way1 (1)
- `plru[2]`: Right child - points to Way2 (0) or Way3 (1)

**Victim Selection**:
- Follow the tree path indicated by the bits
- Example: If `plru = 3'b101`, victim is Way3 (right→right)

**Update on Access**:
- Point away from the accessed way
- Way0 accessed → `plru[0]=0, plru[1]=0` (point right at root, to Way1 at left child)
- Way3 accessed → `plru[0]=1, plru[2]=1` (point left at root, to Way2 at right child)

## Module Interface

### Parameters

```systemverilog
parameter ADDR_WIDTH = 32          // Physical address width
parameter CACHE_SIZE_BYTES = 128 * 1024  // Total cache size
parameter BLOCK_SIZE_BYTES = 64    // Cache block/line size
parameter WAYS = 4                 // Associativity
```

### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | Input | 1 | Clock signal |
| `rst_n` | Input | 1 | Active-low asynchronous reset |
| `read` | Input | 1 | Read enable |
| `write` | Input | 1 | Write enable |
| `addr` | Input | 32 | Physical address |
| `wdata` | Input | 32 | Write data |
| `rdata` | Output | 32 | Read data |
| `hit` | Output | 1 | Cache hit indicator |
| `miss` | Output | 1 | Cache miss indicator |

## File Structure

```
cache/
├── cache.sv       # Main cache module implementation
├── cache_tb.sv    # Simple functional testbench
└── README.md      # This documentation
```

## Usage

### Instantiation Example

```systemverilog
cache #(
  .ADDR_WIDTH(32),
  .CACHE_SIZE_BYTES(128 * 1024),
  .BLOCK_SIZE_BYTES(64),
  .WAYS(4)
) my_cache (
  .clk(clk),
  .rst_n(rst_n),
  .read(read_en),
  .write(write_en),
  .addr(address),
  .wdata(write_data),
  .rdata(read_data),
  .hit(cache_hit),
  .miss(cache_miss)
);
```

### Operation

1. **Reset**: Assert `rst_n = 0` to initialize all valid bits to 0
2. **Read**: Set `read = 1`, provide `addr`, check `hit/miss`, retrieve `rdata`
3. **Write**: Set `write = 1`, provide `addr` and `wdata`, check `hit/miss`
4. **Hit**: Data found in cache, `hit = 1`, `miss = 0`
5. **Miss**: Data not found, victim way selected via PLRU, `hit = 0`, `miss = 1`

## Simulation

### Running the Testbench

```bash
# Using ModelSim/QuestaSim
vlog cache.sv cache_tb.sv
vsim -c cache_tb -do "run -all; quit"

# Using VCS
vcs cache.sv cache_tb.sv
./simv

# Using Verilator
verilator --lint-only cache.sv
```

### Testbench Coverage

The included `cache_tb.sv` provides basic functional verification:
- Reset sequence
- Read miss scenario
- Write operation
- Read hit scenario

**For comprehensive verification, consider:**
- Random address generation
- Conflict testing (same index, different tags)
- Capacity testing (filling all ways)
- PLRU behavior verification
- Corner cases (boundary addresses)

## Design Considerations

### Advantages

✅ **Hardware Efficient**: Tree-based PLRU uses only 3 bits per set (vs. 24 bits for true LRU)  
✅ **Fast**: Victim selection in constant time O(1)  
✅ **Parameterized**: Easy to adjust cache size, block size, associativity  
✅ **Standard Interface**: Simple read/write control signals  

### Limitations

⚠️ **Single-Port**: Only one read or write per cycle  
⚠️ **No Write-Back**: Current implementation is write-through style  
⚠️ **No Dirty Bits**: No distinction between clean/dirty lines  
⚠️ **Word-Level Granularity**: Data array organized as 32-bit words  

## Future Enhancements

- [ ] Add write-back policy with dirty bits
- [ ] Implement write buffers
- [ ] Support for burst transfers
- [ ] AXI4 interface integration
- [ ] Multi-port support
- [ ] Performance counters (hits, misses, evictions)
- [ ] Parity/ECC for error detection

## References

- **Pseudo-LRU**: "Computer Architecture: A Quantitative Approach" by Hennessy & Patterson
- **Cache Design**: "Digital Design and Computer Architecture" by Harris & Harris

## License

MIT License - Feel free to use and modify for your projects.

## Author

Developed as part of cache architecture exploration.

---

**Questions or Issues?** Please open an issue in the repository.
