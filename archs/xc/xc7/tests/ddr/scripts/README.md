# UART-DDR test

The `test_sdram.py` script performs a calibration step with the `DDR` and calculates what are the correct bitslip and delay values to be assigned.

### Prerequisites

To be able to perform the test, make sure to clone the `litex` repository, as it contains the `RemoteClient` library to be able to correctly run the test.
If you do not have the litex dependency on your machine, do the following:

```
git clone https://github.com/enjoy-digital/litex.git
```

To test the design, do the following:

1. Open a new terminal and open a litex server (Note that `X` in the `ttyUSBX` needs to be replaced with the enabled device on your local machine):

```
lxserver --uart --uart-port=/dev/ttyUSBX
```

2. On the previous terminal start the client script:

```
./test_sdram.py
```
