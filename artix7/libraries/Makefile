


PDF := ug953-vivado-7series-libraries.pdf
URL := "https://xilinx.com/support/documentation/sw_manuals/xilinx2017_3/$(PDF)"

$(PDF):
	wget $(URL)

%.txt: %.pdf
	pdftotext -layout $< $@

cells_xtra.v: process.py $(PDF)
	python process.py $(PDF)
