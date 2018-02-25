.SUFFIXES:

SELF_FILE := $(lastword $(MAKEFILE_LIST))
SELF_DIR := $(dir $(SELF_FILE))

# Regenerate files
GEN_MAKEFILES := $(filter-out Makefile.gen,$(wildcard Makefile.*))

LINE := echo "----------------------------------"

.Makefile.gen.d: Makefile.gen $(SELF_FILE)
	rm $@
	@for MFILE in $(GEN_MAKEFILES); do \
			echo "$@: .$$MFILE.d" >> $@; \
			echo "-include .$$MFILE.d" >> $@; \
			echo "" >> $@; \
		done
	touch $@

.Makefile.%.d: Makefile.%
	$(MAKE) -f $< $@

all: .Makefile.gen.d
	@true

clean:
	@for MFILE in $(GEN_MAKEFILES); do echo ""; echo "Cleaning for $$MFILE"; $(LINE); $(MAKE) -f $$MFILE clean ; $(LINE) ; done
	rm -f .Makefile.gen.d

.PHONY: all clean
.DEFAULT_GOAL := all
