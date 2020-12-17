=================
Xilinx 7 Series SymbiFlow Partial Reconfiguration Flow
=================

Background
=================

Partition Regions
-----------------
In this documentation the terms partition region and region of interest (ROI) are used interchangeably to refer to some smaller portion of a larger FPGA architecture.  This region may or may not align with frame boundaries, but the most tested use-case is for partition regions that are one clock region tall.

Overlay Architecture
--------------------
The overlay architecture is essentially the "inverse" of all the partition regions in a design; it includes everything in the full device that is not in a partition region.  Typically this includes chip IOs and the PS region if the chip has one.

Synthetic IO Tiles (Synth IOs)
------------------------------
Synthetic IO tiles are "fake" IOs inserted into the partition region architecture so VPR will route top level IOs to a specific graph node. This method allows partition region architectures to interface with each other and the overlay.

Vivado Node vs Wire
-------------------
A wire is a small electrically connected part of the FPGA contained within a single tile. A Vivado node is an electrically connected collection of wires that can span multiple tiles.

Flow Overview
=============
A simplified view of the partition region flow is as follows:

-  Define each partition region architecture

-  Define the overlay architecture based on the partition regions chosen

-  Build each architecture separately

-  Map a top level verilog file to each architecture

-  Generate FASM for each partition region and the overlay

-  Concatenate FASM for each architecture together and generate final bitstream

-  Generate bitstreams for each partition region architecture

Partition Region Example (switch_processing)
============================================
This example contains two partition regions that are each about the size of one clock region.

The goal of this test is to have two partition regions with identical interfaces so switch "data" can be passed through each region before being displayed on LEDs. Each partition region can then have an arbitrary module mapped to it that processes the data in some way before the output. The example modules used currently are an add_1 module, a blink module, and an identity module.

Define the first partition region:

`xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-pr1-roi-virt/design.json`_

.. code-block:: javascript

	{
	    "info":
		{
		"name": "pr1",
		"GRID_X_MAX": 57,
		"GRID_X_MIN": 10,
		"GRID_Y_MAX": 51,
		"GRID_Y_MIN": 0
		},
	    "ports": [
		{
		    "name": "clk",
		    "type": "clk",
		    "node": "CLK_HROW_TOP_R_X60Y130/CLK_HROW_CK_BUFHCLK_L0",
		    "wire": "HCLK_L_X57Y130/HCLK_CK_BUFHCLK0",
		    "pin": "SYN0"
		},
		{
		    "name": "in[0]",
		    "type": "in",
		    "node": "INT_L_X0Y124/EE2BEG0",
		    "pin": "SYN1"
		},
		{
		    "name": "in[1]",
		    "type": "in",
		    "node": "INT_L_X0Y125/SE6BEG0",
		    "pin": "SYN2"
		},
		{
		    "name": "in[2]",
		    "type": "in",
		    "node": "INT_R_X1Y117/SE2BEG1",
		    "pin": "SYN3"
		},
		{
		    "name": "in[3]",
		    "type": "in",
		    "node": "INT_L_X0Y116/EE2BEG0",
		    "pin": "SYN4"
		},
		{
		    "name": "out[0]",
		    "type": "out",
		    "node": "INT_L_X2Y103/SE6BEG0",
		    "pin": "SYN5"
		},
		{
		    "name": "out[1]",
		    "type": "out",
		    "node": "INT_L_X4Y100/SE6BEG0",
		    "pin": "SYN6"
		},
		{
		    "name": "out[2]",
		    "type": "out",
		    "node": "INT_L_X2Y104/SS6BEG2",
		    "pin": "SYN7"
		},
		{
		    "name": "out[3]",
		    "type": "out",
		    "node": "INT_L_X2Y104/SS6BEG0",
		    "pin": "SYN8"
		},
		{
		    "name": "rst",
		    "type": "in",
		    "node": "INT_R_X21Y119/EE4BEG2",
		    "pin": "SYN9"
		}
	    ]
	}


