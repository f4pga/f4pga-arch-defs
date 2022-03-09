
## Distributed RAM Configurations

| Shape     | Ports   | Primitive | LUTs |
|-----------|---------|-----------|------|
| 32 × 1S   | Single  | RAM32X1S  | 1    |
| 32 × 1D   | Dual    | RAM32X1D  | 2    |
| 32 × 2Q   | Quad    | RAM32M    | 4    |
| 32 × 6SDP | Dual#   | RAM32M    | 4    |
| 64 × 1S   | Single  | RAM64X1S  | 1    |
| 64 × 1D   | Dual    | RAM64X1D  | 2    |
| 64 × 1Q   | Quad    | RAM64M    | 4    |
| 64 × 3SDP | Dual#   | RAM64M    | 4    |
| 128 × 1S  | Single  | RAM128X1S | 2    |
| 128 × 1D  | Dual    | RAM128X1D | 4    |
| 256 × 1S  | Single  | RAM256X1S | 4    |

 * # "Simple" Dual port ram.

### Synchronous Write Operation

> The synchronous write operation is a single clock-edge operation with an
> active-High write-enable (WE) feature. When WE is High, the input (D) is
> loaded into the memory location at address A.

### Asynchronous Read Operation

> The output is determined by the address A for the single-port mode output SPO
> of dual-port mode, or address DPRA for the DPO output of dual-port mode. Each
> time a new address is applied to the address pins, the data value in the
> memory location of that address is available on the output after the time
> delay to access the LUT. This operation is asynchronous and independent of
> the clock signal.

### Single port

 * Port A - Read/Write
  - Async reads
  - Sync writes
  - Read+write share address port

### Dual port

 * Port A - Read/Write
  - Async reads
  - Sync writes
  - Read+write share address port

 * Port B - Read only
  - Async reads

Dual port
• One port for synchronous writes and asynchronous reads
  - One function generator is connected with the shared read and write port address
• One port for asynchronous reads
  - Second function generator has the A inputs connected to a second read-only port address, and the WA inputs are shared with the first read/write port address


### "Simple" Dual Port

 * Port A - Write only
  - Sync writes
 * Port B - Read only
  - Async reads

### Quad Port

 * Port A - Read/Write
   - Sync write
   - Async reads
 * Port B, C, D - Read only
   - Async read

