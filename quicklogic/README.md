# SymbiFlow for Quicklogic FPGAs

Currently the supported families are:
- qlf_k4n8

## Quickstart guide

### 1. Build SymbiFlow

Clone the SymbiFlow repository:

```bash
git clone https://github.com/SymbiFlow/symbiflow-arch-defs
```

Set up the environment:

```bash
make env
```

The command will automatically clone all GIT submodules, setup a Conda environment with all the necessary packages and generate the build system by invoking CMake.

### 2. Generate routing for a sample design

Once the SymbiFlow environment is set up, you can perform the implementation (synthesis, placement and routing) of an example FPGA designs.

Choose a target FPGA family, go to the `quicklogic/<family>/tests` directory and choose a design you want to implement e.g:

```bash
cd quicklogic/qlf_k4n8/tests/counter
make counter-umc22-adder_route
```

This will generate a routing file for the design. For details of each of the test design please refer to its `README.md` file.

## Naming convention

The naming convention of all build targets is: `<design_name>-<board_name>_<stage_name>`

The `<design_name>` corresponds to the name of the design.
The `<board_name>` defines the board that the design is targetted for.
The last part `<stage_name>` defines the last stage of the flow that is to be executed.

The most important stages are:

- **eblif**
    Runs Yosys synthesis and generates an EBLIF file suitable for VPR. The output EBLIF file is named `top.eblif`

- **pack**
    Runs VPR packing stage. The packed design is written to the `top.net` file.

- **place**
    Runs VPR placement stage. Design placement is stored in the `top.place` file. IO placement constraints for VPR are written to the `top_io.place` file.

- **route**
    Runs VPR routing. Design routing data is stored in the `top.route` file.

- **analysis**
    Runs VPR analysis, writes post-route netlists in BLIF and Verilog format plus an SDF file with post routing timing analysis.

- **fasm**
    Generates the FPGA assembly file (a.k.a. FASM) using the routed design. The FASM file is named `top.fasm`.

Executing a particular stage implies that all stages before it will be executed as well (if needed). They form a dependency chain.

## Adding new designs to SymbiFlow

To to add a new design to the flow, and use it as a test follow the guide:

1. Create a subfolder for your design under the `quicklogic/<family>/tests` folder.

1. Add inclusion of the folder in the `quicklogic/<family>/tests/CMakeLists.txt` by adding the following line to it:

    ```plaintext
    add_subdirectory(<your_directory_name>)
    ```

1. Add a `CMakeLists.txt` file to your design. Specify your design settings inside it:

    ```plaintext
    add_fpga_target(
      NAME            <your_design_name>
      BOARD           <target_board_name>
      SOURCES         <verilog sources list>
      INPUT_IO_FILE   <PCF file with IO constraints>
      SDC_FILE        <SDC file with timing constraints>
      )
    ```

    The design name can be anything. For available board names please refer to the `quicklogic/<family>/boards.cmake` file. Input IO constraints have to be given in the *PCF* format. The *SDC* file argument is optional. 
    Please also refer to CMake files for existing designs.
    All the files passed to `add_fpga_target` have to be added to the flow with `add_file_target` e.g:
    
    ```plaintext
    add_file_target(FILE counter.v SCANNER_TYPE verilog)
    add_file_target(FILE io_constraints.pcf)
    ```
    
    The verilog scanner will automatically add all the verilog dependecies explicitely included in the added file.
    
1. Once this is done go back to the SymbiFlow root directory and re-run the make env command to update build targets:

   ```bash
   make env
   ```

1. Now enter the build directory of your project and run the appropriate target as described:

   ```bash
   cd build/quicklogic/<faimly>/tests/<your_directory_name>
   make <your_design_name>-<target_board_name>_<stage_name>
   ```

## Known limitations

SymbiFlow support for Quicklogic FPGAs is currently under heavy development. The current support for the qlf_k4n8 family does not support binary bitstream generation. FASM file generation is supported but is still being worked on.
