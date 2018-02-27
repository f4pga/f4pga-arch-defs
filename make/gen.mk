include $(COMMON_MK_DIR)/files.mk
include $(COMMON_MK_DIR)/func.mk

# Generate other files

# Run Muxgen first
# ------------------
MAKEFILES_MUX := $(call find_files,*/Makefile.mux)
FILES_OUTPUT_MUX :=
$(call include_types,$(MAKEFILES_MUX),mux)
FILES_GENERATED += $(sort $(FILES_OUTPUT_MUX))

# Common dependencies for all muxgen targets
MUX_GEN_CMD := $(realpath $(UTILS_DIR)/mux_gen.py)
MUX_GEN_LIB := $(realpath $(UTILS_DIR)/utils/lib)
MUX_GEN_FILES := $(wildcard $(MUX_GEN_LIB)/*.py)
$(FILES_OUTPUT_MUX): $(MUX_GEN_FILES)
$(FILES_OUTPUT_MUX): Makefile

# Then ntemplates
# ------------------
MAKEFILES_N := $(call find_files,*/Makefile.N)
FILES_INPUT_N :=
FILES_OUTPUT_N :=
$(call include_types,$(MAKEFILES_N),N)
FILES_TEMPLATES += $(sort $(FILES_INPUT_N))
FILES_GENERATED += $(sort $(FILES_OUTPUT_N))
