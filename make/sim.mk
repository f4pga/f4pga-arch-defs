include make/inc/common.mk
include make/inc/files.mk
include make/inc/env.mk

SIM_NETLISTSVG_SKIN ?= $(NETLISTSVG)/lib/default.svg
SIM_NETLISTSVG_DPI  ?= 300

YOSYSSVG_DPI  ?= 300

VERILOG_FILES := $(call find_nontemplate_files,*.v)

SIM_DEPS := $(TOP_DIR)/make/sim.mk
SIM_PREFIX= $(subst .sim.v,,$(notdir $(PREREQ_FIRST)))
SIM_TOP   = $(call uc,$(SIM_PREFIX))

SIM_SVG_DEPS := $(SIM_NETLISTSVG_SKIN) $(SIM_NETLISTSVG_STAMP)

JSON_ENDINGS := %.bb.json %.aig.json %.flat.json

JSON_FILES := $(foreach JF,$(VERILOG_FILES),$(foreach JE,$(JSON_ENDINGS),$(subst .sim.v,,$(JF))$(subst %,,$(JE))))
SVG_FILES  := $(patsubst %.json,%.svg,$(JSON_FILES)) $(patsubst %.sim.v,%.bb.yosys.svg,$(VERILOG_FILES)) $(patsubst %.sim.v,%.flat.yosys.svg,$(VERILOG_FILES))
PNG_FILES  := $(patsubst %.svg,%.png,$(SVG_FILES))

# Basic black box version
%.bb.json: %.sim.v $(SIM_DEPS)
	echo $(SIM_TOP)
	$(YOSYS) -p "prep -top $(SIM_TOP); $(YOSYS_EXTRA); write_json $(TARGET)" $(PREREQ_FIRST)

%.aig.json: %.sim.v $(SIM_DEPS)
	$(YOSYS) -p "prep -top $(SIM_TOP) -flatten; aigmap; $(YOSYS_EXTRA); write_json $(TARGET)" $(PREREQ_FIRST)

%.flat.json: %.sim.v  $(SIM_DEPS)
	$(YOSYS) -p "prep -top $(SIM_TOP) -flatten; $(YOSYS_EXTRA); write_json $(TARGET)" $(PREREQ_FIRST)

.PRECIOUS: $(JSON_ENDINGS)

%.svg: %.json $(SIM_SVG_DEPS)
	$(NODE) $(NETLISTSVG)/bin/netlistsvg $(PREREQ_FIRST) -o $(TARGET) --skin $(SIM_NETLISTSVG_SKIN)

%.bb.yosys.svg: %.sim.v
	$(YOSYS) -p "prep -top $(SIM_TOP); $(YOSYS_EXTRA); cd $(SIM_TOP); show -format svg -prefix $(subst .svg,,$(TARGET))" $(PREREQ_FIRST)

%.flat.yosys.svg: %.sim.v
	$(YOSYS) -p "prep -top $(SIM_TOP) -flatten; $(YOSYS_EXTRA); show -format svg -prefix $(subst .svg,,$(TARGET))" $(PREREQ_FIRST)

.PRECIOUS: %.svg

%.png: %.svg
	$(INKSCAPE) --export-png $(TARGET) --export-dpi $(SIM_NETLISTSVG_DPI) $(PREREQ_FIRST)

.PRECIOUS: %.png

#%.yosys.ps: %.v
#	echo $(SIM_TOP)
#	$(YOSYS) -p "proc; hierarchy -top $(SIM_TOP) -purge_lib; show -format ps -prefix $(basename $(TARGET))" $(PREREQ_FIRST)

render: $(filter $(CURRENT_DIR)%,$(PNG_FILES))
	@true

view: render
	eog $(filter $(CURRENT_DIR)%,$(PNG_FILES))

sim-clean:
	@find $(CURRENT_DIR) -name '*.png'  -delete -print || true
	@find $(CURRENT_DIR) -name '*.svg'  -delete -print || true
	@find $(CURRENT_DIR) -name '*.json' -delete -print || true

clean: sim-clean
