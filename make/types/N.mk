# common/make/N.mk - Create other files from templates based on replacing N
# with another value.
$(INC_DIR)_N_VALUES       := $(NTEMPLATE_VALUES)
ifeq (,$(NTEMPLATE_VALUES))
$(error $(INC_DIR)/Makefile.N: Unable to find NTEMPLATE_VALUES setting!)
endif

$(INC_DIR)_FILES_INPUT_N  := $(call find_files,$(INC_DIR)/ntemplate.*)

ifeq (,$($(INC_DIR)_FILES_INPUT_N))
$(error $(INC_DIR)/Makefile.N: Unable to find any inputs!)
endif

$($(INC_DIR)_FILES_OUTPUT_N): INC_DIR := $(INC_DIR)
$($(INC_DIR)_FILES_OUTPUT_N): $(THIS_FILE)

# $(1) == $(INPUT)
# $(2) == $(OUTPUT)
$(INC_DIR)_FILES_OUTPUT_N :=
define n_template =
$(3): $(2)
	$$(call quiet_cmd,$(UTILS_DIR)/n.py $(1) $(2) $(3),$$(GENERATED_FROM))

$(INC_DIR)_FILES_OUTPUT_N += $(3)
endef

$(foreach N,$($(INC_DIR)_N_VALUES), \
  $(foreach T,$($(INC_DIR)_FILES_INPUT_N), \
    $(eval $(call n_template,$N,$T,$(dir $T)$(subst ntemplate.,,$(subst N,$N,$(notdir $T)))))))

TEMPLATES += $($(INC_DIR)_FILES_INPUT_N)
OUTPUTS   += $($(INC_DIR)_FILES_OUTPUT_N)
