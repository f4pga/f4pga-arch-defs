include make/inc/files.mk
include make/inc/func.mk

# Generate files
$(call include_type_all,mux) 	# Run Muxgen first
$(call include_type_all,N)	# Then ntemplates
$(call include_type_all,v2x)	# Then Verilog -> XML

# Artix-7 specific
$(call include_type_all,xray)
$(call include_type_all,dummy)

gen-clean:
	@rm -f $(call find_generated_files,$(FILTER_BELOW))

clean: gen-clean

redir:
	@for DIR in $$($(UTILS_DIR)/listdirs.py); do \
	  if [ ! -e $$DIR/Makefile ]; then \
	    ln -sf $(abspath $(TOP_DIR)/make/redir.mk) $$DIR/Makefile; \
	    export NEW_MAKEFILE=$$(echo $$DIR/Makefile | sed -e's@^$(TOP_DIR)/@@'); \
	    echo "Creating redirect makefile '$$NEW_MAKEFILE'"; \
	  fi; \
	done

# Generate a .git/info/exclude
define gitexclude_comment

# $(1) files
#-------------------------------
endef

REDIR_EXCLUDE:=$(TOP_DIR)/.git/info/exclude.redir.mk

$(REDIR_EXCLUDE): $(TOP_DIR)/make/gen.mk | redir
	@echo  "REDIR_MAKEFILES=\\" > $(TARGET)
	@for DIR in $$($(UTILS_DIR)/listdirs.py); do \
	  if [ $$(python -c"import os.path; print(os.path.realpath('$$DIR/Makefile'))") = $(abspath $(TOP_DIR)/make/redir.mk) ]; then \
	    export NEW_MAKEFILE=$$(echo $$DIR/Makefile | sed -e's@^$(TOP_DIR)/@@'); \
	    echo  "  $$NEW_MAKEFILE \\" >> $(TARGET); \
	  fi; \
	done
	@echo  "" >> $(TARGET)
	@echo  '$$(call add_generated_files,$$(REDIR_MAKEFILES))' >> $(TARGET)

-include $(REDIR_EXCLUDE)

.git/info/exclude.base:
	@touch $(TARGET)

.git/info/exclude.gen: $(TOP_DIR)/make/gen.mk
	$(file >$(TARGET),$(call gitexclude_comment,Generated))
	$(foreach O,$(call find_generated_files,*),$(file >>$(TARGET),$(subst $(abspath $(PWD))/,,$O)))

.git/info/exclude: .git/info/exclude.base .git/info/exclude.gen | $(REDIR_EXCLUDE)
	@cat $(PREREQ_ALL) > $(TARGET)

gitexclude-clean:
	@rm -vf .git/info/exclude .git/info/exclude.gen $(REDIR_EXCLUDE)

.PHONY: .git/info/exclude.gen

ifeq (,$(CURRENT_DIR))
all: .git/info/exclude
clean: gitexclude-clean
endif
