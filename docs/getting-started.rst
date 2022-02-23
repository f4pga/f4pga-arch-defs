
Getting Started with F4PGA Toolchain development
################################################

.. warning::
   This documentation explains the first steps in the development of the toolchain itself.
   If you are looking for the **user documentation**, please look at :doc:`examples:index` instead.

This section provides an introduction on how to get started with the development of the F4PGA toolchain.
In order to generate a bitstream (or any intermediate file format), you can use one of the toolchain tests.
The following steps describe the whole process:

Clone repository
================

.. code-block:: bash

    git clone https://github.com/chipsalliance/f4pga-arch-defs.git

Prepare environment
===================

Download all the necessary packages, tools and databases into an isolated conda environment:

.. code-block:: bash

    cd f4pga-arch-defs
    make env

This also checks out all the submodules and generates the build system (``Make`` or ``Ninja``) from the CMake configuration.
If you want to use the ``Ninja`` build tool add this line before calling ``make env``:

.. code-block:: bash

    export CMAKE_FLAGS="-GNinja"

Build example
=============

While different architectures provide different build targets, there are some targets that should exist for all architectures.

Each architecture has its own toolchain backend that will be called during build.
(See `Project X-Ray <https://prjxray.readthedocs.io/en/latest/>`_
and `Project Trellis <https://prjtrellis.readthedocs.io/en/latest/>`_ for more information)

For development purposes a set of test designs are included for each supported architecture.
In order to perform a build of a test design with the ``Make`` build system enter the appropriate test build directory
specific to your target architecture and invoke desired make target.
Assuming that you would like to generate the bitstream ``.bit`` file with the counter example for the Arty board, which
uses Xilinx Artix-7 FPGA, you will execute the following:

.. code-block:: bash

    cd build/xc/xc7/tests/counter
    make counter_arty_bit

If you use ``Ninja`` then the target is accessible from root build directory:

.. code-block:: bash

    cd build
    ninja counter_arty_bit

.. note::

   Test design targets names are based on the following naming convention:  ``<design>_<platform>_<target_step>``, where ``<target_step>`` is the actual step to be done, e.g.: ``bit``, ``place``, ``route``, ``prog``.

.. warning::

    Generating architecture files is expected to take a long time to build, even on fast machines.

Load bitstream
==============

The last step is to load the bitstream to your platform.
The final output file can be found in the appropriate test directory, i.e:
``build/xc/xc7/tests/counter/counter_arty/artix7-xc7a50t-arty-swbut-roi-virt-xc7a50t-arty-swbut-test/top.bit``

For every board the loading process may be different and different tools will be required.
``OpenOCD`` is the most widely used tool for loading bitstream in the F4PGA Toolchain.
It is provided as a conda package during the environment setup and ``CMake`` keeps track of its executable.
Other programming tools used in F4PGA that are automatically downloaded and referenced by ``CMake`` are ``tinyfpgab``
and ``tinyprog``.

For convenience the ``prog`` targets are provided for loading the bitstream, e.g.:

.. code-block:: bash

    make counter_arty_prog

or for ``Ninja``:

.. code-block:: bash

    ninja counter_arty_prog

.. note::
    Loading the bitstream into an FPGA can be done outside of the F4PGA.
    There are multiple tools for loading bitstreams into FPGA development boards.
    Typically, each tool supports a specific target family or the lines of products of a vendor.
    Some of the most known are listed in :ref:`hdl/constraints: Programming and debugging <constraints:ProgDebug>`.

OpenFPGALoader
--------------

OpenFPGALoader is an universal utility for programming the FPGA devices that is a great alternative to OpenOCD.
It supports many different boards with FPGAs based on the architectures including xc7, ECP5, iCE40 and many more.
It can utilize a variety of the programming adapters based on JTAG, DAP interface, ORBTrace, DFU and FTDI chips.

Installing OpenFPGALoader
*************************

OpenFPGALoader is available in several packaging solutions.
It can be installed with distribution specific package managers on Arch Linux and Fedora.
There are also prebuilt packages available in `conda <https://anaconda.org/litex-hub/openfpgaloader>`__
or packages in tool :gh:`repository <trabucayre/openFPGALoader/releases>`.
OpenFPGALoader can also be built from sources.
For installation guidelines using both prebuilt packages and building from source please refer to instructions in
:gh:`readme <trabucayre/openFPGALoader/blob/master/INSTALL.md>`.

Usage
*****

For programming the FPGA use one of these commands:

.. code-block:: bash

    openFPGALoader -b <board> <bitstream>           # (e.g. arty)
    openFPGALoader -c <cable> <bitstream>           # (e.g. digilent)
    openFPGALoader -d <device> <bitstream>          # (e.g. /dev/ttyUSB0)

You can also list the supported boards, cables and fpgas:

.. code-block:: bash

    openFPGALoader --list-boards
    openFPGALoader --list-cables
    openFPGALoader --list-fpga

If you encounter any issues, please refer to the :gh:`OpenFPGALoader README <trabucayre/openFPGALoader#readme>` as it
provides more useful information on the usage of the tool.
