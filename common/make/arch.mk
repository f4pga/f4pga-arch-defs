
SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

XML_DEPS = $(shell realpath $(SELF_DIR)/../../utils/xml_deps.py)

arch.deps.mk: arch.xml $(XML_DEPS) $(SELF_DIR)/arch.mk
	$(XML_DEPS) $@ $<

-include arch.deps.mk

merged.xml: arch.xml arch.deps.mk $(SELF_DIR)/arch.mk
	@rm -f $@
	@echo '<?xml version="1.0"?>' > $@
	@echo '<!-- Generated from arch.xml - **DO NOT EDIT** -->' >> $@
	xmllint --xinclude --nsclean --noblanks --format arch.xml \
	| sed -e's/\s*\(xml\|xmlns\):[^=]*="[^"]*"\s*/ /g' -e's/\s\+/ /g' -e's/\s"/"/g' \
	| XMLLINT_INDENT=' ' xmllint --pretty 1 - \
	| tail -n+2 >> $@
	@chmod u-w $@ # Make read only to prevent editing.

clean:
	rm -f arch.deps.mk merged.xml

.DEFAULT_GOAL := merged.xml
