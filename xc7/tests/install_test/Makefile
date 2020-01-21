mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(patsubst %/,%,$(dir $(mkfile_path)))
TOP:=top
VERILOG:=${current_dir}/counter_basys3.v
DEVICE:=xc7a50t_test
BITSTREAM_DEVICE:=artix7
PCF=basys.pcf
BUILDDIR:=build

all: ${TOP}.bit

${BUILDDIR}:
	mkdir ${BUILDDIR}

${TOP}.eblif: ${BUILDDIR}
	cd ${BUILDDIR} && synth -t ${TOP} -v ${VERILOG}

${TOP}.net: ${TOP}.eblif
	cd ${BUILDDIR} && pack -e ${TOP}.eblif -d ${DEVICE}

${TOP}.place: ${TOP}.net
	cd ${BUILDDIR} && place -e ${TOP}.eblif -d ${DEVICE} -p ${PCF} -n ${TOP}.net

${TOP}.route: ${TOP}.place
	cd ${BUILDDIR} && route -e ${TOP}.eblif -d ${DEVICE}

${TOP}.fasm: ${TOP}.route
	cd ${BUILDDIR} && write_fasm -e ${TOP}.eblif -d ${DEVICE}

${TOP}.bit: ${TOP}.fasm
	cd ${BUILDDIR} && write_bitstream -d ${BITSTREAM_DEVICE} -f ${TOP}.fasm -b ${TOP}.bit

clean:
	rm -rf ${BUILDDIR}

