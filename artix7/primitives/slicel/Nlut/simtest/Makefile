
TOPLEVEL_LANG ?= verilog

COCOTB ?= ../../../../../third_party/cocotb
ICARUS_BIN_DIR ?= ../../../../../env/conda/bin

ifeq ($(origin COCOTB), undefined)
$(error "COCOTB must be defined")
endif

ifeq ($(OS),Msys)
WPWD=$(shell sh -c 'pwd -W')
PYTHONPATH := $(WPWD);$(PYTHONPATH)
else
WPWD=$(shell pwd)
PYTHONPATH := $(WPWD):$(PYTHONPATH)
endif

VERILOG_SOURCES = $(WPWD)/../alut.sim.v

TOPLEVEL := ALUT
MODULE   := test_alut

COMPILE_ARGS += -PALUT.INIT=64\'b0101010101010101010101010101010101010101010101010101010101010101
include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim
