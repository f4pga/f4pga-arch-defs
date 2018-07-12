%.sort.xml: %.xml
	xsltproc ../../../../common/xml/xmlsort.xsl $< > $@

model.xml: $(NAME).sim.v
	V=1 ../../../vlog/vlog_to_model.py $< --top $(NAME)

clean:
	rm -f *.sort.xml
	rm -f model.xml

all:
	make clean
	make $(NAME).model.sort.xml
	make model.sort.xml
	diff -u $(NAME).model.sort.xml model.sort.xml

.PHONY: all