Here we see the info section defines the boundaries of the partition region. It is important to use the prjxray grid, not the VPR grid or the Vivado grid, to define these boundaries. The ports section is then used to define the interface pins for the region. A synth IO will be placed to correspond to each of these interface pins. Each pin must contain a name, pin name, type, and node name. The name and pin name must be unique identifiers. The type can be in, out or clk. The node is the vivado node that a synth IO should be connected to.

Optionally, a wire name can be provided to give an exact location for the synth IO. If a wire is not provided it will be inferred as the first wire outside of the partition region on the given node. Providing an explicit wire name is especially important when using nodes that cross all the way through the partition region, such as clock nodes.

Now the CMake files must be defined properly for the first partition region architecture:

`xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-pr1-roi-virt/CMakeLists.txt`_

.. code-block:: RST

	add_xc_device_define_type(
	  ARCH artix7
	  DEVICE xc7a50t-arty-switch-processing-pr1
	  ROI_DIR ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-pr1-roi-virt
	  TILE_TYPES
	    CLBLL_L
	    CLBLL_R
	    CLBLM_L
	    CLBLM_R
	    BRAM_L
	  PB_TYPES
	    SLICEL
	    SLICEM
	    BRAM_L
	)


The important argument here is ``ROI_DIR`` which points to the directory containing the ``design.json`` defined earlier.

Next, define the second partition region in a similar way as the first:

`xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-pr2-roi-virt/design.json`_

.. code-block:: javascript

	{
	    "info":
		{
		"name": "pr2",
		"GRID_X_MAX": 57,
		"GRID_X_MIN": 10,
		"GRID_Y_MAX": 156,
		"GRID_Y_MIN": 105
		},
	    "ports": [
		{
		    "name": "clk",
		    "type": "clk",
		    "node": "CLK_HROW_BOT_R_X60Y26/CLK_HROW_CK_BUFHCLK_L8",
		    "wire": "HCLK_CLB_X56Y26/HCLK_CLB_CK_BUFHCLK8",
		    "pin": "SYN0"
		},
		{
		    "name": "in[0]",
		    "type": "in",
		    "node": "INT_L_X20Y51/SS2BEG0",
		    "pin": "SYN1"
		},
		{
		    "name": "in[1]",
		    "type": "in",
		    "node": "INT_R_X1Y34/EE4BEG3",
		    "pin": "SYN2"
		},
		{
		    "name": "in[2]",
		    "type": "in",
		    "node": "INT_L_X0Y47/EE4BEG3",
		    "pin": "SYN3"
		},
		{
		    "name": "in[3]",
		    "type": "in",
		    "node": "INT_L_X0Y39/EE4BEG1",
		    "pin": "SYN4"
		},
		{
		    "name": "out[0]",
		    "type": "out",
		    "node": "INT_L_X20Y49/ER1BEG_S0",
		    "pin": "SYN5"
		},
		{
		    "name": "out[1]",
		    "type": "out",
		    "node": "INT_R_X3Y34/WW4BEG2",
		    "pin": "SYN6"
		},
		{
		    "name": "out[2]",
		    "type": "out",
		    "node": "INT_L_X2Y33/WW2BEG2",
		    "pin": "SYN7"
		},
		{
		    "name": "out[3]",
		    "type": "out",
		    "node": "INT_L_X4Y30/WW4BEG2",
		    "pin": "SYN8"
		},
		{
		    "name": "rst",
		    "type": "in",
		    "node": "INT_R_X23Y46/WW4BEG3",
		    "pin": "SYN9"
		}
	    ]
	}


`xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-pr2-roi-virt/CMakeLists.txt`_

.. code-block:: RST

	add_xc_device_define_type(
	  ARCH artix7
	  DEVICE xc7a50t-arty-switch-processing-pr1
	  ROI_DIR ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-pr1-roi-virt
	  TILE_TYPES
	    CLBLL_L
	    CLBLL_R
	    CLBLM_L
	    CLBLM_R
	    BRAM_L
	  PB_TYPES
	    SLICEL
	    SLICEM
	    BRAM_L
	)


