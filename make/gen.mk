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
	@rm -f $(call find_generated_files,$(CURRENT_DIR)*)

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

.git/info/exclude.redir: $(TOP_DIR)/make/gen.mk | redir
	$(file >$(TARGET),$(call gitexclude_comment,Makefile redirect))
	@for DIR in $$($(UTILS_DIR)/listdirs.py); do \
	  if [ $$(python -c"import os.path; print(os.path.realpath('$$DIR/Makefile'))") = $(abspath $(TOP_DIR)/make/redir.mk) ]; then \
	    export NEW_MAKEFILE=$$(echo $$DIR/Makefile | sed -e's@^$(TOP_DIR)/@@'); \
	    echo  "$$NEW_MAKEFILE" >> $(TARGET); \
	  fi; \
	done

.git/info/exclude.base:
	@touch $(TARGET)

.git/info/exclude.gen: $(TOP_DIR)/make/gen.mk
	$(file >$(TARGET),$(call gitexclude_comment,Generated))
	$(foreach O,$(call find_generated_files,*),$(file >>$(TARGET),$(subst $(abspath $(PWD))/,,$O)))

.git/info/exclude: .git/info/exclude.base .git/info/exclude.gen .git/info/exclude.redir
	@cat $(PREREQ_ALL) > $(TARGET)

gitexclude-clean:
	@rm -vf .git/info/exclude .git/info/exclude.gen .git/info/exclude.redir

.PHONY: .git/info/exclude.gen

ifeq (,$(CURRENT_DIR))
all: .git/info/exclude
clean: gitexclude-clean
endif
