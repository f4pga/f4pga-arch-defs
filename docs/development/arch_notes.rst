Device Architecture Notes
=========================

The following notes describe in more details the approach required to add new architectures, or enhance an already existing architecture with additional tiles and primitives.

Adding a new tiles and primitives
---------------------------------

In Symbiflow Architecture Definitions, this process requires modifications of two parts in the flow which can be summarized in the following points:

- **VTR** Physical Block type definition
- **Yosys** techmap definition

Physical Block Type Definition
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This is a VTR-related file which includes a detailed description of the internal logic of the block, as well as its I/O interface.

More details can be gathered in the [official VTR documentation](https://docs.verilogtorouting.org/en/latest/arch/reference/).

The primitives are located under `<vendor>/<fpga-family>/common/primitives/`. In general, there should be one subdirectory for each different primitive, or in alternative for each intermediate site that contains a primitive.

It is common that a primitive is included in a hierarchy of Physical Block Types (PB types) before reaching the Top-level one.

The PB types must conform to the physical representation of the primitive/site that needs to be modeled.
To understand the interconnections and composition of each primitive/site, usually it is necessary to read the vendor-provided documentation of the particular block that needs to be modeled.

CMake is used to generate all the targets to include the newly added primitive to the architecture

The Symbiflow Architecture Definitions project provides a well documented CMake library of functions to aid in this process. The common functions are located under `common/cmake/` while the vendor-specific ones are located under `<vendor>/<fpga-family>/common/cmake`.

The new tiles and primitives must be enabled by creating new `CMakeLists.txt` files within the corresponding directories in the following locations:

- **Primitives**: `<vendor>/<fpga-family>/common/primitives/<primitive>`
- **Tile**: `<vendor>/<fpga-family>/archs/<arch>/tiles/<tile>`

Moreover, each new directory needs to be added to the parent `CMakeLists.txt`, so that CMake can find and process the new additions.

The enable a new tile/pb_type in a target device, the device CMake file needs to be changed accordingly, as follows:

.. code-block:: cmake

   add_xc_device_define_type(
     ARCH artix7
     DEVICE xc7a50t
     TILE_TYPES
       CLBLL_L
       CLBLL_R
       CLBLM_L
       CLBLM_R
       NEW_TILE
     PB_TYPES
       SLICEL
       SLICEM
       NEW_PB_TYPE
   )

The device `CMakeLists.txt` file is located under `<vendor>/<fpga-family>/archs/<arch>/devices/<device>/`.

Yosys Techmap and Simulation models
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Yosys is the synthesis tool used in Symbiflow, but, to allow VPR to elaborate Yosys output netlist, we need to perform a technology mapping pass to transform the Yosys-generated primitives to the VPR-compatible ones.

To do so, there are two relevant files to modify, both located under `<vendor>/<fpga-family>/techmap`:

- `cellmap.v`: Defines how specific cells need to be re-mapped.
- `cellsim.v`: Defines the VPR-specific cells that will be present in the `.eblif` output.
