# Lattice iCEstick
# http://www.latticesemi.com/icestick
# ---------------------------------------------
ifeq ($(BOARD),icestick)
DEVICE=hx1k
PACKAGE=tq144
PROG_TOOL=$(ICEPROG_TOOL)
endif

# Lattice iCEblink40-LP1K Evaluation Kit
# **HX** version is different!
# ---------------------------------------------
ifeq ($(BOARD),iceblink40-lp1k)
DEVICE=lp1k
PACKAGE=qn84

ifeq ($(PROG_TOOL),)
PROG_TOOL ?= $(CONDA_DIR)/bin/iCEburn
PROG_CMD ?= $(PROG_TOOL) -ew

$(PROG_TOOL):
	pip install -e git+https://github.com/davidcarne/iceBurn.git#egg=iceBurn

endif
endif

# iCE40-HX8K Breakout Board Evaluation Kit
# iCE40-HX8K-CT256
# ---------------------------------------------
ifeq ($(BOARD),hx8k-b-evn)
DEVICE=hx8k
PACKAGE=ct256
PROG_TOOL ?= $(ICEPROG_TOOL)
PROG_CMD ?= $(PROG_TOOL) -S
endif

# TinyFPGA B2
# iCE40-LP8K-CM81
# ---------------------------------------------
ifeq ($(BOARD),tinyfpga-b2)
DEVICE=lp8k
PACKAGE=cm81

ifeq ($(PROG_TOOL),)
PROG_TOOL=$(CONDA_DIR)/bin/tinyfpgab
PROG_CMD ?= $(PROG_TOOL) --program

$(PROG_TOOL):
	$(CONDA_PIP) install tinyfpgab

endif
endif

# TinyFPGA BX
# iCE40-LP8K-CM81
# ---------------------------------------------
ifeq ($(BOARD),tinyfpga-bx)
DEVICE=lp8k
PACKAGE=cm81

ifeq ($(PROG_TOOL),)
PROG_TOOL=$(CONDA_DIR)/bin/tinyprog
PROG_CMD ?= $(PROG_TOOL) -p

$(PROG_TOOL):
	$(CONDA_PIP) install tinyprog

endif
endif

# DPControl icevision board
# iCE40UP5K-SG48
# ---------------------------------------------
ifeq ($(BOARD),icevision)
DEVICE=up5k
PACKAGE=sg48
PROG_TOOL=$(ICEPROG_TOOL)
endif

# Default dummy
# iCE40 hx1k-tq144 (same as icestick)
# ---------------------------------------------
ifeq ($(BOARD),none)
DEVICE=hx1k
PACKAGE=tq144
PROG_TOOL=true
endif

# ---------------------------------------------

ifeq ($(DEVICE),)
$(error No $$DEVICE set.)
endif
ifeq ($(PACKAGE),)
$(error No $$PACKAGE set.)
endif
ifeq ($(PROG_TOOL),)
$(error No $$PROG_TOOL set.)
endif
