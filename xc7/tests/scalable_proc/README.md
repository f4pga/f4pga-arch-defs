# Scalable processing

This is a design that does the following:

- Reads a number of 32-bit words from ROM (an initialized BRAM)
- Processes them in parallel using N "processing units"
- Transmitts processing results through UART as HEX numbers

The number of processing units can be set and therefore the design can be scaled up in size. There is a clock divider which divides the input clock by 2^k, where k >= 1.

Currently the ROM stores a pair of 16-bit numbers on each 32-bit word. A processing unit multiplies these two numbers and outputs the result as a 32-bit number.

## Testing output

- Run the _receiver.py_ script from _utils_ subfolder, provide correct serial port device and baudrate
- Observe the output

Curently the baudate is set to **9600** and clock division to **7 (1/128)**. The input clock frequency is assumed to be **100MHz**