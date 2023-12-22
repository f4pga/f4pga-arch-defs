set_property -dict { PACKAGE_PIN R2    IOSTANDARD SSTL135 } [get_ports { clk }]; #IO_L12P_T1_MRCC_34 Sch=ddr3_clk[200]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5.000}  [get_ports { clk }];

set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVCMOS33 } [get_ports { led[0] }]; #IO_L16N_T2_A27_15 Sch=led[2]
set_property -dict { PACKAGE_PIN F13   IOSTANDARD LVCMOS33 } [get_ports { led[1] }]; #IO_L17P_T2_A26_15 Sch=led[3]
set_property -dict { PACKAGE_PIN E13   IOSTANDARD LVCMOS33 } [get_ports { led[2] }]; #IO_L17N_T2_A25_15 Sch=led[4]
set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33 } [get_ports { led[3] }]; #IO_L18P_T2_A24_15 Sch=led[5]

set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property INTERNAL_VREF 0.675 [get_iobanks 34]
