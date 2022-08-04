# SymbiFlow Architecture Definitions Import Functions

[![Build Status](https://travis-ci.org/SymbiFlow/symbiflow-arch-defs.svg?branch=master)](https://travis-ci.org/SymbiFlow/symbiflow-arch-defs)

This directory contains python scripts used to import the prjxray architectures to Symbiflow architecture definition repository.

The purpose of these scripts are the following:

* Create a correct XML representation of the XC7 series FPGAs.
* Create a database containing correct routing information (e.g. channels, pin assignments, etc.).

This document gives an overview of the dependencies among these scripts and their functionalities.

## Tile import

Tiles are the top level FPGA blocks that can be instantiated:

* CLB (Configurable Logic Block)
* IOB (Input Output Blcok)
* BRAM (Block RAM)
* DSP (Digital Signal Processor)
* INT (Interconnect Blocks)

They are represented by three different XML definitions:

* model.xml
* pb_type.xml
* tile.xml

`prjxray_tile_import.py` generates the `pb_type` and `model` definitions. It takes the name of the top level tile as an argument.
This script needs to be called for each different tile that has to be generated.

`prjxray_tile_type_import.py` generates the `tile` definition. It is located in a different script as it relies on the `pb_type` definitions.
In fact, each `tile` can be associated to other tiles which are defined `equivalent`. In this case, the `tile.xml` definition must include the pin mapping between the two equivalent tiles.
The pin mapping is created with the information included in the `pb_type.xml` of both the tiles, hence the `tile.xml` generation can be performed only when all the `pb_type.xml` definitions have been produced.
`pb_type.xml` are parsed to extract the pin connections of the equivalent tiles that are used to generate the pin mapping when producing `tile.xml` definitions.
