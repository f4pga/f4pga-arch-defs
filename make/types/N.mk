# common/make/N.mk - Create other files from templates based on replacing N
# with another value.
#
THIS_FILE := $(lastword $(MAKEFILE_LIST))
INC_FILE  := $(lastword $(filter-out $(THIS_FILE), $(MAKEFILE_LIST)))
INC_DIR   := $(realpath $(dir $(INC_FILE)))

$(INC_DIR)_N_VALUES       := $(NTEMPLATE_VALUES)
$(INC_DIR)_FILES_INPUT_N  := $(call find_files,$(INC_DIR)/ntemplate.*,$(FILES_POSSIBLE))

$($(INC_DIR)_FILES_OUTPUT_N): INC_DIR := $(INC_DIR)
$($(INC_DIR)_FILES_OUTPUT_N): $(THIS_FILE)

# $(1) == $(INPUT)
# $(2) == $(OUTPUT)
$(INC_DIR)_FILES_OUTPUT_N :=
define n_template =
$(2): $(1)
	@$(UTILS_DIR)/n.py $(1) $(2)

$(INC_DIR)_FILES_OUTPUT_N += $(2)
endef

$(foreach N,$($(INC_DIR)_N_VALUES), \
  $(foreach T,$($(INC_DIR)_FILES_INPUT_N), \
    $(eval $(call n_template,$T,$(dir $T)$(subst ntemplate.,,$(subst N,$N,$(notdir $T)))))))

FILES_INPUT_N  += $($(INC_DIR)_FILES_INPUT_N)
FILES_OUTPUT_N += $($(INC_DIR)_FILES_OUTPUT_N)

undefine NTEMPLATE_VALUES
