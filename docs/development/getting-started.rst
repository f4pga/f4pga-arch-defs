.. _Development:GettingStarted:

Getting Started with F4PGA Toolchain development
################################################

.. IMPORTANT::
   This documentation explains the first steps in the development of the toolchain itself: generating definitions about
   the primitives and routing infrastructure of the architectures.
   If you are looking for the **user documentation**, i.e. how to generate bitstreams from HDL designs, please look at
   :doc:`f4pga:index` and :doc:`examples:index` instead.

.. WARNING::
  Generating Architecture Definition files is expected to take a long time to build, even on fast machines.
  To run the tests in this repository, please make sure these resources are available:

  * Memory: 5.5G
  * Disk space: 20G


This section provides an introduction on how to get started with the development of the F4PGA toolchain.
Each FPGA architecture has its own toolchain backend that will be called during build.
The aim of this repository is to gather the knowledge from those backends and generate useful human and machine readable
documentation to be used by tools such as yosys, vpr and/or vpr.
See `Project X-Ray <https://prjxray.readthedocs.io/en/latest/>`_
and `Project Trellis <https://prjtrellis.readthedocs.io/en/latest/>`_ for more information.

In order to generate architecture definitions, any intermediate file format or bitstreams, you can use one of the
toolchain tests in this repository.
The following steps describe the whole process:


Prepare the environment
=======================

Clone the repository:

.. sourcecode:: bash

    git clone https://github.com/chipsalliance/f4pga-arch-defs.git

Bootstrap an isolated Conda environment with all the necessary dependencies:

.. sourcecode:: bash

    cd f4pga-arch-defs
    make env

.. HINT::
  This also checks out all the submodules and generates the build system (``Make`` or ``Ninja``) from the CMake
  configuration.
  If you want to use the ``Ninja`` build tool add this line before calling ``make env``:

  .. sourcecode:: bash

      export CMAKE_FLAGS="-GNinja"


Build the tests
===============

While different architectures provide different build targets, there are some targets that should exist for all
architectures.

For development purposes a set of test designs are included for each supported architecture.
In order to perform a build of a test design with the ``Make`` build system, enter the appropriate test build directory
specific to your target architecture and invoke the desired target.

Assuming that you would like to generate the bitstream ``.bit`` file with the counter example for the Arty board, which
uses Xilinx Artix-7 FPGA, you will execute the following:

.. sourcecode:: bash

  cd build/xilinx/xc7/tests/counter
  make counter_arty_bit

If you use ``Ninja``, the target is accessible from the root of the build directory:

.. sourcecode:: bash

  cd build
  ninja counter_arty_bit

.. NOTE::
 Test design target names are based on the following naming convention: ``<design>_<platform>_<target_step>``,
 where ``<target_step>`` is the actual step to be done, e.g.: ``bit``, ``place``, ``route``, ``prog``.

There are targets to run multiple tests at once:

.. sourcecode:: bash

  # Build all demo bitstreams, targetting all architectures
  make all_demos

  # Build all Xilinx 7-series demo bitstreams
  make all_xc7

  # Build all Lattice ICE40 demo bitstreams
  make all_ice40

  # Build all QuickLogic demo bitstreams
  make all_quicklogic

Specific bitstreams can be built by specifying their target name, followed by a suffix specifying the desired output.
For example, the LUT-RAM test for the RAM64X1D primative is called `dram_test_64x1d`.
Example targets are:

.. sourcecode:: bash

  # Just run synthesis on the input Verilog
  make dram_test_64x1d_eblif

  # Complete synthesis and place and route the circuit
  make dram_test_64x1d_route

  # Create the output bitstream (including synthesis and place and route)
  make dram_test_64x1d_bin

  # Run bitstream back into Vivado for timing checks, etc.
  make dram_test_64x1d_vivado


Load the bitstreams
===================

The last step to test the whole flow is to load the bitstream to your platform.
The final output file can be found in the appropriate test directory, i.e:
``build/xilinx/xc7/tests/counter/counter_arty/artix7-xc7a50t-arty-swbut-roi-virt-xc7a50t-arty-swbut-test/top.bit``

Programming tools used in F4PGA are either provided as a conda package during the environment setup, or are automatically
downloaded and referenced by ``CMake``.

For convenience, the ``prog`` targets are provided for loading the bitstream, e.g.:

.. sourcecode:: bash

    make counter_arty_prog

or for ``Ninja``:

.. sourcecode:: bash

    ninja counter_arty_prog

Find further details about loading bitstreams in :ref:`f4pga:GettingStarted:LoadingBitstreams`.
