include ../make/inc/common.mk

# Need the environment for the Python code
include $(TOP_DIR)/make/inc/env.mk
include $(TOP_DIR)/make/env.mk

list: | $(PYTEST)
	$(PYTEST) --collect-only

tests: | $(PYTEST)
	$(PYTEST)

.PHONY: list

all:
	@true


.PHONY: all
