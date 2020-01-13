TOP:=top
VERILOG:=counter_basys3.v
DEVICE:=xc7a50t_test
BITSTREAM_DEVICE:=artix7
PCF=basys.pcf

all: ${TOP}.bit

${TOP}.eblif:
	synth -t ${TOP} -v ${VERILOG}

${TOP}.net: ${TOP}.eblif
	pack -e ${TOP}.eblif -d ${DEVICE}

${TOP}.place: ${TOP}.net
	place -e ${TOP}.eblif -d ${DEVICE} -p ${PCF} -n ${TOP}.net

${TOP}.route: ${TOP}.place
	route -e ${TOP}.eblif -d ${DEVICE}

${TOP}.fasm: ${TOP}.route
	write_fasm -e ${TOP}.eblif -d ${DEVICE}

${TOP}.bit: ${TOP}.fasm
	write_bitstream -d ${BITSTREAM_DEVICE} -f ${TOP}.fasm -b ${TOP}.bit

clean:
	rm -f *.rpt
	rm -f *.log
	rm -f *.place
	rm -f ${TOP}.json
	rm -f ${TOP}_synth*
	rm -f ${TOP}.eblif
	rm -f ${TOP}.route
	rm -f ${TOP}.fasm
	rm -f ${TOP}.frames
	rm -f ${TOP}.bit
	rm -f ${TOP}.net

