# Minitest for PS7 AXI lite and PL2PS interrupts

## Description

This test allows to verify that connection between PS7 to PL is working on hardware.

The test instantiates a simple AXI lite peripheral and connects it to PS7 GP0 AXI bus.
The peripheral's base address is 0x40000000.
The peripheral implements 8 32-bit registers accessible via AXI bus.
Bits 0 and 1 of the register 0 are routed to Zybo's leds 0 and 1 respectively.
Bit 4 of register 0 is routed to lsb bit of the PS7 PL2PS interrupt input.

Axi peripheral has been implemented in Chisel3. This repository holds only generated verilog file.
The original source can be found in the [simple-chisel-axi-peripheral](https://github.com/antmicro/simple-chisel-axi-peripheral) repository (commit ffa093a8246361d475afcf2aec9bc032d1d6c723)
