include $(COMMON_MK_DIR)/files.mk
include $(COMMON_MK_DIR)/func.mk

# Generate files
$(call include_type_all,mux) 	# Run Muxgen first
$(call include_type_all,N)	# Then ntemplates
$(call include_type_all,v2x)	# Then Verilog -> XML

# Artix-7 specific
$(call include_type_all,xray)
$(call include_type_all,dummy)

# Generate a .gitignore
define gitignore_comment

# Generated files
#-------------------------------
.gitignore
.gitignore.gen
endef

.gitignore.gen:
	$(file >$(TARGET),$(gitignore_comment))
	$(foreach O,$(call find_generated_files,*),$(file >>$(TARGET),$(subst $(abspath $(PWD))/,,$O)))

.gitignore: .gitignore.base .gitignore.gen
	@cat $(PREREQ_ALL) > $(TARGET)

.PHONY: .gitignore.gen
