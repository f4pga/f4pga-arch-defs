SUBDIRS_ALL := $(sort $(dir $(foreach SUBDIR,$(wildcard *),$(wildcard $(SUBDIR)/Makefile))))
SUBDIRS_EXCLUDED := $(sort $(dir $(foreach PATTERN,$(SUBDIR_EXCLUDE),$(wildcard $(PATTERN)/Makefile))))
SUBDIRS := $(filter-out $(SUBDIRS_EXCLUDED),$(SUBDIRS_ALL))
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
