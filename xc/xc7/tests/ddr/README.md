# UART-DDR test

The `test_sdram.py` script in the `scripts` directory performs a calibration step with the `DDR` and calculates what are the correct bitslip and delay values to be assigned.

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

### Output

Depending on the clock frequency selected during the gateware generation, different outputs are generated:

- 50 MHz sysytem clock:

    ```
    Minimal Arty DDR3 Design for tests with Project X-Ray 2020-02-03 11:30:24
    Release reset
    Bring CKE high
    Load Mode Register 2, CWL=5
    Load Mode Register 3
    Load Mode Register 1
    Load Mode Register 0, CL=6, BL=8
    ZQ Calibration
    bitslip 0: |..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|31|
    bitslip 1: |..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|
    bitslip 2: |..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|
    bitslip 3: |..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|
    bitslip 4: |..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|
    bitslip 5: |..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|
    bitslip 6: |..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|
    bitslip 7: |..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|
    ```

- 100 MHz system clock:


    ```
    Minimal Arty DDR3 Design for tests with Project X-Ray 2020-01-31 15:41:14
    Release reset
    Bring CKE high
    Load Mode Register 2, CWL=5
    Load Mode Register 3
    Load Mode Register 1
    Load Mode Register 0, CL=6, BL=8
    ZQ Calibration
    bitslip 0: |00|01|02|03|04|05|06|07|08|09|10|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|
    bitslip 1: |..|..|..|..|..|..|..|..|..|..|..|..|..|13|14|15|16|17|18|19|20|21|22|23|24|25|..|..|..|..|..|..|
    bitslip 2: |..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|29|30|31|
    bitslip 3: |..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|
    bitslip 4: |..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|
    bitslip 5: |..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|
    bitslip 6: |..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|
    bitslip 7: |..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|..|
    ```
