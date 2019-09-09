# Temporary repositories to perform master+wip update
SHELL:=/bin/bash
NPROC ?= 4

VTR=vtr
YOSYS=yosys

clean:
	rm -rf ${VTR} ${YOSYS}

update-vtr:
	./update_tools.py git@github.com:SymbiFlow/vtr-verilog-to-routing.git ${VTR}
	# Testing that VTR is correctly integrated in SymbiFlow
	pushd ${VTR};                                   \
	make -j`nproc`;                                 \
	export VTR=`pwd`/build/vpr/vpr;                 \
	export GENFASM=`pwd`/build/utils/fasm/genfasm;  \
	popd                                            \
	make all_xc7 -j${NPROC} && make all_ice40 -j${NPROC} && make all_v2x -j${NPROC}
	# If tests are successful push force tool master+wip-next
	cd ${VTR}; git push --force origin master+wip-next
	rm -rf ${VTR}
