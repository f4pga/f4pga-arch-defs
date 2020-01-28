create_clock -period 10 clk
create_clock -period 10 virtual_io_clock
create_clock -period 10 soc.simpleuart.clk__clk_bufg__soc.clk__soc.cpu.clk__soc.cpu.cpuregs.clk__soc.cpu.pcpi_div.clk__soc.cpu.pcpi_mul.clk__soc.memory.clk__soc.progmem.clk

