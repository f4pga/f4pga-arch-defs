ifeq (,$(INC_ENV_MK))
INC_ENV_MK := 1

ENV_DIR     := $(abspath $(TOP_DIR)/env)
CONDA_DIR   := $(ENV_DIR)/conda

CONDA_BIN      := $(CONDA_DIR)/bin/conda
CONDA_YOSYS    := $(CONDA_DIR)/bin/yosys
CONDA_VPR      := $(CONDA_DIR)/bin/vpr
CONDA_MAKE     := $(CONDA_DIR)/bin/make
CONDA_XSLT     := $(CONDA_DIR)/bin/xsltproc
CONDA_PYTEST   := $(CONDA_DIR)/bin/pytest
CONDA_YAPF     := $(CONDA_DIR)/bin/yapf
CONDA_NODE     := $(CONDA_DIR)/bin/node
CONDA_NPM      := $(CONDA_DIR)/bin/npm
CONDA_IVERILOG := $(CONDA_DIR)/bin/iverilog
CONDA_PYTHON3  := $(CONDA_DIR)/bin/python3
CONDA_PIP      := $(CONDA_DIR)/bin/pip

# If the environment exists, put it into the path and use it.
ifneq (,$(wildcard $(abspath $(ENV_DIR))))
PATH      := $(CONDA_DIR)/bin:$(PATH)
YOSYS     ?= $(CONDA_YOSYS)
VPR       ?= $(CONDA_VPR)
XSLT      ?= $(CONDA_XSLT)
PYTEST    ?= $(CONDA_PYTEST)
YAPF      ?= $(CONDA_YAPF)
NODE      ?= $(CONDA_NODE)
NPM       ?= $(CONDA_NPM)
IVERILOG  ?= $(CONDA_IVERILOG)
PYTHON    ?= $(CONDA_PYTHON3)
else
YOSYS     ?= yosys
VPR       ?= vpr
XSLT      ?= xsltproc
PYTEST    ?= pytest-3
YAPF      ?= yapf
NODE      ?= node
NPM       ?= npm
IVERILOG  ?= iverilog
PYTHON    ?= python3
endif

# Tools in third_party
NETLISTSVG = $(TOP_DIR)/third_party/netlistsvg

# Tools not part of the environment yet.
INKSCAPE ?= inkscape

# TODO: Should this live somewhere else
TOPLEVEL_LANG ?= verilog
COCOTB ?= $(shell $(PYTHON) -c "import site; print(site.getsitepackages()[0])")
ICARUS_BIN_DIR ?= $(dir $(shell which $(IVERILOG)))

endif
