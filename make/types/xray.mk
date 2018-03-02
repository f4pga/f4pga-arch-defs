PRJXRAY_VALID := 0

ifneq (1,$(words $(PRJXRAY_INT) $(PRJXRAY_CLB)))
$(error $(INC_DIR): Both PRJXRAY_INT '$(PRJXRAY_INT)' and PRJXRAY_CLB '$(PRJXRAY_CLB)' defined!)
endif

# INT tiles import
ifneq (,$(PRJXRAY_INT))
PRJXRAY_VALID := 1
include $(TOP_DIR)/artix7/make/prjxray-int.mk
endif

# CLB tiles import
ifneq (,$(PRJXRAY_CLB))
PRJXRAY_VALID := 1
include $(TOP_DIR)/artix7/make/prjxray-clb.mk
endif

ifneq (1,$(PRJXRAY_VALID))
$(error $(INC_FILE)/Makefile.xray: Unknown PRJXRAY config)
endif
