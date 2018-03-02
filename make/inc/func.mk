ifeq (,$(INC_FUNC_MK))
INC_FUNC_MK := 1

# Lowercase a string
lc = $(shell echo "$1" | tr A-Z a-z)

# -------------------------------
#  Functions for getting variables
# -------------------------------

DEFINED_VARIABLES = $(foreach V,$(sort $(.VARIABLES)), \
	   $(if $(filter-out environment% default automatic undefined, \
	   $(origin $V)),$V))

define _undefine_me
undefine $(1)
endef

# -------------------------------
# $(call include_types,file1 file2,mux)
# -------------------------------

define _include_type

INC_TYPE := $(1)
INC_FILE := $(2)
INC_DIR  := $$(realpath $$(dir $(2)))

# Save a list of variables so we can remove any that were created.
BEFORE_VARIABLES := $$(DEFINED_VARIABLES)

-include $$(INC_FILE)
include $(TOP_DIR)/make/types/$$(INC_TYPE).mk

# Work out if any new variables were created
AFTER_VARIABLES := $$(DEFINED_VARIABLES)
NEW_VARIABLES := $$(filter-out %_VARIABLES,$$(filter-out $$(BEFORE_VARIABLES),$$(AFTER_VARIABLES)))
NEW_GLOBALS := $$(filter-out $(INC_DIR)/%,$$(NEW_VARIABLES))

# Undefine them
$$(foreach V,$$(NEW_GLOBALS),$$(eval $$(call _undefine_me,$$(V))))

undefine INC_FILE
undefine INC_DIR
undefine INC_TYPE

endef

include_types = $(foreach FILE,$(1),$(eval $(call _include_type,$(2),$(FILE))))

# -------------------------------
# $(call include_types,file1 file2,mux)
# -------------------------------

define _include_type_all

INC_ALL_TYPE := $(1)

MAKEFILES_INC := $$(call find_files,*/Makefile.$$(INC_ALL_TYPE))
ifeq (0,$$(words $$(MAKEFILES_INC)))
$$(error No configs found for $$(INC_ALL_TYPE))
endif

OUTPUTS   :=
TEMPLATES :=
$$(call include_types,$$(MAKEFILES_INC),$(1))

TEMPLATES := $$(sort $$(abspath $$(TEMPLATES)))
OUTPUTS   := $$(sort $$(abspath $$(OUTPUTS)))

ifeq (1,$(V))
$$(info $$(INC_ALL_TYPE) TEMPLATES: $$(TEMPLATES))
$$(info $$(INC_ALL_TYPE)   OUTPUTS: $$(OUTPUTS))
endif

ifeq (0,$$(words $$(OUTPUTS)))
$$(error No outputs generated for $$(INC_ALL_TYPE))
endif


FILES_TEMPLATES := $$(sort $$(abspath $$(FILES_TEMPLATES) $$(TEMPLATES)))
FILES_GENERATED := $$(sort $$(abspath $$(FILES_GENERATED) $$(OUTPUTS)))

undefine TEMPLATES
undefine OUTPUTS

undefine MAKEFILES_INC
undefine INC_ALL_TYPE

endef

include_type_all = $(eval $(call _include_type_all,$(1)))

# -------------------------------
endif
