Xilinx 7 Series F4PGA Partial Reconfiguration Flow
##################################################

.. Note::
  F4PGA currently does not support partial bitstream generation.
  This is a goal in the future, but at the moment partial FASM must be concatenated with an overlay to generate a full
  bitstream.

Background
==========

Partition Regions
-----------------

In this documentation the terms partition region and region of interest (ROI) are used interchangeably to refer to some
smaller portion of a larger FPGA architecture.
This region may or may not align with frame boundaries, but the most tested use-case is for partition regions that are
one clock region tall.

Overlay Architecture
--------------------

The overlay architecture is essentially the "inverse" of all the partition regions in a design; it includes everything
in the full device that is not in a partition region.
Typically this includes chip IOs and the PS region if the chip has one.

Synthetic IO Tiles (Synth IOs)
------------------------------

Synthetic IO tiles are "fake" IOs inserted into the partition region architecture so VPR will route top level IOs to a
specific graph node.
This method allows partition region architectures to interface with each other and the overlay.

Vivado Node vs Wire
-------------------

A wire is a small electrically connected part of the FPGA contained within a single tile.
A Vivado node is an electrically connected collection of wires that can span multiple tiles.

Flow Overview
=============

A simplified view of the partition region flow is as follows:

-  Define each partition region architecture

-  Define the overlay architecture based on the partition regions chosen

-  Build each architecture separately

-  Map a top level verilog file to each architecture

-  Generate FASM for each partition region and the overlay

-  Concatenate FASM for each architecture together and generate final bitstream

Partition Region Example (switch_processing)
============================================

This example contains two partition regions that are each about the size of one clock region.

The goal of this test is to have two partition regions with identical interfaces so switch "data" can be passed through
each region before being displayed on LEDs.
Each partition region can then have an arbitrary module mapped to it that processes the data in some way before the
output.
The example modules used currently are an add_1 module, a blink module, and an identity module.

Define the first partition region:

:ghsrc:`xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-pr1-roi-virt/design.json`

.. literalinclude:: ../../../xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-pr1-roi-virt/design.json
  :language: JSON

Here we see the info section defines the boundaries of the partition region.
It is important to use the prjxray grid, not the VPR grid or the Vivado grid, to define these boundaries.
The ports section is then used to define the interface pins for the region.
A synth IO will be placed to correspond to each of these interface pins.
Each pin must contain a name, pin name, type, and node name.
The name and pin name must be unique identifiers.
The type can be in, out or clk.
The node is the vivado node that a synth IO should be connected to.

Optionally, a wire name can be provided to give an exact location for the synth IO.
If a wire is not provided it will be inferred as the first wire outside of the partition region on the given node.
Providing an explicit wire name is especially important when using nodes that cross all the way through the partition
region, such as clock nodes.

Now the CMake files must be defined properly for the first partition region architecture:

:ghsrc:`xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-pr1-roi-virt/CMakeLists.txt`

.. literalinclude:: ../../../xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-pr1-roi-virt/CMakeLists.txt
  :language: cmake

The important argument here is ``ROI_DIR`` which points to the directory containing the ``design.json`` defined earlier.

Next, define the second partition region in a similar way as the first:

:ghsrc:`xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-pr2-roi-virt/design.json`

.. literalinclude:: ../../../xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-pr2-roi-virt/design.json
  :language: JSON

:ghsrc:`xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-pr2-roi-virt/CMakeLists.txt`

.. literalinclude:: ../../../xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-pr2-roi-virt/CMakeLists.txt
  :language: cmake

The last ``design.json`` that must be defined is for the overlay.
It is mostly a list of the json for the partition regions contained in the design.
One important change is the pin names must still be unique across all ports in the overlay.
Any explicit wires must also be changed to be on the other side of the partition region boundary.

:ghsrc:`xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-overlay-virt/design.json`

.. literalinclude:: ../../../xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-overlay-virt/design.json
  :language: JSON

:ghsrc:`xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-overlay-virt/CMakeLists.txt`

.. literalinclude:: ../../../xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-overlay-virt/CMakeLists.txt
  :language: cmake

The important argument here is ``OVERLAY_DIR`` which points to the directory containing the ``design.json`` for this
overlay.
Notice this ``CMakeLists.txt`` also contains more tile/pb types because it contains the real IOs.

Continuing on past ``design.json`` definitions, CMake needs to be informed these new architectures should be built.
This is done in another ``CMakeLists.txt`` by adding the following:

:ghsrc:`xc/xc7/archs/artix7/devices/CMakeLists.txt`

.. literalinclude:: ../../../xc/xc7/archs/artix7/devices/CMakeLists.txt
  :language: cmake

The last step before switching over to adding a test is adding to ``boards.cmake``:

:ghsrc:`xc/xc7/boards.cmake`

.. literalinclude:: ../../../xc/xc7/boards.cmake
  :language: cmake

This defines a separate board for each of the partition regions and overlay so they can be mapped to separately.

