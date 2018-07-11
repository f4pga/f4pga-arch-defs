SUBDIRS := $(sort $(dir $(foreach SUBDIR,$(wildcard *),$(wildcard $(SUBDIR)/Makefile))))
$(info SUBDIRS = $(SUBDIRS))

$(SUBDIRS):
	cd $@; $(MAKE) $(MAKECMDGOALS)

.PHONY: $(SUBDIRS)

##########################################################################

%: $(SUBDIRS)
	@true

check-all: check $(SUBDIRS)
	@true

clean-all: clean $(SUBDIRS)
	@true

.PHONY: check check-all clean clean-all
