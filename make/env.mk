include make/inc/common.mk

MINICONDA_FILE := Miniconda3-latest-Linux-x86_64.sh
MINICONDA_URL  := https://repo.continuum.io/miniconda/$(MINICONDA_FILE)

CONDA_BIN_DIR := $(abspath ./env/conda/bin/)

CONDA := $(CONDA_BIN_DIR)/conda
CONDA_YOSYS := $(CONDA_BIN_DIR)/yosys
CONDA_VPR   := $(CONDA_BIN_DIR)/vpr
CONDA_MAKE  := $(CONDA_BIN_DIR)/make

env/$(MINICONDA_FILE):
	mkdir -p env
	wget $(MINICONDA_URL) -O $(TARGET)

$(CONDA): env/$(MINICONDA_FILE)
	sh $(PREREQ_FIRST) -p env/conda -b -f
	$(CONDA) config --system --set always_yes yes

env/conda/envs: $(CONDA)
	$(CONDA) config --system --add envs_dirs $(TARGET)

env/conda/pkgs: $(CONDA)
	$(CONDA) config --system --add pkgs_dirs $(TARGET)

# TODO(mithro): Move to a "conda-symbiflow-packages" rather then leaching off
# the TimVideos packages.
env/conda/.timvideos.channel: $(CONDA) env/conda/envs env/conda/pkgs
	$(CONDA) config --add channels timvideos

CONDA_SETUP := $(CONDA) env/conda/envs env/conda/pkgs env/conda/.timvideos.channel

$(CONDA_YOSYS): $(CONDA_SETUP)
	$(CONDA) install yosys

$(CONDA_VPR): $(CONDA_SETUP)
	$(CONDA) install vtr

$(CONDA_MAKE): $(CONDA_SETUP)
	$(CONDA) install make

make: $(CONDA_MAKE)
	@true

.PHONY: make

env: $(CONDA_YOSYS) $(CONDA_VPR)
	@echo $(PREREQ_ALL)

.PHONY: env

# If the environment exists, put it into the path.
ifneq (,$(wildcard $(abspath env)))
PATH := $(CONDA)/bin:$(PATH)
endif
