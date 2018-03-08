include make/inc/common.mk
include make/inc/env.mk

# Install netlistsvg in third_party
NETLISTSVG_STAMP := $(TOP_DIR)/third_party/.netlistsvg.stamp
NETLISTSVG_SKIN ?= $(NETLISTSVG)/lib/default.svg

$(NETLISTSVG_SKIN): $(NETLISTSVG_STAMP)
	@true

$(NETLISTSVG)/.git:
	git submodule update --init $(NETLISTSVG)

$(NETLISTSVG_STAMP): $(NETLISTSVG)/.git
	cd $(NETLISTSVG) && $(NPM) install
	touch $(NETLISTSVG_STAMP)
