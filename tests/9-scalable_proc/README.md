# Scalable processing

This is a design that does the following:

- Reads a number of 32-bit words from ROM (an initialized BRAM)
- Processes them in parallel using N "processing units"
- Transmitts processing results through UART as HEX numbers

The switch SW0 (V17) serves as a external reset.

The number of processing units can be set and therefore the design can be scaled up in size. There is a clock divider which divides the input clock by 2^k, where k >= 1.

Currently the ROM stores a pair of 16-bit numbers on each 32-bit word. A processing unit multiplies these two numbers and outputs the result as a 32-bit number.

The design outputs data as ASCII text line-by-line. Each line contain N 32-bit words delimited by space and is terminated with a single "\n" character.

## Testing output

- Run the _receiver.py_ script from _utils_ subfolder, provide correct serial port device and baudrate
- Observe the output

Curently the baudate is set to **500000**. The input clock frequency is assumed to be **100MHz**

Example script call:
```
receiver.py --port /dev/ttyUSB1 --baud 500000 --verbose 2
```

The script first simulates behavior of a processing unit and generates expected output. Then it receives data from UART and waits for synchronization. If at least 5 consecutive received words match first 5 words of the generated expected output then the stream considers to be in sync with the data pattern being received. Once synchronized the script continues comparing received vs. expected data and in case of a mismatch prints an error.
