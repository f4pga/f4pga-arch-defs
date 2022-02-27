F4PGA Architecture Definitions
==============================

***Warning: This project is a work in progress and many items may be broken.***

This project contains documentation of various FPGA architectures, it is currently concentrating on;

* Lattice iCE40
* Artix 7

The aim is to include useful documentation (both human and machine readable) on the primitives and routing infrastructure for these architectures. We hope this enables growth in the open source FPGA tools space.

The project includes;

* Black box part definitions
* Verilog simulations
* Verilog To Routing architecture definitions
* Documentation for humans


Contents
--------

.. toctree::
   :maxdepth: 2

   getting-started
   development/development

.. toctree::
   :maxdepth: 2
   :caption: Bitstream Documentation

   prjxray/index

.. toctree::
   :caption: pyF4PGA Reference
   :maxdepth: 2

   f4pga/index
   f4pga/GettingStarted
   f4pga/Concepts
   f4pga/Usage
   f4pga/CommonTargetsAndVariables
   f4pga/Module
   f4pga/common/index
   f4pga/DevNotes
