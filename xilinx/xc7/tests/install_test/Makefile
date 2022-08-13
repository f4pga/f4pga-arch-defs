mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(patsubst %/,%,$(dir $(mkfile_path)))
TOP:=top
PARTNAME?= xc7a35tcpg236-1
DEVICE  ?= xc7a50t_test
BOARD   ?= basys3
BITSTREAM_DEVICE ?= artix7
VERILOG:=${current_dir}/counter.v
XDC=${current_dir}/${BOARD}.xdc
BUILDDIR:=build_${BOARD}
ADDITIONAL_VPR_OPTIONS="--seed 1024"

# Determine if we should use uhdm-plugin to read sources
ifneq (${SURELOG_CMD},)
	SURELOG_OPT := -s ${SURELOG_CMD}
	BUILDDIR = build_${BOARD}_surelog
endif

all: ${BUILDDIR}/${TOP}.bit

${BUILDDIR}:
	mkdir ${BUILDDIR}

${BUILDDIR}/${TOP}.eblif: | ${BUILDDIR}
	cd ${BUILDDIR} && symbiflow_synth -t ${TOP} ${SURELOG_OPT} -v ${VERILOG} -d ${BITSTREAM_DEVICE} -p ${PARTNAME} -x ${XDC}

${BUILDDIR}/${TOP}.net: ${BUILDDIR}/${TOP}.eblif
	cd ${BUILDDIR} && symbiflow_pack -e ${TOP}.eblif -d ${DEVICE} -- ${ADDITIONAL_VPR_OPTIONS}

${BUILDDIR}/${TOP}.place: ${BUILDDIR}/${TOP}.net
	cd ${BUILDDIR} && symbiflow_place -e ${TOP}.eblif -d ${DEVICE} -n ${TOP}.net -P ${PARTNAME} -- ${ADDITIONAL_VPR_OPTIONS}

${BUILDDIR}/${TOP}.route: ${BUILDDIR}/${TOP}.place
	cd ${BUILDDIR} && symbiflow_route -e ${TOP}.eblif -d ${DEVICE} -- ${ADDITIONAL_VPR_OPTIONS}

${BUILDDIR}/${TOP}.fasm: ${BUILDDIR}/${TOP}.route
	cd ${BUILDDIR} && symbiflow_write_fasm -e ${TOP}.eblif -d ${DEVICE} -- ${ADDITIONAL_VPR_OPTIONS}

${BUILDDIR}/${TOP}.bit: ${BUILDDIR}/${TOP}.fasm
	cd ${BUILDDIR} && symbiflow_write_bitstream -d ${BITSTREAM_DEVICE} -f ${TOP}.fasm -p ${PARTNAME} -b ${TOP}.bit

clean:
	rm -rf ${BUILDDIR}

