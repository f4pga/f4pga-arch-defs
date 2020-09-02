===============
Getting Started
===============

This section provides an introduction on how to get started with using the SymbiFlow toolchain.
In order to generate a bitstream (or any intermediate file format),
you can use one of the toolchain tests. Following steps describe the whole
process:

Clone repository
----------------

.. code-block:: bash

    git clone https://github.com/SymbiFlow/symbiflow-arch-defs.git

Prepare environment
-------------------

Download all needed packages and databases content
into the separated environment

.. code-block:: bash

    cd symbiflow-arch-defs
    make env

To initialize the conda environment that contains all the tools and libraries,
from the root of the ``symbiflow-arch-defs`` directory run:

.. code-block:: bash

    make all_conda

Build example
-------------

Enter the appropriate test build directory, depending on your target
architecture and invoke the appropriate make target.

Build directories depend on the architecture. Because of that,
depending on the chosen target, a different toolchain backend will be used.
(See `Project X-Ray <https://prjxray.readthedocs.io/en/latest/>`_
and `Project Trellis <https://prjtrellis.readthedocs.io/en/latest/>`_
for more information)

Moreover, it is worth to note that target names have the form <*testname_platform_outputformat*>.

Assuming that you would like to generate bitstream ``.bit`` file with
the counter example for the arty board, which uses Xilinx Artix-7 FPGA,
you will type:

.. code-block:: bash

    cd build/xc/xc7/tests/counter
    make counter_arty_bit

Load bitstream
--------------

The last step is to load the bitstream to your platform.
The final output file can be found in the appropriate test directory, i.e:
``build/xc/xc7/tests/counter/counter_arty/artix7-xc7a50t-arty-swbut-roi-virt-xc7a50t-arty-swbut-test/top.bit``

The loading proces may be different for every vendor.
For convenience a target is provided for this purpose, e.g.:

.. code-block:: bash

    make counter_arty_prog

However, this can be done with any tool of your choice, such as `Vivado` or `xc3sprog`.

Vivado
++++++

For programming the Arty Board with ``Vivado``, open the program in GUI mode
and choose the ``Open Target`` option from
``Flow Navigator \ Program and Debug \ Open Hardware Manager``. After
right-clicking on the chip icon in the newly-opened ``Hardware`` window,
you will see the ``Program Device`` option in the context menu.
The option  will open an appropriate Manager for programming the chip.
Select the location of the bitstream file and click ``Program``.

xc3sprog
++++++++

Alternatively, you can use other tools like `xc3sprog <https://github.com/matrix-io/xc3sprog>`_
which allow programming the chip directly from a console.
For Arty Board you can do it with the following command:

.. code-block:: bash

   xc3sprog -c nexys4 bitstream.bit
