SUBDIRS := $(sort $(dir $(foreach SUBDIR,$(wildcard *),$(wildcard $(SUBDIR)/Makefile))))
$(info SUBDIRS = $(SUBDIRS))

$(SUBDIRS):
	cd $@; $(MAKE) $(MAKECMDGOALS)

.PHONY: $(SUBDIRS)

##########################################################################

check-all: check $(SUBDIRS)
	@true

clean-all: clean $(SUBDIRS)
	@true

.PHONY: check check-all clean clean-all
