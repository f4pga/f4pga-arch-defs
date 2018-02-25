# common/make/N.mk - Create other files from templates based on replacing N
# with another value.

ifeq (,$(NTEMPLATE_VALUES))
$(error "You have NTEMPLATES $(NTEMPLATES_INPUTS), you must provide $$NTEMPLATE_VALUES")
endif

NTEMPLATE_TOOL := $(realpath $(SELF_DIR)/../../utils/n.py)

$(call DEPMK,$(NTEMPLATE_PREFIX)s): | $(DEP_DIR)
	@echo "Generating deps for ntemplates into '$(TARGET)' using '$(SELF_FILE)'"
	@echo "" > $(TARGET)
	@for I in $(NTEMPLATES); do \
		for V in $(NTEMPLATE_VALUES); do \
			export O=$$(echo $$I | sed -e"s/N/$$V/g" -e's#$(NTEMPLATE_PREFIX)\.##'); \
			printf "$$O: $$I\n" 						>> $(TARGET); \
			printf "\t$(NTEMPLATE_TOOL) \$$(PREREQ_FIRST) \$$(TARGET)\n" 	>> $(TARGET); \
			printf "\n"		 					>> $(TARGET); \
			printf "NTEMPLATES_OUTPUTS += $$O\n"				>> $(TARGET); \
			printf "\n"		 					>> $(TARGET); \
		done; \
	done
	@echo "clean_ntemplates:" 							>> $(TARGET)
	@for I in $(NTEMPLATES); do \
		for V in $(NTEMPLATE_VALUES); do \
			export O=$$(echo $$I | sed -e"s/N/$$V/g" -e's#$(NTEMPLATE_PREFIX)\.##'); \
			printf "\trm -f $$O\n" 						>> $(TARGET); \
		done; \
	done
	@echo "" 									>> $(TARGET)
	@echo "clean: clean_ntemplates" 						>> $(TARGET)
	@echo "" 									>> $(TARGET)
	@echo "Created: $(TARGET)"

$(call DEPMK,$(NTEMPLATE_PREFIX)s): $(NTEMPLATES)
$(call DEPMK,$(NTEMPLATE_PREFIX)s): $(call ALL,$(INC_MAKEFILE))

all: $(NTEMPLATE_OUTPUTS)

include $(call DEPMK,$(NTEMPLATE_PREFIX)s)
