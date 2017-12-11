
XML_DEPS=../utils/xml_deps.sh

arch.deps.mk: arch.xml
	$(XML_DEPS) $@ $<

-include arch.deps.mk

merged.xml: arch.xml arch.deps.mk
	@rm -f $@
	@echo '<?xml version="1.0"?>' > $@
	@echo '<!-- Generated from arch.xml - **DO NOT EDIT** -->' >> $@
	XMLLINT_INDENT=' ' xmllint --pretty 1 --xinclude --nsclean --format arch.xml |  \
		sed -e's/ *\(xml\|xmlns\):[^=]*="[^"]*" */ /g' \
	| tail -n+2 >> $@
	@chmod u-w $@ # Make read only to prevent editing.

.DEFAULT_GOAL := merged.xml
