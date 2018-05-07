include $(TOP_DIR)/make/inc/env.mk

VERILOG_SOURCES = $(CURDIR)/../mux2.sim.v
TOPLEVEL := MUX2
MODULE   := test_mux2

include $(COCOTB)/makefiles/Makefile.inc

PYTHONPATH := $(CURDIR):$(PYTHONPATH):$(PYTHON_DYNLIBDIR)

include $(COCOTB)/makefiles/Makefile.sim
