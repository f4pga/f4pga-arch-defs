# UART-DDR test

This test is to verify the correctness of DDR modules.
It comprehends:

- UART-DDR design, which is the minimum design possible to test the correct functioning of the DDR module;
- Testing script: under the `scripts` directory, there is a script that performs memory calibration, and is used to test the correctness of the design.

## Testing

To test the design, do the following:

```
cd scripts
make test_dram
```
