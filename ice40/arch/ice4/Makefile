
DEPS:
	grep 'xi:include' arch.xml | sed -e's/.*href="\([^"]*\)".*/\1/g' > DEPS

.PHONY: DEPS

merged.xml: arch.xml DEPS
	xmllint --pretty 1 -xinclude arch.xml > merged.xml
