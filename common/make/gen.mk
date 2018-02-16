.SUFFIXES:

# Regenerate files
GEN_MAKEFILES := $(shell ls Makefile.* | grep -v .gen)

LINE := echo "----------------------------------"

.gen.stamp:
	@for MAKE in $(GEN_MAKEFILES); do echo ""; echo "Regenerating for $$MAKE"; $(LINE); $(MAKE) -f $$MAKE  ; $(LINE) ; done
	touch .gen.stamp

all: .gen.stamp
	@true

clean:
	@for MAKE in $(GEN_MAKEFILES); do echo ""; echo "Cleaning for $$MAKE"; $(LINE); $(MAKE) -f $$MAKE clean ; $(LINE) ; done
	rm -f .gen.stamp

.PHONY: all clean .gen.stamp
.DEFAULT_GOAL := all
