XML_DEPS=../../../utils/xml_deps.sh

arch.deps.mk: arch.xml
	$(XML_DEPS) $@ $<

-include arch.deps.mk

merged.xml: arch.xml arch.deps.mk
	XMLLINT_INDENT=' ' xmllint --pretty 1 --xinclude --nsclean --format arch.xml |  \
		sed -e's/ *\(xml\|xmlns\):[^=]*="[^"]*" */ /g' \
	> merged.xml

.DEFAULT_GOAL := merged.xml
