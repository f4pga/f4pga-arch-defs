ifeq ($(PRJXRAY_PART),)
$(error "Please set PRJXRAY_PART")
endif
ifeq ($(PRJXRAY_CLB),)
$(error "Please set PRJXRAY_CLB")
endif

PRJXRAY_LCLB := $(shell echo $(PRJXRAY_CLB) | tr A-Z a-z)

PRJXRAY_INFO = $(TOP_DIR)/third_party/prjxray-db/Info.md
PRJXRAY_DB = $(TOP_DIR)/third_party/prjxray-db/$(PRJXRAY_PART)/
CLB_IMPORT = $(TOP_DIR)/artix7/utils/prjxray-clb-import.py

$(PRJXRAY_LCLB).pb_type.xml $(PRJXRAY_LCLB).model.xml: $(CLB_IMPORT) $(PRJXRAY_INFO) $(PRJXRAY_DB)/*$(PRJXRAY_LCLB)*.db
	$(CLB_IMPORT) --part $(PRJXRAY_PART) --tile $(PRJXRAY_CLB) --output-pb-type $(PRJXRAY_LCLB).pb_type.xml --output-model $(PRJXRAY_LCLB).model.xml

CLB_OUTPUTS := $(PRJXRAY_LCLB).pb_type.xml $(PRJXRAY_LCLB).model.xml

clean_clb:
	rm $(CLB_OUTPUTS)

clean: clean_clb
