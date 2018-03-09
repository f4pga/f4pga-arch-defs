should_not_include = 1
include $(TOP_DIR)/make/inc/common.mk
include $(TOP_DIR)/make/inc/env.mk

MINICONDA_FILE := Miniconda3-latest-Linux-x86_64.sh
MINICONDA_URL  := https://repo.continuum.io/miniconda/$(MINICONDA_FILE)

$(ENV_DIR)/$(MINICONDA_FILE):
	mkdir -p $(ENV_DIR)
	wget $(MINICONDA_URL) -O $(TARGET)

$(CONDA_BIN): $(ENV_DIR)/$(MINICONDA_FILE)
	sh $(PREREQ_FIRST) -p $(CONDA_DIR) -b -f
	$(CONDA_BIN) config --system --set always_yes yes

$(CONDA_DIR)/envs: $(CONDA_BIN)
	$(CONDA_BIN) config --system --add envs_dirs $(TARGET)

$(CONDA_DIR)/pkgs: $(CONDA_BIN)
	$(CONDA_BIN) config --system --add pkgs_dirs $(TARGET)

# TODO(mithro): Move to a "conda-symbiflow-packages" rather then leaching off
# the TimVideos packages.
$(CONDA_DIR)/.timvideos.channel: $(CONDA_BIN) $(CONDA_DIR)/envs $(CONDA_DIR)/pkgs
	$(CONDA_BIN) config --add channels timvideos
	touch $(TARGET)

$(CONDA_DIR)/.conda-forge.channel: $(CONDA_BIN) $(CONDA_DIR)/envs $(CONDA_DIR)/pkgs
	$(CONDA_BIN) config --add channels conda-forge
	touch $(TARGET)

$(CONDA_DIR)/lib/python3.6/site-packages/lxml:
	$(CONDA_BIN) install lxml

CONDA_SETUP := \
  $(CONDA_BIN) \
  $(CONDA_DIR)/envs \
  $(CONDA_DIR)/pkgs \
  $(CONDA_DIR)/.timvideos.channel \
  $(CONDA_DIR)/.conda-forge.channel \

$(CONDA_YOSYS): | $(CONDA_SETUP)
	$(CONDA_BIN) install yosys

$(CONDA_VPR): | $(CONDA_SETUP)
	$(CONDA_BIN) install vtr

$(CONDA_MAKE): | $(CONDA_SETUP)
	$(CONDA_BIN) install make

$(CONDA_XSLTPROC): | $(CONDA_SETUP)
	$(CONDA_BIN) install libxslt

$(CONDA_PYTEST): | $(CONDA_SETUP)
	$(CONDA_BIN) install pytest

make:
	make -C $(TOP_DIR) -f $(TOP_DIR)/make/env.mk $(CONDA_MAKE)

.PHONY: make

env:
	make -C $(TOP_DIR) -f $(TOP_DIR)/make/env.mk $(CONDA_YOSYS) $(CONDA_VPR) $(CONDA_DIR)/lib/python3.6/site-packages/lxml

.PHONY: env

env-clean:
	@rm -rf $(ENV_DIR)

dist-clean: env-clean

.PHONY: env-clean
