# 7-series support

This directory contains 7-series specific architecture definitions.

## Examples

The following examples are testing on basys3:

* xc7/tests/buttons - Connects switches/buttons to LEDs
* xc7/tests/simple_ff - Connects the inputs and outputs of an FF to switches and LEDs
* xc7/tests/counter - Displays a counter on 5 LEDs
* xc7/tests/ram_test - Runs a simple RAM test against a 64x1 DRAM instance.  Results arrive on UART (500k baud).

### Running examples

After creating a cmake build directory (running make env in root), cd into example and run:

```
make <example name>_<board name>_bin
```

to generate a bitstream.  To program the bitstream via OpenOCD run:

```
make <example name>_<board name>_prog
```

Additional targets are best explored via tab completion.

Full example for buttons:

```
git clone https://github.com/SymbiFlow/symbiflow-arch-defs.git
cd symbiflow-arch-defs
make env
cd build
cd xc7/tests/buttons
make buttons_basys3_bin
```
