include $(COMMON_MK_DIR)/files.mk
include $(COMMON_MK_DIR)/func.mk

# Generate files
$(call include_type_all,mux) 	# Run Muxgen first
$(call include_type_all,N)	# Then ntemplates
$(call include_type_all,v2x)	# Then Verilog -> XML

# Artix-7 specific
$(call include_type_all,xray)
$(call include_type_all,dummy)

redir:
	@rm -f .gitignore.redir
	@for DIR in $$($(UTILS_DIR)/listdirs.py); do \
	  if [ ! -e $$DIR/Makefile ]; then \
	    ln -sf $(abspath $(TOP_DIR)/make/redir.mk) $$DIR/Makefile; \
	  fi; \
	  if [ $$(python -c"import os.path; print(os.path.realpath('$$DIR/Makefile'))") = $(abspath $(TOP_DIR)/make/redir.mk) ]; then \
	    export NEW_MAKEFILE=$$(echo $$DIR/Makefile | sed -e's@^$(TOP_DIR)/@@'); \
	    echo "Redirect makefile '$$NEW_MAKEFILE'"; \
	    echo  "$$NEW_MAKEFILE" >> .gitignore.redir; \
	  fi; \
	done
	@$(MAKE) .gitignore

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

.gitignore: .gitignore.base .gitignore.gen .gitignore.redir
	@cat $(PREREQ_ALL) > $(TARGET)

gitignore-clean:
	@rm -vf .gitignore .gitignore.gen

.PHONY: .gitignore.gen

ifeq (,$(CURRENT_DIR))
all: .gitignore
clean: gitignore-clean
endif
