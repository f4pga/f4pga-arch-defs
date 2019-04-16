#	xsltproc --xinclude ../../../../common/xml/xmlsort.xsl $< > $@.tmp
#	xmllint --c14n $@.tmp > $@
%.sort.xml: %.xml
	xsltproc --xinclude ../../../../common/xml/xmlsort.xsl $< > $@

model.xml: $(NAME).sim.v
	V=1 ../../../vlog/vlog_to_model.py $< --top $(NAME)

pb_type.xml: $(NAME).sim.v
	V=1 ../../../vlog/vlog_to_pbtype.py $< --top $(NAME)

clean:
	rm -f *.sort.xml
	rm -f model.xml
	rm -f pb_type.xml

check-model:
	make $(NAME).model.sort.xml
	make model.sort.xml
	diff -u $(NAME).model.sort.xml model.sort.xml

check-pb_type:
	make $(NAME).pb_type.sort.xml
	make pb_type.sort.xml
	diff -u $(NAME).pb_type.sort.xml pb_type.sort.xml

all:
	make clean
	make check-model
	make check-pb_type

.PHONY: all
