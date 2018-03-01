PRJXRAY_VALID := 0

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
$(error "$(INC_FILE): Unknown PRJXRAY config")
endif