.. _xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-pr1-roi-virt/design.json: https://github.com/SymbiFlow/symbiflow-arch-defs/blob/master/xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-pr1-roi-virt/design.json
.. _xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-pr1-roi-virt/CMakeLists.txt: https://github.com/SymbiFlow/symbiflow-arch-defs/blob/master/xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-pr1-roi-virt/CMakeLists.txt
.. _xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-pr2-roi-virt/design.json: https://github.com/SymbiFlow/symbiflow-arch-defs/blob/master/xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-pr2-roi-virt/design.json
.. _xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-pr2-roi-virt/CMakeLists.txt: https://github.com/SymbiFlow/symbiflow-arch-defs/blob/master/xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-pr2-roi-virt/CMakeLists.txt

The last ``design.json`` that must be defined is for the overlay. It is mostly a list of the json for the partition regions contained in the design. One important change is the pin names must still be unique across all ports in the overlay. Any explicit wires must also be changed to be on the other side of the partition region boundary.


`xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-overlay-virt/design.json`_

.. code-block:: javascript

	[
	    {
		"info":
		    {
		    "name": "pr1",
		    "GRID_X_MAX": 57,
		    "GRID_X_MIN": 10,
		    "GRID_Y_MAX": 51,
		    "GRID_Y_MIN": 0
		    },
		"ports": [
		    {
			"name": "clk",
			"type": "clk",
			"node": "CLK_HROW_TOP_R_X60Y130/CLK_HROW_CK_BUFHCLK_L0",
			"wire": "HCLK_L_X57Y130/HCLK_CK_BUFHCLK0",
			"pin": "SYN0"
		    },
		    {
			"name": "in[0]",
			"type": "in",
			"node": "INT_L_X0Y124/EE2BEG0",
			"pin": "SYN1"
		    },
		    {
			"name": "in[1]",
			"type": "in",
			"node": "INT_L_X0Y125/SE6BEG0",
			"pin": "SYN2"
		    },
		    {
			"name": "in[2]",
			"type": "in",
			"node": "INT_R_X1Y117/SE2BEG1",
			"pin": "SYN3"
		    },
		    {
			"name": "in[3]",
			"type": "in",
			"node": "INT_L_X0Y116/EE2BEG0",
			"pin": "SYN4"
		    },
		    {
			"name": "out[0]",
			"type": "out",
			"node": "INT_L_X2Y103/SE6BEG0",
			"pin": "SYN5"
		    },
		    {
			"name": "out[1]",
			"type": "out",
			"node": "INT_L_X4Y100/SE6BEG0",
			"pin": "SYN6"
		    },
		    {
			"name": "out[2]",
			"type": "out",
			"node": "INT_L_X2Y104/SS6BEG2",
			"pin": "SYN7"
		    },
		    {
			"name": "out[3]",
			"type": "out",
			"node": "INT_L_X2Y104/SS6BEG0",
			"pin": "SYN8"
		    },
		    {
			"name": "rst",
			"type": "in",
			"node": "INT_L_X0Y119/EE4BEG1",
			"pin": "SYN9"
		    }
		]
	    },
		{
		"info":
		    {
		    "name": "pr2",
		    "GRID_X_MAX": 57,
		    "GRID_X_MIN": 10,
		    "GRID_Y_MAX": 156,
		    "GRID_Y_MIN": 105
		    },
		"ports": [
		    {
			"name": "clk",
			"type": "clk",
			"node": "CLK_HROW_BOT_R_X60Y26/CLK_HROW_CK_BUFHCLK_L8",
			"wire": "HCLK_CLB_X56Y26/HCLK_CLB_CK_BUFHCLK8",
			"pin": "SYN10"
		    },
		    {
			"name": "in[0]",
			"type": "in",
			"node": "INT_L_X20Y51/SS2BEG0",
			"pin": "SYN11"
		    },
		    {
			"name": "in[1]",
			"type": "in",
			"node": "INT_R_X1Y34/EE4BEG3",
			"pin": "SYN12"
		    },
		    {
			"name": "in[2]",
			"type": "in",
			"node": "INT_L_X0Y47/EE4BEG3",
			"pin": "SYN13"
		    },
		    {
			"name": "in[3]",
			"type": "in",
			"node": "INT_L_X0Y39/EE4BEG1",
			"pin": "SYN14"
		    },
		    {
			"name": "out[0]",
			"type": "out",
			"node": "INT_L_X20Y49/ER1BEG_S0",
			"pin": "SYN15"
		    },
		    {
			"name": "out[1]",
			"type": "out",
			"node": "INT_R_X3Y34/WW4BEG2",
			"pin": "SYN16"
		    },
		    {
			"name": "out[2]",
			"type": "out",
			"node": "INT_L_X2Y33/WW2BEG2",
			"pin": "SYN17"
		    },
		    {
			"name": "out[3]",
			"type": "out",
			"node": "INT_L_X4Y30/WW4BEG2",
			"pin": "SYN18"
		    },
		    {
			"name": "rst",
			"type": "in",
			"node": "INT_R_X23Y46/WW4BEG3",
			"pin": "SYN19"
		    }
		]
	    }
	]


`xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-overlay-virt/CMakeLists.txt`_

.. code-block:: RST

	add_xc_device_define_type(
	  ARCH artix7
	  DEVICE xc7a50t-arty-switch-processing-overlay
	  OVERLAY_DIR ${symbiflow-arch-defs_SOURCE_DIR}/xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-overlay-virt
	  TILE_TYPES
	    CLBLL_L
	    CLBLL_R
	    CLBLM_L
	    CLBLM_R
	    BRAM_L
	    LIOPAD_M
	    LIOPAD_S
	    LIOPAD_SING
	    RIOPAD_M
	    RIOPAD_S
	    RIOPAD_SING
	    CLK_BUFG_BOT_R
	    CLK_BUFG_TOP_R
	    CMT_TOP_L_UPPER_T
	    CMT_TOP_R_UPPER_T
	    HCLK_IOI3
	  PB_TYPES
	    SLICEL
	    SLICEM
	    BRAM_L
	    IOPAD
	    IOPAD_M
	    IOPAD_S
	    BUFGCTRL
	    PLLE2_ADV
	    HCLK_IOI3
	)


The important argument here is ``OVERLAY_DIR`` which points to the directory containing the ``design.json`` for this overlay. Notice this ``CMakeLists.txt`` also contains more tile/pb types because it contains the real IOs.

.. _xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-overlay-virt/design.json: https://github.com/SymbiFlow/symbiflow-arch-defs/blob/master/xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-overlay-virt/design.json
.. _xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-overlay-virt/CMakeLists.txt: https://github.com/SymbiFlow/symbiflow-arch-defs/blob/master/xc/xc7/archs/artix7/devices/xc7a50t-arty-switch-processing-overlay-virt/CMakeLists.txt

Continuing on past ``design.json`` definitions, CMake needs to be informed these new architectures should be built.  This is done in another ``CMakeLists.txt`` by adding the following:

`xc/xc7/archs/artix7/devices/CMakeLists.txt`_

.. code-block:: RST

	add_xc_device_define(
	  ARCH artix7
	  PART xc7a50tfgg484-1
	  USE_ROI
	  DEVICES xc7a50t-arty-switch-processing-pr1 xc7a50t-arty-switch-processing-pr2
	)
	add_xc_device_define(
	  ARCH artix7
	  PART xc7a50tfgg484-1
	  USE_OVERLAY
	  DEVICES xc7a50t-arty-switch-processing-overlay
	)


The last step before switching over to adding a test is adding to ``boards.cmake``:

`xc/xc7/boards.cmake`_