Now to define a test.
This part of the documentation will not go in detail on how to define a new test case in f4pga-arch-defs, but will
point out items of importance for using the partial reconfiguration flow.

All of the following snippets are from :ghsrc:`xc/xc7/tests/switch_processing/CMakeLists.txt`.

.. code-block:: cmake

	add_file_target(FILE switch_processing_add_1.v SCANNER_TYPE verilog)
	add_fpga_target(
	  NAME switch_processing_arty_add_1_pr1
	  BOARD arty-switch-processing-pr1
	  SOURCES switch_processing_add_1.v
	  INPUT_IO_FILE ${COMMON}/arty_switch_processing_pr1.pcf
	  EXPLICIT_ADD_FILE_TARGET
	  )

	add_file_target(FILE switch_processing_blink.v SCANNER_TYPE verilog)
	add_fpga_target(
	  NAME switch_processing_arty_blink_pr2
	  BOARD arty-switch-processing-pr2
	  SOURCES switch_processing_blink.v
	  INPUT_IO_FILE ${COMMON}/arty_switch_processing_pr2.pcf
	  EXPLICIT_ADD_FILE_TARGET
	  )

	add_file_target(FILE switch_processing_identity.v SCANNER_TYPE verilog)
	add_fpga_target(
	  NAME switch_processing_arty_identity_pr1
	  BOARD arty-switch-processing-pr1
	  SOURCES switch_processing_identity.v
	  INPUT_IO_FILE ${COMMON}/arty_switch_processing_pr1.pcf
	  EXPLICIT_ADD_FILE_TARGET
	  )

	add_fpga_target(
	  NAME switch_processing_arty_identity_pr2
	  BOARD arty-switch-processing-pr2
	  SOURCES switch_processing_identity.v
	  INPUT_IO_FILE ${COMMON}/arty_switch_processing_pr2.pcf
	  EXPLICIT_ADD_FILE_TARGET
	  )

Here the add_1 and blink modules are mapped to pr1 and pr2 respectively.
The identity function is then also mapped to each partition region.

.. code-block:: cmake

	add_file_target(FILE switch_processing_arty_overlay.v SCANNER_TYPE verilog)
	add_fpga_target(
	  NAME switch_processing_arty_overlay
	  BOARD arty-switch-processing-overlay
	  SOURCES switch_processing_arty_overlay.v
	  INPUT_IO_FILE ${COMMON}/arty_switch_processing_overlay.pcf
	  EXPLICIT_ADD_FILE_TARGET
	  )

Here the overlay verilog is mapped to the overlay architecture.
This overlay verilog connects switches to the input of the first partition region, connects the output of the first
partition region to the input of the second partition region, and then connects the output of the second partition
region to LEDs.

.. code-block:: cmake

	add_bitstream_target(
	  NAME switch_processing_arty_both_merged
	  USE_FASM
	  INCLUDED_TARGETS switch_processing_arty_add_1_pr1 switch_processing_arty_blink_pr2 switch_processing_arty_overlay
	  )

	add_bitstream_target(
	  NAME switch_processing_arty_add_1_merged
	  USE_FASM
	  INCLUDED_TARGETS switch_processing_arty_add_1_pr1 switch_processing_arty_identity_pr2 switch_processing_arty_overlay
	  )

	add_bitstream_target(
	  NAME switch_processing_arty_blink_merged
	  USE_FASM
	  INCLUDED_TARGETS switch_processing_arty_identity_pr1 switch_processing_arty_blink_pr2 switch_processing_arty_overlay
	  )

	add_bitstream_target(
	  NAME switch_processing_arty_identity_merged
	  USE_FASM
	  INCLUDED_TARGETS switch_processing_arty_identity_pr1 switch_processing_arty_identity_pr2 switch_processing_arty_overlay
	  )

Lastly, multiple merged bitstream targets are defined.
These targets will concatenate the FASM generated by each included target and produce the final bitstream.
By varying which targets are included different functionality is created without having to remap any new regions after
it has been done once.
Just concatenate the resulting FASM and get different functionality.

The last thing to cover related to the F4PGA partial reconfiguration flow is synthetic ibufs and obufs required in
the overlay verilog:

:ghsrc:`switch_processing_arty_overlay.v <xc/xc7/tests/switch_processing/switch_processing_arty_overlay.v>`

Currently the ``SYN_IBUF`` and ``SYN_OBUF`` must be explicitly defined for each top level IO that will be constrained to
a synth IO.
In the future this should be able to be resolved using a yosys io map pass, but currently if explicit synthetic buffers
are not defined the top level IOs will be packed into a real IO.
This will prevent constraining the top level IOs to the intended synthetic IO location.

The overlay pcf file can then be written to constrain real IOs to chip IOs and synthetic IOs to synthetic IOs.


Frequently Encountered Errors
=============================

SYN-IOPAD unroutable
--------------------

* Make sure the chosen node is driven in the correct direction for the I/O type it is being used as.

* Inputs to a partition region must be driven from outside the partition region and outputs must be driven from inside
  the partition region.
