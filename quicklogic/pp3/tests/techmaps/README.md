# LUT -> MUX tree techmap test suite

This is a small test suite for verification of LUT to MUX tree conversion. The flow is as following:

1. The python script `lut_testgen.v` generates a design with multiple LUTn cells. Each one is initialized with different data.
2. Yosys is used to perform techmapping and convert all LUTs to INV+MUX gate tree
3. A miter circuit is generated for both designs using Yosys
4. The miter circut is simulated by Icarus verilog and 1-to-1 correspondence between outputs of LUT and INV+MUX implementation is verified.