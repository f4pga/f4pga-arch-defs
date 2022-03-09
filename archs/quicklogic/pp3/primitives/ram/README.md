# RAM model generator

RAM blocks in the EOS S3/PPE3 architecture can operate in many modes. Each mode has different timings. Therefore to implement it SymbiFlow there has to be one model/pb_type per each mode of operation.

The script `make_rams.py` generates everything that is needed. It reads a list (actually a tree) of RAM modes of operation from the `ram_modes.json` file. Each mode is defined by a certain combination of control signals that are connected either to 0 or to 1. These conditions are stored in the JSON file. Alongside with that file, the script also reads timings from an SDF file for the RAM cell. It looks for conditions defining control signal combinations and extracts appropriate timings.

To sum up, the script generates:

 - XML file with BLIF model definitions for VPR
 - XML file with pb_type tree for VPR
 - Verilog definitions of blackbox RAM cells for Yosys
 - Verilog techmap for Yosys that maps the RAM macro to appropriate RAM model(s)

The RAM macro actually represents two RAM cells that can be either concantenated together or not. When there is no concatenation, a macro is split into two independent RAM models.
