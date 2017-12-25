# Regenerate files
MAKEFILES := $(shell ls Makefile.* | grep -v .gen)

LINE := echo "----------------------------------"

.gen.stamp:
	@for MAKE in $(MAKEFILES); do echo ""; echo "Regenerating for $$MAKE"; $(LINE); make -f $$MAKE ; $(LINE) ; done
	touch .gen.stamp

all: .gen.stamp
	@true

clean:
	@for MAKE in $(MAKEFILES); do echo ""; echo "Cleaning for $$MAKE"; $(LINE); make -f $$MAKE clean ; $(LINE) ; done
	rm -f .gen.stamp

.PHONY: all clean .gen.stamp
.DEFAULT_GOAL := all
