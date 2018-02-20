# Automatic conversion of Verilog to XML

.SUFFIXES:

SELF_FILE := $(shell realpath $(lastword $(MAKEFILE_LIST)))
SELF_DIR := $(shell realpath $(dir $(lastword $(MAKEFILE_LIST))))
INC_MAKEFILE := $(shell realpath $(word $(shell echo $(words $(MAKEFILE_LIST))-1 | bc),$(MAKEFILE_LIST)))
INC_MAKEFILE_DIR := $(dir INC_MAKEFILE)

PB_TYPE_GEN_CMD = $(shell realpath $(SELF_DIR)/../../utils/vlog/vlog_to_pbtype.py)
MODEL_GEN_CMD = $(shell realpath $(SELF_DIR)/../../utils/vlog/vlog_to_model.py)

SIM_VERILOG := $(sort $(wildcard *.v))
PB_TYPE_XML := $(patsubst sim%.v,pb_type%.xml,$(SIM_VERILOG))

ifeq ($(USE_W), y)
PB_TYPE_XML := $(filter-out pb_type.xml, $(PB_TYPE_XML))
MODEL_SRC = sim_clean.v
else
MODEL_SRC = sim.v
endif

ifeq ($(GEN_MODEL), y)
MODEL_XML=model.xml
PB_TYPE_XML := $(filter-out pb_type_clean.xml, $(PB_TYPE_XML))
else
MODEL_XML=
endif

# Default top level module is directory name, a reasonable assumption for non-W
# modules. Can be overriden if needed
TOP_MODULE ?= $(notdir $(patsubst %/,%,$(INC_MAKEFILE_DIR)))

pb_type.%.xml: sim.%.v
	$(PB_TYPE_GEN_CMD) --top $* -o $@ $<

pb_type.xml: sim.v
	$(PB_TYPE_GEN_CMD) --top $(TOP_MODULE) -o $@ $<

sim_clean.v: sim.v
	sed 's/{W}/W/' $< > sim_clean.v

model.xml: $(MODEL_SRC)
	$(MODEL_GEN_CMD) --top $(TOP_MODULE) -o $@ $<

clean:
	rm -f $(PB_TYPE_XML) $(MODEL_XML) sim_clean.v

all: $(PB_TYPE_XML) $(MODEL_XML)

.DEFAULT_GOAL := all