.. code-block:: RST

	add_xc_board(
	  BOARD arty-switch-processing-pr1
	  DEVICE xc7a50t-arty-switch-processing-pr1
	  PACKAGE test
	  PROG_CMD "${OPENOCD} -f ${PRJXRAY_DIR}/utils/openocd/board-digilent-basys3.cfg -c \\\"init $<SEMICOLON> pld load 0 \${OUT_BIN} $<SEMICOLON> exit\\\""
	  PART xc7a35tcsg324-1
	)

	add_xc_board(
	  BOARD arty-switch-processing-pr2
	  DEVICE xc7a50t-arty-switch-processing-pr2
	  PACKAGE test
	  PROG_CMD "${OPENOCD} -f ${PRJXRAY_DIR}/utils/openocd/board-digilent-basys3.cfg -c \\\"init $<SEMICOLON> pld load 0 \${OUT_BIN} $<SEMICOLON> exit\\\""
	  PART xc7a35tcsg324-1
	)

	add_xc_board(
	  BOARD arty-switch-processing-overlay
	  DEVICE xc7a50t-arty-switch-processing-overlay
	  PACKAGE test
	  PROG_CMD "${OPENOCD} -f ${PRJXRAY_DIR}/utils/openocd/board-digilent-basys3.cfg -c \\\"init $<SEMICOLON> pld load 0 \${OUT_BIN} $<SEMICOLON> exit\\\""
	  PART xc7a35tcsg324-1
	)


This defines a separate board for each of the partition regions and overlay so they can be mapped to separately.

.. _xc/xc7/archs/artix7/devices/CMakeLists.txt: https://github.com/SymbiFlow/symbiflow-arch-defs/blob/master/xc/xc7/archs/artix7/devices/CMakeLists.txt
.. _xc/xc7/boards.cmake: https://github.com/SymbiFlow/symbiflow-arch-defs/blob/master/xc/xc7/boards.cmake

Now to define a test. This part of the documentation will not go in detail on how to define a new test case in symbiflow-arch-defs, but will point out items of importance for using the partial reconfiguration flow.

All of the following snippets are from `xc/xc7/tests/switch_processing/CMakeLists.txt`_

.. _xc/xc7/tests/switch_processing/CMakeLists.txt: https://github.com/SymbiFlow/symbiflow-arch-defs/blob/master/xc/xc7/tests/switch_processing/CMakeLists.txt

.. code-block:: RST
	add_file_target(FILE switch_processing_add_1.v SCANNER_TYPE verilog)
	add_fpga_target(
	  NAME switch_processing_arty_add_1_pr1
	  BOARD arty-switch-processing-pr1
	  SOURCES switch_processing_add_1.v
	  INPUT_IO_FILE ${COMMON}/arty_switch_processing_pr1.pcf
          GEN_PARTIAL_BIT
	  EXPLICIT_ADD_FILE_TARGET
	  )

	add_file_target(FILE switch_processing_blink.v SCANNER_TYPE verilog)
	add_fpga_target(
	  NAME switch_processing_arty_blink_pr2
	  BOARD arty-switch-processing-pr2
	  SOURCES switch_processing_blink.v
	  INPUT_IO_FILE ${COMMON}/arty_switch_processing_pr2.pcf
          GEN_PARTIAL_BIT
	  EXPLICIT_ADD_FILE_TARGET
	  )

	add_file_target(FILE switch_processing_identity.v SCANNER_TYPE verilog)
	add_fpga_target(
	  NAME switch_processing_arty_identity_pr1
	  BOARD arty-switch-processing-pr1
	  SOURCES switch_processing_identity.v
	  INPUT_IO_FILE ${COMMON}/arty_switch_processing_pr1.pcf
          GEN_PARTIAL_BIT
	  EXPLICIT_ADD_FILE_TARGET
	  )

	add_fpga_target(
	  NAME switch_processing_arty_identity_pr2
	  BOARD arty-switch-processing-pr2
	  SOURCES switch_processing_identity.v
	  INPUT_IO_FILE ${COMMON}/arty_switch_processing_pr2.pcf
          GEN_PARTIAL_BIT
	  EXPLICIT_ADD_FILE_TARGET
	  )

