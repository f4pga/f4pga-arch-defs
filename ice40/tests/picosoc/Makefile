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
