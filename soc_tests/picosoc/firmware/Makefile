CC = ${RISCV}/bin/riscv32-unknown-elf-gcc
OC = ${RISCV}/bin/riscv32-unknown-elf-objcopy

all: firmware.elf firmware.hex disassembly

clean:
	rm -rf *.elf
	rm -rf *.hex

firmware.elf: sections.lds start.s firmware.c
	${CC} -DHX8KDEMO -DNOSPIFLASH -march=rv32im -Wl,-Bstatic,-T,sections.lds,--strip-debug -ffreestanding -nostdlib -mstrict-align -O0 -o firmware.elf start.s firmware.c

firmware.hex: firmware.elf
	${OC} -O verilog firmware.elf firmware.hex

disassembly: firmware.elf
	${RISCV}/bin/riscv32-unknown-elf-objdump -d firmware.elf >disassembly.txt

