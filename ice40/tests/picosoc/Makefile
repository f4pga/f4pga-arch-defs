BOARD ?= hx8k-b-evn
ARCH = ice40

TOP = hx8kdemo

SOURCES = \
	hx8kdemo.v \
	picosoc.v \
	picorv32.v \
	simpleuart.v \
	spimemio.v

TESTBENCH_SOURCES = \
	hx8kdemo_tb.v \
	spiflash.v

include ../../../make/tests.mk

firmware.hex: firmware.elf
	riscv32-unknown-elf-objcopy -O verilog firmware.elf /dev/stdout | sed -e '1 s/@00000000/@00100000/; 2,65537 d;' > firmware.hex

firmware.bin: firmware.elf
	riscv32-unknown-elf-objcopy -O binary firmware.elf /dev/stdout | tail -c +1048577 > firmware.bin

prog-firmware: firmware.hex
	$(ICEPROG_TOOL) -o 1M firmware.bin
.PHONY: prog-firmware


prog-all: prog prog-firmware
	@true
.PHONY: prog-all
