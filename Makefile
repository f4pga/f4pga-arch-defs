# Makefile
TOP_DIR := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
REQUIREMENTS_FILE := requirements.txt
ENVIRONMENT_FILE := conda_lock.yml

third_party/make-env/conda.mk:
	git submodule init
	git submodule update --init --recursive

include third_party/make-env/conda.mk

ifeq ($(origin CMAKE_COMMAND),undefined)
CMAKE_COMMAND := cmake
else
CMAKE_COMMAND := ${CMAKE_COMMAND}
endif

.PHONY: all env

all: env
	cd build && $(MAKE)

clean::
	rm -rf build

# Conda Lock contains all dependencies. PIP often fails if a package is both
# specified to be installed directly and as a dependency of another package.
env:: export PIP_NO_DEPS = true
env:: | $(CONDA_ENV_PYTHON)
	git submodule init
	git submodule update --init --recursive
	@$(IN_CONDA_ENV) mkdir -p build && cd build && $(CMAKE_COMMAND) ${CMAKE_FLAGS} ..

build/Makefile:
	make env

.PHONY: Makefile

#%: build/Makefile
#	@$(IN_CONDA_ENV) cd build && $(MAKE) $@
