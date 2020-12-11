# Minitest for Litex/VexRiscv system booting Linux on Zynq device

## Description

This test allows to verify that connection between PS7 to PL is working on hardware.

The test instantiates Litex system with VexRiscv CPU.
The system connects to PS7 slave AXI bus and uses PS7 DDR.
Litex/VexRiscv system is able to boot Linux.
