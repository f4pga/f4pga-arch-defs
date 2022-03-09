# Temporary repositories to perform master+wip update
SHELL:=/bin/bash
NPROC ?= 4

VTR_LOCATION ?= `pwd`/vtr
VTR_URL ?= git@github.com:SymbiFlow/vtr-verilog-to-routing.git
VTR_OPTIONS = --location ${VTR_LOCATION} --url ${VTR_URL}

YOSYS_LOCATION ?= `pwd`/yosys
YOSYS_URL ?= git@github.com:SymbiFlow/yosys.git
YOSYS_OPTIONS = --location ${YOSYS_LOCATION} --url ${YOSYS_URL}

update-vtr:
	./update_tools.py ${VTR_OPTIONS}
	# Testing that VTR is correctly integrated in SymbiFlow
	pushd ${VTR_LOCATION};                          \
	make -j`nproc`;                                 \
	export VTR=`pwd`/build/vpr/vpr;                 \
	export GENFASM=`pwd`/build/utils/fasm/genfasm;  \
	popd                                            \
	make all_xc7 -j${NPROC} && make all_ice40 -j${NPROC} && make all_v2x -j${NPROC}
	# If tests are successful push force tool master+wip-next

clean:
	rm -rf ${VTR_LOCATION} ${YOSYS_LOCATION}
