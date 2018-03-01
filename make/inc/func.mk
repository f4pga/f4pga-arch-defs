ifeq (,$(INC_FUNC_MK))
INC_FUNC_MK := 1

# Makefile functions
# -------------------------------

# Allow people to depend on either;
#  * depend_on_only - Only the file directly.
#  * depend_on_deps - On the dependencies of a file.
#  * depend_on_all  - On both the file directly and it's dependencies.
DEPEXT=.d
depend_on_only  = $(1)
depend_on_deps  = $(subst ./,,$(dir $(1)))$(notdir $(1))$(DEPEXT)
depend_on_all   = $(call depend_on_only,$(1)) $(call depend_on_deps,$(1))

# Add a dependency from X onto Y
define _add_dependency

ONTO := $(1)
FROM := $(2)

$$(call depend_on_deps,$$(ONTO)): $$(call depend_on_all,$$(FROM))

undefine FROM
undefine ONTO

endef

# $(call add_dependency,filex,included_file1 included_file2)
# Creates the following dependency chain,
# a.d: b b.d
add_dependency = $(foreach DEP,$(2),$(eval $(call _add_dependency,$(1),$(DEP))))

# -------------------------------

define _include_type

INC_TYPE := $(1)
INC_FILE := $(2)
INC_DIR  := $$(realpath $$(dir $(2)))

include $$(INC_FILE)
include $(TOP_DIR)/make/types/$$(INC_TYPE).mk

undefine INC_FILE
undefine INC_DIR
undefine INC_TYPE

endef

# $(call include_types,file1 file2,mux)
include_types = $(foreach FILE,$(1),$(eval $(call _include_type,$(2),$(FILE))))

define _include_type_all

INC_ALL_TYPE := $(1)

MAKEFILES_INC := $$(call find_files,*/Makefile.$$(INC_ALL_TYPE))

OUTPUTS :=
TEMPLATES :=
$$(call include_types,$$(MAKEFILES_INC),$(1))

TEMPLATES := $$(sort $$(abspath $$(TEMPLATES)))
OUTPUTS   := $$(sort $$(abspath $$(OUTPUTS)))

ifeq (1,$(V))
$$(info $$(INC_ALL_TYPE) TEMPLATES: $$(TEMPLATES))
$$(info $$(INC_ALL_TYPE)   OUTPUTS: $$(OUTPUTS))
endif

FILES_TEMPLATES := $$(sort $$(abspath $$(FILES_TEMPLATES) $$(TEMPLATES)))
FILES_OUTPUTS   := $$(sort $$(abspath $$(FILES_OUTPUTS) $$(OUTPUTS)))

undefine TEMPLATES
undefine OUTPUTS

undefine MAKEFILES_INC
undefine INC_ALL_TYPE

endef

# $(call include_types,file1 file2,mux)
include_type_all = $(eval $(call _include_type_all,$(1)))

# -------------------------------

# Lowercase a string
lc = $(shell echo "$1" | tr A-Z a-z)

endif
