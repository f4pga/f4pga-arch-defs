===============
Getting Started
===============

.. note::

   If you are looking for user documentation, please look at https://github.com/SymbiFlow/symbiflow-examples instead.

This section provides an introduction on how to get started with the development of the SymbiFlow toolchain.
In order to generate a bitstream (or any intermediate file format), you can use one of the toolchain tests.
The following steps describe the whole process:

Clone repository
----------------

.. code-block:: bash

    git clone https://github.com/SymbiFlow/symbiflow-arch-defs.git

Prepare environment
-------------------

Download all the necessary packages, tools and databases into an isolated conda environment:

.. code-block:: bash

    cd symbiflow-arch-defs
    make env

This also checks out all the submodules and generates the build system (``Make`` or ``Ninja``) from the CMake configuration.
If you want to use the ``Ninja`` build tool add this line before calling ``make env``:

.. code-block:: bash

    export CMAKE_FLAGS="-GNinja"

Build example
-------------

While different architectures provide different build targets, there are some targets that should exist for all architectures.

Each architecture has its own toolchain backend that will be called during build.
(See `Project X-Ray <https://prjxray.readthedocs.io/en/latest/>`_
and `Project Trellis <https://prjtrellis.readthedocs.io/en/latest/>`_ for more information)

For development purposes a set of test designs are included for each supported architecture. In order to perform a build
of a test design with the ``Make`` build system enter the appropriate test build directory specific to your target architecture
and invoke desired make target.
Assuming that you would like to generate the bitstream ``.bit`` file with the counter example for the Arty board, which uses Xilinx Artix-7 FPGA,
you will execute the following:

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
--------------

The last step is to load the bitstream to your platform.
The final output file can be found in the appropriate test directory, i.e:
``build/xc/xc7/tests/counter/counter_arty/artix7-xc7a50t-arty-swbut-roi-virt-xc7a50t-arty-swbut-test/top.bit``

The loading process may be different for every vendor.
For convenience the ``prog`` targets are provided for this purpose, e.g.:

.. code-block:: bash

    make counter_arty_prog

or for ``Ninja``:

.. code-block:: bash

    ninja counter_arty_prog

However, this can be done with any tool of your choice, such as `Vivado` or `xc3sprog`.

Vivado
++++++

For programming the Arty Board with ``Vivado``, open the program in GUI mode and choose the ``Open Target`` option from
``Flow Navigator \ Program and Debug \ Open Hardware Manager``.
After right-clicking on the chip icon in the newly-opened ``Hardware`` window, you will see the ``Program Device`` option in the context menu.
The option  will open an appropriate Manager for programming the chip.
Select the location of the bitstream file and click ``Program``.

xc3sprog
++++++++

Alternatively, you can use other tools like `xc3sprog <https://github.com/matrix-io/xc3sprog>`_
which allow programming the chip directly from a console.
For Arty Board you can do it with the following command:

.. code-block:: bash

   xc3sprog -c nexys4 bitstream.bit
