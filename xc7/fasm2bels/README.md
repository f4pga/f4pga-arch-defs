FASM 2 BELs
-----------

fasm2bels is a tool designed to take a FASM file into Vivado.

It does this by generating a file describing the BEL connections (techmapped
Verilog) and TCL commands for Vivado which lock the BEL placements.

This makes it possible to perform simulation and analysis of a FASM file inside
Vivado.

In the absence of bugs, it is expected that after consuming the BEL
connections and TCL constraints Vivado will produce a bitstream identical to
the bitstream the FASM file would generate.

Invoking
--------

`python3 -mfasm2bels <options> <verilog> <tcl>`

Required arguments are:
 - `--connection_database` - Path to connection database for part
 - `--db_root` - Path to prjxray database for part
 - `--fasm_file` - Path to FASM file to process
 - verilog - Path to verilog file to write
 - tcl - Path to TCL file to write

Once the verilog and TCL is generated, it should be importable to Vivado with
a script roughly like:

```
create_project -force -part {part} design design

read_verilog {bit_v}
synth_design -top {top}
source {bit_tcl}
set_property IS_ENABLED 0 [get_drc_checks {{LUTLP-1}}]
place_design
route_design
```

Timing constraints should be provided as needed, along with other property
modifications as needed for the design.  These properties are not embedded in
the bitstream, so must be supplied external.

Examples:
 - `set_property CFGBVS VCCO [current_design]`
 - `set_property CONFIG_VOLTAGE 3.3 [current_design]`

BELs / Sites supported
----------------------

- SLICEL (all)
- SLICEM (all)
- RAMB18/RAMB36 (BRAM only, no FIFO support)
- IOB (limited IOSTANDARDs)
- IOI (no IDELAY/IDDR/ISERDES/ODDR/ISERDES support)
- CLK\_HROW\_\*
- CLK\_BUFG\_\*

Future work
-----------
 - PLLs and MMCMs
 - IDELAY/IDRR/ISERDES
 - ODDR/OSERDES
 - BUFR/BUFMR and other clock buffers
 - DSP
