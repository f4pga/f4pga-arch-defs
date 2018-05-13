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

all: | redir .git/info/exclude
	@true

.PHONY: all
.DEFAULT_GOAL := all

simtest: | $(CONDA_COCOTB)
	$(call heading,Running simulation tests)
	@for ii in `find . -type d -name simtest -a ! -wholename "./.deps/*"`; do echo $$ii; $(MAKE) -C $$ii TOP_DIR=$(TOP_DIR) > /dev/null; [ `grep -c failure $$ii/results.xml` == 0 ]; done

.PHONY: simtest

test: simtest
	$(call heading,Running Python utils tests)
	@$(MAKE) -C utils tests $(result)

	$(call heading,$(PURPLE)Aritx 7:$(NC)Running Verilog to Routing tests)
	@$(MAKE) ARCH=artix7 -C tests $(result)

	$(call heading,$(PURPLE)iCE40:$(NC)Running Verilog to Routing tests)
	@$(MAKE) ARCH=ice40 -C tests $(result)

	$(call heading,$(PURPLE)Test Arch:$(NC)Running Verilog to Routing tests)
	@$(MAKE) ARCH=testarch -C tests $(result)

.PHONY: test

format:
	find . -name \*.py -and -not -path './third_party/*' -and -not -path './env/*' -and -not -path './.git/*' -exec yapf -p -i {} \;

.PHONY: format

clean:
	@true

dist-clean: clean
	@true

.PHONY: clean dist-clean
