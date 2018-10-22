# Logic table for `LUT6_2`

I0 .. I5 are the LUT inputs.
O5 and O6 are the LUT outputs.

INIT is 64-bit hex value.

```verilog
module LUT6_2 (O6, O5, I0, I1, I2, I3, I4, I5);

  output wire O6;
  output wire O5;
  input wire I0;
  input wire I1;
  input wire I2;
  input wire I3;
  input wire I4;
  input wire I5;

  parameter [63:0] INIT = 64'h0000000000000000;

endmodule
```


| I5 | I4 | I3 | I2 | I1 | I0 | O5       | O6       |
|----|----|----|----|----|----|----------|----------|
|  0 |  0 |  0 |  0 |  0 |  0 | INIT[ 0] | INIT[ 0] |
|  0 |  0 |  0 |  0 |  0 |  1 | INIT[ 1] | INIT[ 1] |
|  0 |  0 |  0 |  0 |  1 |  0 | INIT[ 2] | INIT[ 2] |
|  0 |  0 |  0 |  0 |  1 |  1 | INIT[ 3] | INIT[ 3] |
|  0 |  0 |  0 |  1 |  0 |  0 | INIT[ 4] | INIT[ 4] |
|  0 |  0 |  0 |  1 |  0 |  1 | INIT[ 5] | INIT[ 5] |
|  0 |  0 |  0 |  1 |  1 |  0 | INIT[ 6] | INIT[ 6] |
|  0 |  0 |  0 |  1 |  1 |  1 | INIT[ 7] | INIT[ 7] |
|  0 |  0 |  1 |  0 |  0 |  0 | INIT[ 8] | INIT[ 8] |
|  0 |  0 |  1 |  0 |  0 |  1 | INIT[ 9] | INIT[ 9] |
|  0 |  0 |  1 |  0 |  1 |  0 | INIT[10] | INIT[10] |
|  0 |  0 |  1 |  0 |  1 |  1 | INIT[11] | INIT[11] |
|  0 |  0 |  1 |  1 |  0 |  0 | INIT[12] | INIT[12] |
|  0 |  0 |  1 |  1 |  0 |  1 | INIT[13] | INIT[13] |
|  0 |  0 |  1 |  1 |  1 |  0 | INIT[14] | INIT[14] |
|  0 |  0 |  1 |  1 |  1 |  1 | INIT[15] | INIT[15] |
|  0 |  1 |  0 |  0 |  0 |  0 | INIT[16] | INIT[16] |
|  0 |  1 |  0 |  0 |  0 |  1 | INIT[17] | INIT[17] |
|  0 |  1 |  0 |  0 |  1 |  0 | INIT[18] | INIT[18] |
|  0 |  1 |  0 |  0 |  1 |  1 | INIT[19] | INIT[19] |
|  0 |  1 |  0 |  1 |  0 |  0 | INIT[20] | INIT[20] |
|  0 |  1 |  0 |  1 |  0 |  1 | INIT[21] | INIT[21] |
|  0 |  1 |  0 |  1 |  1 |  0 | INIT[22] | INIT[22] |
|  0 |  1 |  0 |  1 |  1 |  1 | INIT[23] | INIT[23] |
|  0 |  1 |  1 |  0 |  0 |  0 | INIT[24] | INIT[24] |
|  0 |  1 |  1 |  0 |  0 |  1 | INIT[25] | INIT[25] |
|  0 |  1 |  1 |  0 |  1 |  0 | INIT[26] | INIT[26] |
|  0 |  1 |  1 |  0 |  1 |  1 | INIT[27] | INIT[27] |
|  0 |  1 |  1 |  1 |  0 |  0 | INIT[28] | INIT[28] |
|  0 |  1 |  1 |  1 |  0 |  1 | INIT[29] | INIT[29] |
|  0 |  1 |  1 |  1 |  1 |  0 | INIT[30] | INIT[30] |
|  0 |  1 |  1 |  1 |  1 |  1 | INIT[31] | INIT[31] |
|  1 |  0 |  0 |  0 |  0 |  0 | INIT[ 0] | INIT[32] |
|  1 |  0 |  0 |  0 |  0 |  1 | INIT[ 1] | INIT[33] |
|  1 |  0 |  0 |  0 |  1 |  0 | INIT[ 2] | INIT[34] |
|  1 |  0 |  0 |  0 |  1 |  1 | INIT[ 3] | INIT[35] |
|  1 |  0 |  0 |  1 |  0 |  0 | INIT[ 4] | INIT[36] |
|  1 |  0 |  0 |  1 |  0 |  1 | INIT[ 5] | INIT[37] |
|  1 |  0 |  0 |  1 |  1 |  0 | INIT[ 6] | INIT[38] |
|  1 |  0 |  0 |  1 |  1 |  1 | INIT[ 7] | INIT[39] |
|  1 |  0 |  1 |  0 |  0 |  0 | INIT[ 8] | INIT[40] |
|  1 |  0 |  1 |  0 |  0 |  1 | INIT[ 9] | INIT[41] |
|  1 |  0 |  1 |  0 |  1 |  0 | INIT[10] | INIT[42] |
|  1 |  0 |  1 |  0 |  1 |  1 | INIT[11] | INIT[43] |
|  1 |  0 |  1 |  1 |  0 |  0 | INIT[12] | INIT[44] |
|  1 |  0 |  1 |  1 |  0 |  1 | INIT[13] | INIT[45] |
|  1 |  0 |  1 |  1 |  1 |  0 | INIT[14] | INIT[46] |
|  1 |  0 |  1 |  1 |  1 |  1 | INIT[15] | INIT[47] |
|  1 |  1 |  0 |  0 |  0 |  0 | INIT[16] | INIT[48] |
|  1 |  1 |  0 |  0 |  0 |  1 | INIT[17] | INIT[49] |
|  1 |  1 |  0 |  0 |  1 |  0 | INIT[18] | INIT[50] |
|  1 |  1 |  0 |  0 |  1 |  1 | INIT[19] | INIT[51] |
|  1 |  1 |  0 |  1 |  0 |  0 | INIT[20] | INIT[52] |
|  1 |  1 |  0 |  1 |  0 |  1 | INIT[21] | INIT[53] |
|  1 |  1 |  0 |  1 |  1 |  0 | INIT[22] | INIT[54] |
|  1 |  1 |  0 |  1 |  1 |  1 | INIT[23] | INIT[55] |
|  1 |  1 |  1 |  0 |  0 |  0 | INIT[24] | INIT[56] |
|  1 |  1 |  1 |  0 |  0 |  1 | INIT[25] | INIT[57] |
|  1 |  1 |  1 |  0 |  1 |  0 | INIT[26] | INIT[58] |
|  1 |  1 |  1 |  0 |  1 |  1 | INIT[27] | INIT[59] |
|  1 |  1 |  1 |  1 |  0 |  0 | INIT[28] | INIT[60] |
|  1 |  1 |  1 |  1 |  0 |  1 | INIT[29] | INIT[61] |
|  1 |  1 |  1 |  1 |  1 |  0 | INIT[30] | INIT[62] |
|  1 |  1 |  1 |  1 |  1 |  1 | INIT[31] | INIT[63] |
