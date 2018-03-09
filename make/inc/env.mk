ifeq (,$(INC_ENV_MK))
INC_ENV_MK := 1

ENV_DIR     := $(abspath $(TOP_DIR)/env)
CONDA_DIR   := $(ENV_DIR)/conda

CONDA_BIN   := $(CONDA_DIR)/bin/conda
CONDA_YOSYS := $(CONDA_DIR)/bin/yosys
CONDA_VPR   := $(CONDA_DIR)/bin/vpr
CONDA_MAKE  := $(CONDA_DIR)/bin/make
CONDA_XSLT  := $(CONDA_DIR)/bin/xsltproc
CONDA_PYTEST:= $(CONDA_DIR)/bin/pytest

# If the environment exists, put it into the path and use it.
ifneq (,$(wildcard $(abspath $(ENV_DIR))))
PATH   := $(CONDA_DIR)/bin:$(PATH)
YOSYS  ?= $(CONDA_YOSYS)
VPR    ?= $(CONDA_VPR)
XSLT   ?= $(CONDA_XSLT)
PYTEST ?= $(CONDA_PYTEST)
else
YOSYS  ?= yosys
VPR    ?= vpr
XSLT   ?= xsltproc
PYTEST ?= pytest-3
endif

# Tools in third_party
NETLISTSVG = $(TOP_DIR)/third_party/netlistsvg

# Tools not part of the environment yet.
NODE     ?= node
INKSCAPE ?= inkscape
NPM      ?= npm

endif
