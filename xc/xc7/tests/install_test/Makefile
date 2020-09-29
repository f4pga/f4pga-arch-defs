mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(patsubst %/,%,$(dir $(mkfile_path)))
TOP:=top
PARTNAME:= xc7a35tcpg236-1
DEVICE  := xc7a50t_test
BOARD   := basys3
BITSTREAM_DEVICE := artix7
VERILOG:=${current_dir}/counter_${BOARD}.v
PCF=${current_dir}/${BOARD}.pcf
XDC=${current_dir}/counter_${BOARD}.xdc
BUILDDIR:=build
ADDITIONAL_VPR_OPTIONS="--seed 1024 --astar_fac 1.3"

all: ${BUILDDIR}/${TOP}.bit

${BUILDDIR}:
	mkdir ${BUILDDIR}

${BUILDDIR}/${TOP}.eblif: | ${BUILDDIR}
ifeq (,$(wildcard ${XDC}))
	cd ${BUILDDIR} && symbiflow_synth -t ${TOP} -v ${VERILOG} -d ${BITSTREAM_DEVICE} -p ${PARTNAME}
else
	cd ${BUILDDIR} && symbiflow_synth -t ${TOP} -v ${VERILOG} -x ${XDC} -d ${BITSTREAM_DEVICE} -p ${PARTNAME}
endif

${BUILDDIR}/${TOP}.net: ${BUILDDIR}/${TOP}.eblif
	cd ${BUILDDIR} && symbiflow_pack -e ${TOP}.eblif -d ${DEVICE} -a ${ADDITIONAL_VPR_OPTIONS}

${BUILDDIR}/${TOP}.place: ${BUILDDIR}/${TOP}.net
	cd ${BUILDDIR} && symbiflow_place -e ${TOP}.eblif -d ${DEVICE} -p ${PCF} -n ${TOP}.net -P ${PARTNAME} -a ${ADDITIONAL_VPR_OPTIONS}

${BUILDDIR}/${TOP}.route: ${BUILDDIR}/${TOP}.place
	cd ${BUILDDIR} && symbiflow_route -e ${TOP}.eblif -d ${DEVICE} -a ${ADDITIONAL_VPR_OPTIONS}

${BUILDDIR}/${TOP}.fasm: ${BUILDDIR}/${TOP}.route
	cd ${BUILDDIR} && symbiflow_write_fasm -e ${TOP}.eblif -d ${DEVICE} --additional_vpr_options ${ADDITIONAL_VPR_OPTIONS}

${BUILDDIR}/${TOP}.bit: ${BUILDDIR}/${TOP}.fasm
	cd ${BUILDDIR} && symbiflow_write_bitstream -d ${BITSTREAM_DEVICE} -f ${TOP}.fasm -p ${PARTNAME} -b ${TOP}.bit

clean:
	rm -rf ${BUILDDIR}

