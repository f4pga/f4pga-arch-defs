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

ifeq (1,$(V))

define quiet_cmd
$(1)
endef

else

define quiet_cmd
@export T=$$(tempfile); \
$(1) > $$T 2>&1; R=$$?; \
if [ $$R == 0 ]; then \
  echo -e "$(2)"; \
else \
  echo '$(1)'; \
  echo -e "-- $(RED)Failed!$(NC)"; \
  cat $$T; \
  echo -e "-- $(RED)Failed!$(NC)"; \
  exit $$R ; \
fi; rm $$T

endef

endif

GENERATED_FROM = Generated $(GREEN)$(subst $(PWD)/,,$(TARGET))$(NC)from $(YELLOW)$(notdir $(PREREQ_FIRST))$(NC)

# Basic black box version
%.bb.json: %.sim.v $(SIM_DEPS)
	$(call quiet_cmd,$(YOSYS) -p "prep -top $(SIM_TOP); $(YOSYS_EXTRA); write_json $(TARGET)" $(PREREQ_FIRST),$(GENERATED_FROM))

%.aig.json: %.sim.v $(SIM_DEPS)
	$(call quiet_cmd,$(YOSYS) -p "prep -top $(SIM_TOP) -flatten; aigmap; $(YOSYS_EXTRA); write_json $(TARGET)" $(PREREQ_FIRST),$(GENERATED_FROM))

%.flat.json: %.sim.v  $(SIM_DEPS)
	$(call quiet_cmd,$(YOSYS) -p "prep -top $(SIM_TOP) -flatten; $(YOSYS_EXTRA); write_json $(TARGET)" $(PREREQ_FIRST),$(GENERATED_FROM))

.PRECIOUS: $(JSON_ENDINGS)

%.svg: %.json $(SIM_SVG_DEPS)
	$(call quiet_cmd,$(NODE) $(NETLISTSVG)/bin/netlistsvg $(PREREQ_FIRST) -o $(TARGET) --skin $(SIM_NETLISTSVG_SKIN),$(GENERATED_FROM))

%.bb.yosys.svg: %.sim.v
	$(call quiet_cmd,$(YOSYS) -p "prep -top $(SIM_TOP); $(YOSYS_EXTRA); cd $(SIM_TOP); show -format svg -prefix $(subst .svg,,$(TARGET))" $(PREREQ_FIRST),$(GENERATED_FROM))

%.flat.yosys.svg: %.sim.v
	$(call quiet_cmd,$(YOSYS) -p "prep -top $(SIM_TOP) -flatten; $(YOSYS_EXTRA); show -format svg -prefix $(subst .svg,,$(TARGET))" $(PREREQ_FIRST),$(GENERATED_FROM))

.PRECIOUS: %.svg

%.png: %.svg
	$(call quiet_cmd,$(INKSCAPE) --export-png $(TARGET) --export-dpi $(SIM_NETLISTSVG_DPI) $(PREREQ_FIRST),$(GENERATED_FROM))

.PRECIOUS: %.png

#%.yosys.ps: %.v
#	echo $(SIM_TOP)
#	$(YOSYS) -p "proc; hierarchy -top $(SIM_TOP) -purge_lib; show -format ps -prefix $(basename $(TARGET))" $(PREREQ_FIRST)

define render_and_view_cmds

render$(1): $$(filter $$(CURRENT_DIR)%,$$(filter %$(1).png,$$(PNG_FILES)))
	$$(call heading,Rendered $(1).png output from XXX.sim.v files)
	@echo "$$(PREREQ_ALL)" | sed -e's/ /\n/g' -e's@$$(PWD)/@@g'

view$(1): render$(1)
	@eog $$(filter $$(CURRENT_DIR)%,$$(filter %$(1).png,$$(PNG_FILES)))

endef

$(eval $(call render_and_view_cmds,,))
$(foreach X,.bb .aig .flat .bb.yosys .flat.yosys,$(eval $(call render_and_view_cmds,$(X))))


render-clean:
	@find $(CURRENT_DIR) -name '*.png'  -delete -print || true
	@find $(CURRENT_DIR) -name '*.svg'  -delete -print || true
	@find $(CURRENT_DIR) -name '*.json' -delete -print || true
	@find $(CURRENT_DIR) -name '*.dot' -delete -print || true

# Add to the global targets
all: render
clean: render-clean
