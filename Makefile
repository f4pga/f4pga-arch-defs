# Include files
include make/inc/common.mk
include make/inc/files.mk
# Generated files
include make/gen.mk
# Dependency generation
include make/deps.mk
# Conda environment
include make/env.mk
# Rules for converting XXX.sim.v files into images
include make/xml.mk
include make/third_party.mk
include make/sim.mk

print_vars:
	@$(foreach V,$(DEFINED_VARIABLES),$(info $V=$($V) ($(value $V))))

.PHONY: print_vars

# ------------------------------------------

all: | redir
	@true

.PHONY: all
.DEFAULT_GOAL := all

test:
	$(call heading,Running Python utils tests)
	@$(MAKE) -C utils all $(result)

#$(call heading,Running Verilog to Routing tests)
#@$(MAKE) -C tests all $(result)

.PHONY: test

clean:
	@true

dist-clean:
	@true

.PHONY: clean dist-clean
