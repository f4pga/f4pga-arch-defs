CC = ${RISCV}/bin/riscv32-unknown-elf-gcc
OC = ${RISCV}/bin/riscv32-unknown-elf-objcopy
OD = ${RISCV}/bin/riscv32-unknown-elf-objdump

CFLAGS = -march=rv32im -Wl,-Bstatic,-T,sections.lds,--strip-debug -ffreestanding -nostdlib -mstrict-align -O0  

all: firmware_noflash_25.hex firmware_noflash_50.hex firmware_noflash_100.hex firmware_25.hex firmware_50.hex firmware_100.hex

clean:
	rm -rf *.elf
	rm -rf *.hex
	rm -rf *.lst

firmware_25.elf: sections.lds start.s firmware.c
	${CC} -DHX8KDEMO -DCLK_FREQ=25000000 ${CFLAGS} -o $@ start.s firmware.c
firmware_50.elf: sections.lds start.s firmware.c
	${CC} -DHX8KDEMO -DCLK_FREQ=50000000 ${CFLAGS} -o $@ start.s firmware.c
firmware_100.elf: sections.lds start.s firmware.c
	${CC} -DHX8KDEMO -DCLK_FREQ=100000000 ${CFLAGS} -o $@ start.s firmware.c

firmware_noflash_25.elf: sections.lds start.s firmware.c
	${CC} -DHX8KDEMO -DCLK_FREQ=25000000 -DNOSPIFLASH ${CFLAGS} -o $@ start.s firmware.c
firmware_noflash_50.elf: sections.lds start.s firmware.c
	${CC} -DHX8KDEMO -DCLK_FREQ=50000000 -DNOSPIFLASH ${CFLAGS} -o $@ start.s firmware.c
firmware_noflash_100.elf: sections.lds start.s firmware.c
	${CC} -DHX8KDEMO -DCLK_FREQ=100000000 -DNOSPIFLASH ${CFLAGS} -o $@ start.s firmware.c

%.hex: %.elf
	${OC} -O verilog $< $@

%.lst: %.elf
	${OD} -d $< >$@