Here the add_1 and blink modules are mapped to pr1 and pr2 respectively. The identity function is then also mapped to each partition region. Please note that in order to generate a partial bitstream for each fpga_target the ``GEN_PARTIAL_BIT`` option must be set.

.. code-block:: RST
	add_file_target(FILE switch_processing_arty_overlay.v SCANNER_TYPE verilog)
	add_fpga_target(
	  NAME switch_processing_arty_overlay
	  BOARD arty-switch-processing-overlay
	  SOURCES switch_processing_arty_overlay.v
	  INPUT_IO_FILE ${COMMON}/arty_switch_processing_overlay.pcf
	  EXPLICIT_ADD_FILE_TARGET
	  )

Here the overlay verilog is mapped to the overlay architecture. This overlay verilog connects switches to the input of the first partition region, connects the output of the first partition region to the input of the second partition region, and then connects the output of the second partition region to LEDs.

.. code-block:: RST
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

Lastly, multiple merged bitstream targets are defined. These targets will concatenate the FASM generated by each included target and produce the final bitstream. By varying which targets are included different functionality is created without having to remap any new regions after it has been done once. Just concatenate the resulting FASM and get different functionality.

The last thing to cover related to the SymbiFlow partial reconfiguration flow is synthetic ibufs and obufs required in the overlay verilog:

`switch_processing_arty_overlay.v`_

.. _switch_processing_arty_overlay.v: https://github.com/SymbiFlow/symbiflow-arch-defs/blob/master/xc/xc7/tests/switch_processing/switch_processing_arty_overlay.v

Currently the ``SYN_IBUF`` and ``SYN_OBUF`` must be explicitly defined for each top level IO that will be constrained to a synth IO. In the future this should be able to be resolved using a yosys io map pass, but currently if explicit synthetic buffers are not defined the top level IOs will be packed into a real IO. This will prevent constraining the top level IOs to the intended synthetic IO location.

The overlay pcf file can then be written to constrain real IOs to chip IOs and synthetic IOs to synthetic IOs.

Paritial bitstream generation rule set
======================================

In order to partially reconfigure an FPGA there are some rules which must be considered when creating a design:

1. It is assumed that partition regions are not intersecting and overlaping across configuration column.
   It means partition regions cannot share any of the configuration columns.

2. Inputs and outputs of the parition region should be defined as follows:

   * Each output tile must be within the ROI and a corresponding node must route the signal outside the ROI
   * Each input tile must be outside the ROI and a corresponding node must route the signal to the insides of the ROI

3. Define explicitly ``SYN_BUFs`` for inputs and outputs in an overlay design. ``SYN_BUFs`` are not needed inside the ROI design.

4. Each SYN-IO signal should be routed through an active logic (e.g. FD) if signals are set to global constant like GND.
   In case of an overlay design, signals are the ones which are connected to ``SYN_OBUF`` and vice versa for a ROI design.

5. If all above rules are met, the ``GEN_PARTIAL_BIT`` option can be safely set to an fpga_target in a cmake.

To define parition region architecture it can be done either by hand or with **artix7_partial_arch_gen** tool. It is recomended to use **artix7_partial_arch_gen** tool which generates an architecture assuming that the ROI corresponds to a one whole clock domain, which can be chosen by a user.

`utils/artix7_partial_arch_gen.py`_

Frequently Encountered Errors
=============================

+----------------------+--------------------------------------------------------------------------------------------------------------------------------------------+
| Error                | Solution                                                                                                                                   |
+----------------------+--------------------------------------------------------------------------------------------------------------------------------------------+
| SYN-IOPAD unroutable | Make sure the chosen node is driven in the correct direction for the I/O type it is being used as.                                         |
|                      | Inputs to a partition region must be driven from outside the partition region and outputs must be driven from inside the partition region. |
+----------------------+--------------------------------------------------------------------------------------------------------------------------------------------+
