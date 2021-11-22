Zynq 7020 support in SymbiFlow
==============================

SymbiFlow supports several boards featuring a Zynq-7020 FPGA.
Several example projects spanning from simple buttons or counter tests up to booting Linux have been added to verify that the toolchain is capable of producing a bitstream for any of these designs that  works on hardware.
This readme describes the steps needed to generate and upload the bitstream with one of the exmple projects for any of the supported boards.
The list of currently supported boards is as follows:

* `Digilent Pynq-Z1 <https://reference.digilentinc.com/reference/programmable-logic/pynq-z1/start>`_
* `Enclustra Mars-ZX3 <https://www.enclustra.com/en/products/system-on-chip-modules/mars-zx3>`_
* `Avnet MicroZed <http://zedboard.org/product/microzed>`_
* `Digilent ZedBoard <https://store.digilentinc.com/zedboard-zynq-7000-arm-fpga-soc-development-board>`_
* `Digilent Zybo Z7-20 <https://store.digilentinc.com/zybo-z7-zynq-7000-arm-fpga-soc-development-board>`_


Running examples
----------------

Everything needed to use SymbiFlow for the supported Zynq boards can be found in the `SymbiFlow Architecture Definition <https://github.com/SymbiFlow/symbiflow-arch-defs>`_ repository.
The repository contains the architecture definition of the programmable logic (PL) part of the Zynq device.
The basic example projects for the Zynq boards are placed in `xc7/tests/counter` or `xc7/tests/buttons` directories.
The more advanced including the Linux capable Litex system can be found in `xc7/tests/ps7`.

Basic examples
--------------

The simplest tests demonstrate the basic connections of inputs, outputs and clocks.

Buttons
+++++++

In this test the switches that are available on the platform are connected to some of the available LEDs.
The project is placed in the `xc7/tests/buttons` directory.
To test it on hardware the only steps that are required is generating the bitstream and loadinging it to the target board.
The commands needed to be run for a specific board are as follows:

Pynq-Z1
*******

#. Generate the bitstream - ``make buttons_pynqz1_bin`` - the final bitstream called ``top.bit`` will be available in ``buttons_pynqz1`` directory.
#. Program the target board - ``make buttons_pynqz1_prog``

Mars-ZX3
********

#. Generate the bitstream - ``make buttons_marszx3_bin`` - the final bitstream called ``top.bit`` will be available in ``buttons_marszx3`` directory.
#. Program the target board - ``make buttons_marszx3_prog``

MicroZed
********

#. Generate the bitstream - ``make buttons_microzed_bin`` - the final bitstream called ``top.bit`` will be available in ``buttons_microzed`` directory.
#. Program the target board - ``make buttons_microzed_prog``

ZedBoard
********

#. Generate the bitstream - ``make buttons_zedboard_bin`` - the final bitstream called ``top.bit`` will be available in ``buttons_zedboard`` directory.
#. Program the target board - ``make buttons_zedboard_prog``

Counter
+++++++

In this test the current state of a counter register is displayed on the LEDs available on the platform.
The project is placed in the `xc7/tests/counter` directory.
To test it on hardware the only steps that are required is generating the bitstream and loadinging it to the target board.
The commands needed to be run for a specific board are as follows:

Pynq-Z1
*******

#. Generate the bitstream - ``make counter_pynqz1_bin`` - the final bitstream called ``top.bit`` will be available in ``counter_pynqz1`` directory.
#. Program the target board - ``make counter_pynqz1_prog``

Mars-ZX3
********

#. Generate the bitstream - ``make counter_marszx3_bin`` - the final bitstream called ``top.bit`` will be available in ``counter_marszx3`` directory.
#. Program the target board - ``make counter_marszx3_prog``

MicroZed
********

#. Generate the bitstream - ``make counter_microzed_bin`` - the final bitstream called ``top.bit`` will be available in ``counter_microzed`` directory.
#. Program the target board - ``make counter_microzed_prog``

ZedBoard
********

#. Generate the bitstream - ``make counter_zedboard_bin`` - the final bitstream called ``top.bit`` will be available in ``counter_zedboard`` directory.
#. Program the target board - ``make counter_zedboard_prog``


Advanced examples
-----------------

These examples use the U-Boot bootloader running on the Zynq Processing System (PS) to load the bitstream for the programmable logic (PL).

AXI Lite
++++++++

This test is located in the ``xc7/tests/ps7/axi_lite_reg`` directory and it instantiates a simple AXI lite peripheral and connects it to the PS7's GP0 AXI bus.
The peripheral's base address is 0x40000000.
It implements 8 32-bit registers accesible via the AXI bus.

Zybo-Z7
*******

On this board the bits 0 and 1 of the first AXI register are connected to LED0 and LED1 respectively.
The bistream is loaded from the U-Boot bootloader which is loaded during boot that is performed from the SD card.
The design can be verified on hardware by performing some simple write/read tests in U-Boot.
The steps that are needed to test the design are as follows:

#. Generate the bitstream - ``make axi_regs_zybo_bin`` - the final bitstream called ``top.bit`` will be available in ``axi_regs_zybo`` directory.
#. Follow the `[official guide] <https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18842385/How+to+format+SD+card+for+SD+boot>`_ to prepare the SD card.
#. Build the U-Boot bootloader and copy to the SD card along with the ``top.bit`` bitstream.
#. Power-up the board with the SD card inserted into the slot.
#. Switch on the LEDs from U-Boot - ``mw.w 0x40000000 0x3``.
#. Verify that the content of the register reflects the state of the LEDs - ``mw.r 0x40000000``.


Linux on Litex
++++++++++++++

This test is located in the ``xc7/tests/ps7/linux_litex`` directory and it features a Litex system with a VexRiscv CPU that connects to the PS7's slave AXI bus in order to use PS7 DDR interface.
The Litex/VexRiscv system is able to boot linux.

Zybo-Z7
*******

Since this board boots from the SD card it has to be prepared correctly.
The steps needed to run the test are as follows:

#. Generate the bitstream - ``make linux_litex_zybo_bin`` - the final bitstream called ``top.bit`` will be available in ``linux_litex_zybo`` directory.
#. Prepare the SD card by following the `[official guide] <https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18842385/How+to+format+SD+card+for+SD+boot>`_).
#. Build the U-Boot bootloader and the Linux kernel and copy them onto the SD card.
#. Power-up the board with the SD card inserted into the slot.
#. Stop U-Boot autoboot by pressing any key during countdown and in U-Boot's console run the following commands::

        setenv booargs "root=/dev/mmcblk0p2 rw rootwait"
        setenv bootcmd "load mmc 0 0x1000000 uImage && load mmc 0 0x2000000 devicetree.dtb && bootm 0x1000000 - 0x2000000"
