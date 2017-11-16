
DEPS:
	grep 'xi:include' arch.xml | sed -e's/.*href="\([^"]*\)".*/\1/g' > DEPS

.PHONY: DEPS

merged.xml: arch.xml DEPS
	XMLLINT_INDENT=' ' xmllint --pretty 1 --xinclude --nsclean --format arch.xml |  \
		sed -e's/ *\(xml\|xmlns\):[^=]*="[^"]*" */ /g' \
	> merged.xml
