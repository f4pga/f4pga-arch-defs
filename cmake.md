## CMake build system
### Terminology

The CMake system in symbiflow-arch-defs uses the following hierarchy:

* `ARCH` - Architecture is the high level grouping of a set of "similar" FPGA
  types. An example would be the "Lattice iCE40 Series" (ice40) or the "Xilinx Artix 7 Series" (artix7).
* `DEVICE_TYPE` - A type of device.  This is defined as an `ARCH` and the
  arch.xml which defines the units with this device type.
* `DEVICE` - A specific instance of a `DEVICE_TYPE`.  A device definition is
   a `DEVICE_TYPE`, a `PACKAGE` list, and IO map definitions for each package
   if needed.  Each `DEVICE` should coorispond with a layout definition within
   the `DEVICE_TYPE`.
* `BOARD` - A specific `DEVICE` and `PACKAGE` instance, along with a
  `PROG_TOOL`/`PROG_CMD` (e.g. commands to program a specified board).

### Creating a new FPGA target

If you are familiar with cmake, `ADD_FPGA_TARGET` is the rough equivalent to
the normal `ADD_EXECUTABLE` target you would use with a C project.

`ADD_FPGA_TARGET` will create the targets needed to take a design from Verilog
to bitstream through the synthesis, place and route, bitstream and potentially
even programming. The required arguments are the `BOARD` and input files see
[`ADD_FPGA_TARGET` documentation](make/devices.cmake#L559) for further
information on other target configuration options.

If you want to target multiple boards, `ADD_FPGA_TARGET_BOARDS` exists
that will call `ADD_FPGA_TARGET` correctly for each board you request.  See
[`ADD_FPGA_TARGET_BOARDS` documentation](make/devices.cmake#L458).

#### Note on `ADD_FILE_TARGET` and `ADD_FPGA_BOARD`

All source files in the symbiflow-arch-defs are required to have a file target
associated with them.  This is done via
[`ADD_FILE_TARGET`](make/file_targets.cmake#L193).  By default
`ADD_FPGA_TARGET` and `ADD_FPGA_TARGET_BOARDS` will both implicitly invoke
`ADD_FILE_TARGET` for you.  This handles the common case where input sources
are not generated files.  However, if you are using generated files, then you
will need to add `ADD_FILE_TARGET` calls for all inputs to `ADD_FPGA_TARGET`.

For non-generated verilog, `ADD_FILE_TARGET` should be invoked like:
```
add_file_target(FILE <current source dir relative path> SCANNER_TYPE verilog)
```

For generated verilog, `ADD_FILE_TARGET` should be invoked like:
```
add_file_target(FILE <current source dir relative path> GENERATED)
```
Note that the input path must be current source dir relative, not absolute,
and not relative to the cmake current binary dir.  Also note that CMake cannot
take depedendencies during build time, so for generated files you must supply
the dependencies for the target.  See
[`APPEND_FILE_DEPENDENCY`](make/file_targets.cmake#L79) for adding depedencies
to other file targets.

It is generally suggested that all source forms within
symbiflow-arch-defs are file targets, but it is required for verilog files
because of how verilog handles relative include paths. Verilog defines relative
paths as relative to the location of the file, not to the location of the
compiler. As a result, if you use relative includes to include both a
generated and non-generated file, unless the files are moved to a unified
source tree, verilog relative includes will not work. `ADD_FILE_TARGET` solves
this by copying non-generated files to the binary directory.
