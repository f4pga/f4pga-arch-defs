include make/inc/common.mk
include make/inc/env.mk

# Install netlistsvg in third_party
NETLISTSVG_BIN  := $(NETLISTSVG)/bin/netlistsvg.js
NETLISTSVG_LOCK := $(NETLISTSVG)/package-lock.json
NETLISTSVG_SKIN ?= $(NETLISTSVG)/lib/default.svg

$(NETLISTSVG_SKIN): $(NETLISTSVG_STAMP)
	@true

$(NETLISTSVG)/package.json $(NETLISTSVG)/.git: $(TOP_DIR)/.gitmodules
	git submodule update --init $(NETLISTSVG)

$(NETLISTSVG_LOCK): $(NPM) $(NETLISTSVG)/package.json
	cd $(NETLISTSVG) && $(NPM) install
