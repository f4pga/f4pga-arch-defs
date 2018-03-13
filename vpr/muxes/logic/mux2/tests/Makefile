
TOPLEVEL_LANG ?= verilog

ifeq ($(origin COCOTB), undefined)
$(error "COCOTB must be defined")
endif

ifeq ($(OS),Msys)
WPWD=$(shell sh -c 'pwd -W')
PYTHONPATH := $(WPWD)/../model;$(PYTHONPATH)
else
WPWD=$(shell pwd)
PYTHONPATH := $(WPWD)/../model:$(PYTHONPATH)
endif

VERILOG_SOURCES = $(WPWD)/../mux2.sim.v

TOPLEVEL := MUX2
MODULE   := test_mux2

include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim
