# Distributed RAM possible modes


| RAM       | Primitive    | Planned? | LUTs | Yosys    | Should work?   | Pack tested?   | Function tested? | Description                                 |
|-----------|--------------|----------|------|----------|----------------|----------------|------------------|---------------------------------------------|
| 32 x 1S   | `RAM32X1S`   | Yes      |   1  | Yes      | Yes            | Yes            |                  | Single-Port 32 x 1-bit RAM                  |
| 32 x 1S   | `RAM32X1S_1` | No       |   1  | No       | No (need mode) | No             |                  | Single-Port 32 x 1-bit RAM (inverted clock) |
| 32 x 1D   | `RAM32X1D`   | Yes      |   2  | Yes      | Yes            | Yes            |                  | Dual-Port 32 x 1-bit RAM                    |
| 32 x 2S   | `RAM32X2S`   | Yes      |   1  | Yes      | Yes            | Yes            |                  | Single-Port 32 x 2-bit RAM                  |
| 32 x 2Q   | `RAM32M`     | Yes      |   4  | Not yet^ | Yes            | No             |                  | Quad-Port 32 x 2-bit RAM                    |
| 32 x 6SDP | `RAM32M`     | Yes      |   4  | Not yet^ | Yes            | No             |                  | Simple Dual-Port 32 x 6-bit RAM             |
| 64 x 1S   | `RAM64X1S`   | Yes      |   1  | Yes      | Yes            | Yes            |                  | Single-Port 64 x 1-bit RAM                  |
| 64 x 1S   | `RAM64X1S_1` | No       |   1  | No       | No (need mode) | No             |                  | Single-Port 32 x 1-bit RAM (inverted clock) |
| 64 x 1D   | `RAM64X1D`   | Yes      |   2  | Yes      | Yes            | Yes            |                  | Dual-Port 64 x 1-bit RAM                    |
| 64 x 1Q   | `RAM64M`     | Yes      |   4  | Not yet^ | Yes            | No             |                  | Quad-Port 64 x 1-bit RAM                    |
| 64 x 3SDP | `RAM64M`     | Yes      |   4  | Not yet^ | Yes            | No             |                  | Simple Dual-Port 64 x 3-bit RAM             |
| 128 x 1S  | `RAM128X1S`  | Yes      |   2  | Yes      | Yes            | Yes            |                  | Single-Port 128 x 1-bit RAM                 |
| 128 x 1D  | `RAM128X1D`  | Yes      |   4  | Yes      | Yes            |                |                  | Dual-Port 128 x 1-bit RAM                   |
| 256 x 1S  | `RAM256X1S`  | Yes      |   4  | Yes      | Yes            | Yes            |                  | Single-Port 256 x 1-bit RAM                 |


 ^ - Need to model shorted inputs with CONNMAP
