#!/usr/bin/env python3
"""
The way this works is as follows;

Loop over all possible "wires" and work out;

 * If the wire is an actual wire or a pin
 * A unique, descriptive name

For each wire, we then work out which channel the wire should be assigned too.
    We build up the channels as follows;

     X Channel
        Span 4 Tracks
        Empty
        Span 12 Tracks
        Empty
        Global Tracks

     Y Channel
        Empty
        Local Tracks
        Empty
        Neighbour Tracks
        Empty
        Span 4 Tracks
        Empty
        Span 12 Tracks
        Empty
        Global Tracks

We use the Y channels for the Local + Neighbour track because we have cells
which are multiple tiles wide in the Y direction.

For each wire, we work out the "edges" (IE connection to other wires / pins).

Naming (ie track names)
http://www.clifford.at/icestorm/logic_tile.html
"Note: the Lattice tools use a different normalization scheme for this wire names."
This doc: https://docs.google.com/document/d/1kTehDgse8GA2af5HoQ9Ntr41uNL_NJ43CjA32DofK8E/edit#
I think is based on CW's naming but has some divergences

Some terminology clarification:
-A VPR "track" is a specific net that can be connected to in the global fabric

-Icestorm docs primarily talk about "wires" which generally refer to a concept
 how how these nets are used per tile

That is, we take the Icestorm tile wire pattern and convert it to VPR tracks

Other resources:
http://hedmen.org/icestorm-doc/icestorm.html


mithro MVP proposal: spans and locals only
Then add globals, then neighbourhood
"""

import sys
import os

from collections import namedtuple, OrderedDict
import os
import re

import lxml.etree as ET

from lib.collections_extra import CompassDir
from lib.rr_graph import Position, single_element

import lib.rr_graph.channel as channel
import lib.rr_graph.graph as graph

edges = [CompassDir.NN, CompassDir.EE, CompassDir.SS, CompassDir.WW]

_Track = namedtuple("Track", ("name", "type", "aliases"))


class Track(_Track):
    def __str__(self):
        return self.name


if True:
    # yapf: disable
    # pylint: disable=line-too-long,bad-whitespace
    #------------------------------
    plb_tracks = []
    plb_tracks.extend([
        Track(name="glb2local[%s]" % i, type="glb2local", aliases=())
        for i in [0, 1, 2, 3]
    ])
    plb_tracks.extend([
        # Span 4 Vertical
        Track(name="sp04_v[00]", type="span4", aliases=(               "sp4_v_b[1]",  )),
        Track(name="sp04_v[01]", type="span4", aliases=(               "sp4_v_b[0]",  )),
        Track(name="sp04_v[02]", type="span4", aliases=(               "sp4_v_b[3]",  )),
        Track(name="sp04_v[03]", type="span4", aliases=(               "sp4_v_b[2]",  )),
        Track(name="sp04_v[04]", type="span4", aliases=(               "sp4_v_b[5]",  )),
        Track(name="sp04_v[05]", type="span4", aliases=(               "sp4_v_b[4]",  )),
        Track(name="sp04_v[06]", type="span4", aliases=(               "sp4_v_b[7]",  )),
        Track(name="sp04_v[07]", type="span4", aliases=(               "sp4_v_b[6]",  )),
        Track(name="sp04_v[08]", type="span4", aliases=(               "sp4_v_b[9]",  )),
        Track(name="sp04_v[09]", type="span4", aliases=(               "sp4_v_b[8]",  )),
        Track(name="sp04_v[10]", type="span4", aliases=(               "sp4_v_b[11]", )),
        Track(name="sp04_v[11]", type="span4", aliases=(               "sp4_v_b[10]", )),
        Track(name="sp04_v[12]", type="span4", aliases=("sp4_v_t[0]",  "sp4_v_b[13]", )),
        Track(name="sp04_v[13]", type="span4", aliases=("sp4_v_t[1]",  "sp4_v_b[12]", )),
        Track(name="sp04_v[14]", type="span4", aliases=("sp4_v_t[2]",  "sp4_v_b[15]", )),
        Track(name="sp04_v[15]", type="span4", aliases=("sp4_v_t[3]",  "sp4_v_b[14]", )),
        Track(name="sp04_v[16]", type="span4", aliases=("sp4_v_t[4]",  "sp4_v_b[17]", )),
        Track(name="sp04_v[17]", type="span4", aliases=("sp4_v_t[5]",  "sp4_v_b[16]", )),
        Track(name="sp04_v[18]", type="span4", aliases=("sp4_v_t[6]",  "sp4_v_b[19]", )),
        Track(name="sp04_v[19]", type="span4", aliases=("sp4_v_t[7]",  "sp4_v_b[18]", )),
        Track(name="sp04_v[20]", type="span4", aliases=("sp4_v_t[8]",  "sp4_v_b[21]", )),
        Track(name="sp04_v[21]", type="span4", aliases=("sp4_v_t[9]",  "sp4_v_b[20]", )),
        Track(name="sp04_v[22]", type="span4", aliases=("sp4_v_t[10]", "sp4_v_b[23]", )),
        Track(name="sp04_v[23]", type="span4", aliases=("sp4_v_t[11]", "sp4_v_b[22]", )),
        Track(name="sp04_v[24]", type="span4", aliases=("sp4_v_t[12]", "sp4_v_b[25]", )),
        Track(name="sp04_v[25]", type="span4", aliases=("sp4_v_t[13]", "sp4_v_b[24]", )),
        Track(name="sp04_v[26]", type="span4", aliases=("sp4_v_t[14]", "sp4_v_b[27]", )),
        Track(name="sp04_v[27]", type="span4", aliases=("sp4_v_t[15]", "sp4_v_b[26]", )),
        Track(name="sp04_v[28]", type="span4", aliases=("sp4_v_t[16]", "sp4_v_b[29]", )),
        Track(name="sp04_v[29]", type="span4", aliases=("sp4_v_t[17]", "sp4_v_b[28]", )),
        Track(name="sp04_v[30]", type="span4", aliases=("sp4_v_t[18]", "sp4_v_b[31]", )),
        Track(name="sp04_v[31]", type="span4", aliases=("sp4_v_t[19]", "sp4_v_b[30]", )),
        Track(name="sp04_v[32]", type="span4", aliases=("sp4_v_t[20]", "sp4_v_b[33]", )),
        Track(name="sp04_v[33]", type="span4", aliases=("sp4_v_t[21]", "sp4_v_b[32]", )),
        Track(name="sp04_v[34]", type="span4", aliases=("sp4_v_t[22]", "sp4_v_b[35]", )),
        Track(name="sp04_v[35]", type="span4", aliases=("sp4_v_t[23]", "sp4_v_b[34]", )),
        Track(name="sp04_v[36]", type="span4", aliases=("sp4_v_t[24]", "sp4_v_b[37]", )),
        Track(name="sp04_v[37]", type="span4", aliases=("sp4_v_t[25]", "sp4_v_b[36]", )),
        Track(name="sp04_v[38]", type="span4", aliases=("sp4_v_t[26]", "sp4_v_b[39]", )),
        Track(name="sp04_v[39]", type="span4", aliases=("sp4_v_t[27]", "sp4_v_b[38]", )),
        Track(name="sp04_v[40]", type="span4", aliases=("sp4_v_t[28]", "sp4_v_b[41]", )),
        Track(name="sp04_v[41]", type="span4", aliases=("sp4_v_t[29]", "sp4_v_b[40]", )),
        Track(name="sp04_v[42]", type="span4", aliases=("sp4_v_t[30]", "sp4_v_b[43]", )),
        Track(name="sp04_v[43]", type="span4", aliases=("sp4_v_t[31]", "sp4_v_b[42]", )),
        Track(name="sp04_v[44]", type="span4", aliases=("sp4_v_t[32]", "sp4_v_b[45]", )),
        Track(name="sp04_v[45]", type="span4", aliases=("sp4_v_t[33]", "sp4_v_b[44]", )),
        Track(name="sp04_v[46]", type="span4", aliases=("sp4_v_t[34]", "sp4_v_b[47]", )),
        Track(name="sp04_v[47]", type="span4", aliases=("sp4_v_t[35]", "sp4_v_b[46]", )),
        Track(name="sp04_v[48]", type="span4", aliases=("sp4_v_t[36]",                )),
        Track(name="sp04_v[49]", type="span4", aliases=("sp4_v_t[37]",                )),
        Track(name="sp04_v[50]", type="span4", aliases=("sp4_v_t[38]",                )),
        Track(name="sp04_v[51]", type="span4", aliases=("sp4_v_t[39]",                )),
        Track(name="sp04_v[52]", type="span4", aliases=("sp4_v_t[40]",                )),
        Track(name="sp04_v[53]", type="span4", aliases=("sp4_v_t[41]",                )),
        Track(name="sp04_v[54]", type="span4", aliases=("sp4_v_t[42]",                )),
        Track(name="sp04_v[55]", type="span4", aliases=("sp4_v_t[43]",                )),
        Track(name="sp04_v[56]", type="span4", aliases=("sp4_v_t[44]",                )),
        Track(name="sp04_v[57]", type="span4", aliases=("sp4_v_t[45]",                )),
        Track(name="sp04_v[58]", type="span4", aliases=("sp4_v_t[46]",                )),
        Track(name="sp04_v[59]", type="span4", aliases=("sp4_v_t[47]",                )),
        # Span 4 Right Vertical
        Track(name="sp04_rv[00]", type="span4", aliases=("sp4_r_v_b[0]",  )),
        Track(name="sp04_rv[01]", type="span4", aliases=("sp4_r_v_b[1]",  )),
        Track(name="sp04_rv[02]", type="span4", aliases=("sp4_r_v_b[2]",  )),
        Track(name="sp04_rv[03]", type="span4", aliases=("sp4_r_v_b[3]",  )),
        Track(name="sp04_rv[04]", type="span4", aliases=("sp4_r_v_b[4]",  )),
        Track(name="sp04_rv[05]", type="span4", aliases=("sp4_r_v_b[5]",  )),
        Track(name="sp04_rv[06]", type="span4", aliases=("sp4_r_v_b[6]",  )),
        Track(name="sp04_rv[07]", type="span4", aliases=("sp4_r_v_b[7]",  )),
        Track(name="sp04_rv[08]", type="span4", aliases=("sp4_r_v_b[8]",  )),
        Track(name="sp04_rv[09]", type="span4", aliases=("sp4_r_v_b[9]",  )),
        Track(name="sp04_rv[10]", type="span4", aliases=("sp4_r_v_b[10]", )),
        Track(name="sp04_rv[11]", type="span4", aliases=("sp4_r_v_b[11]", )),
        Track(name="sp04_rv[12]", type="span4", aliases=("sp4_r_v_b[12]", )),
        Track(name="sp04_rv[13]", type="span4", aliases=("sp4_r_v_b[13]", )),
        Track(name="sp04_rv[14]", type="span4", aliases=("sp4_r_v_b[14]", )),
        Track(name="sp04_rv[15]", type="span4", aliases=("sp4_r_v_b[15]", )),
        Track(name="sp04_rv[16]", type="span4", aliases=("sp4_r_v_b[16]", )),
        Track(name="sp04_rv[17]", type="span4", aliases=("sp4_r_v_b[17]", )),
        Track(name="sp04_rv[18]", type="span4", aliases=("sp4_r_v_b[18]", )),
        Track(name="sp04_rv[19]", type="span4", aliases=("sp4_r_v_b[19]", )),
        Track(name="sp04_rv[20]", type="span4", aliases=("sp4_r_v_b[20]", )),
        Track(name="sp04_rv[21]", type="span4", aliases=("sp4_r_v_b[21]", )),
        Track(name="sp04_rv[22]", type="span4", aliases=("sp4_r_v_b[22]", )),
        Track(name="sp04_rv[23]", type="span4", aliases=("sp4_r_v_b[23]", )),
        Track(name="sp04_rv[24]", type="span4", aliases=("sp4_r_v_b[24]", )),
        Track(name="sp04_rv[25]", type="span4", aliases=("sp4_r_v_b[25]", )),
        Track(name="sp04_rv[26]", type="span4", aliases=("sp4_r_v_b[26]", )),
        Track(name="sp04_rv[27]", type="span4", aliases=("sp4_r_v_b[27]", )),
        Track(name="sp04_rv[28]", type="span4", aliases=("sp4_r_v_b[28]", )),
        Track(name="sp04_rv[29]", type="span4", aliases=("sp4_r_v_b[29]", )),
        Track(name="sp04_rv[30]", type="span4", aliases=("sp4_r_v_b[30]", )),
        Track(name="sp04_rv[31]", type="span4", aliases=("sp4_r_v_b[31]", )),
        Track(name="sp04_rv[32]", type="span4", aliases=("sp4_r_v_b[32]", )),
        Track(name="sp04_rv[33]", type="span4", aliases=("sp4_r_v_b[33]", )),
        Track(name="sp04_rv[34]", type="span4", aliases=("sp4_r_v_b[34]", )),
        Track(name="sp04_rv[35]", type="span4", aliases=("sp4_r_v_b[35]", )),
        Track(name="sp04_rv[36]", type="span4", aliases=("sp4_r_v_b[36]", )),
        Track(name="sp04_rv[37]", type="span4", aliases=("sp4_r_v_b[37]", )),
        Track(name="sp04_rv[38]", type="span4", aliases=("sp4_r_v_b[38]", )),
        Track(name="sp04_rv[39]", type="span4", aliases=("sp4_r_v_b[39]", )),
        Track(name="sp04_rv[40]", type="span4", aliases=("sp4_r_v_b[40]", )),
        Track(name="sp04_rv[41]", type="span4", aliases=("sp4_r_v_b[41]", )),
        Track(name="sp04_rv[42]", type="span4", aliases=("sp4_r_v_b[42]", )),
        Track(name="sp04_rv[43]", type="span4", aliases=("sp4_r_v_b[43]", )),
        Track(name="sp04_rv[44]", type="span4", aliases=("sp4_r_v_b[44]", )),
        Track(name="sp04_rv[45]", type="span4", aliases=("sp4_r_v_b[45]", )),
        Track(name="sp04_rv[46]", type="span4", aliases=("sp4_r_v_b[46]", )),
        Track(name="sp04_rv[47]", type="span4", aliases=("sp4_r_v_b[47]", )),
        # Span 12 Vertical
        Track(name="sp12_v[00]", type="span12", aliases=(                "sp12_v_b[1]",  )),
        Track(name="sp12_v[01]", type="span12", aliases=(                "sp12_v_b[0]",  )),
        Track(name="sp12_v[02]", type="span12", aliases=("sp12_v_t[0]",  "sp12_v_b[3]",  )),
        Track(name="sp12_v[03]", type="span12", aliases=("sp12_v_t[1]",  "sp12_v_b[2]",  )),
        Track(name="sp12_v[04]", type="span12", aliases=("sp12_v_t[2]",  "sp12_v_b[5]",  )),
        Track(name="sp12_v[05]", type="span12", aliases=("sp12_v_t[3]",  "sp12_v_b[4]",  )),
        Track(name="sp12_v[06]", type="span12", aliases=("sp12_v_t[4]",  "sp12_v_b[7]",  )),
        Track(name="sp12_v[07]", type="span12", aliases=("sp12_v_t[5]",  "sp12_v_b[6]",  )),
        Track(name="sp12_v[08]", type="span12", aliases=("sp12_v_t[6]",  "sp12_v_b[9]",  )),
        Track(name="sp12_v[09]", type="span12", aliases=("sp12_v_t[7]",  "sp12_v_b[8]",  )),
        Track(name="sp12_v[10]", type="span12", aliases=("sp12_v_t[8]",  "sp12_v_b[11]", )),
        Track(name="sp12_v[11]", type="span12", aliases=("sp12_v_t[9]",  "sp12_v_b[10]", )),
        Track(name="sp12_v[12]", type="span12", aliases=("sp12_v_t[10]", "sp12_v_b[13]", )),
        Track(name="sp12_v[13]", type="span12", aliases=("sp12_v_t[11]", "sp12_v_b[12]", )),
        Track(name="sp12_v[14]", type="span12", aliases=("sp12_v_t[12]", "sp12_v_b[15]", )),
        Track(name="sp12_v[15]", type="span12", aliases=("sp12_v_t[13]", "sp12_v_b[14]", )),
        Track(name="sp12_v[16]", type="span12", aliases=("sp12_v_t[14]", "sp12_v_b[17]", )),
        Track(name="sp12_v[17]", type="span12", aliases=("sp12_v_t[15]", "sp12_v_b[16]", )),
        Track(name="sp12_v[18]", type="span12", aliases=("sp12_v_t[16]", "sp12_v_b[19]", )),
        Track(name="sp12_v[19]", type="span12", aliases=("sp12_v_t[17]", "sp12_v_b[18]", )),
        Track(name="sp12_v[20]", type="span12", aliases=("sp12_v_t[18]", "sp12_v_b[21]", )),
        Track(name="sp12_v[21]", type="span12", aliases=("sp12_v_t[19]", "sp12_v_b[20]", )),
        Track(name="sp12_v[22]", type="span12", aliases=("sp12_v_t[20]", "sp12_v_b[23]", )),
        Track(name="sp12_v[23]", type="span12", aliases=("sp12_v_t[21]", "sp12_v_b[22]", )),
        Track(name="sp12_v[24]", type="span12", aliases=("sp12_v_t[22]",                 )),
        Track(name="sp12_v[25]", type="span12", aliases=("sp12_v_t[23]",                 )),
        # Span 4 Horizontal
        Track(name="sp04_h[00]", type="span4", aliases=(               "sp4_h_r[1]",  )),
        Track(name="sp04_h[01]", type="span4", aliases=(               "sp4_h_r[0]",  )),
        Track(name="sp04_h[02]", type="span4", aliases=(               "sp4_h_r[3]",  )),
        Track(name="sp04_h[03]", type="span4", aliases=(               "sp4_h_r[2]",  )),
        Track(name="sp04_h[04]", type="span4", aliases=(               "sp4_h_r[5]",  )),
        Track(name="sp04_h[05]", type="span4", aliases=(               "sp4_h_r[4]",  )),
        Track(name="sp04_h[06]", type="span4", aliases=(               "sp4_h_r[7]",  )),
        Track(name="sp04_h[07]", type="span4", aliases=(               "sp4_h_r[6]",  )),
        Track(name="sp04_h[08]", type="span4", aliases=(               "sp4_h_r[9]",  )),
        Track(name="sp04_h[09]", type="span4", aliases=(               "sp4_h_r[8]",  )),
        Track(name="sp04_h[10]", type="span4", aliases=(               "sp4_h_r[11]", )),
        Track(name="sp04_h[11]", type="span4", aliases=(               "sp4_h_r[10]", )),
        Track(name="sp04_h[12]", type="span4", aliases=("sp4_h_l[0]",  "sp4_h_r[13]", )),
        Track(name="sp04_h[13]", type="span4", aliases=("sp4_h_l[1]",  "sp4_h_r[12]", )),
        Track(name="sp04_h[14]", type="span4", aliases=("sp4_h_l[2]",  "sp4_h_r[15]", )),
        Track(name="sp04_h[15]", type="span4", aliases=("sp4_h_l[3]",  "sp4_h_r[14]", )),
        Track(name="sp04_h[16]", type="span4", aliases=("sp4_h_l[4]",  "sp4_h_r[17]", )),
        Track(name="sp04_h[17]", type="span4", aliases=("sp4_h_l[5]",  "sp4_h_r[16]", )),
        Track(name="sp04_h[18]", type="span4", aliases=("sp4_h_l[6]",  "sp4_h_r[19]", )),
        Track(name="sp04_h[19]", type="span4", aliases=("sp4_h_l[7]",  "sp4_h_r[18]", )),
        Track(name="sp04_h[20]", type="span4", aliases=("sp4_h_l[8]",  "sp4_h_r[21]", )),
        Track(name="sp04_h[21]", type="span4", aliases=("sp4_h_l[9]",  "sp4_h_r[20]", )),
        Track(name="sp04_h[22]", type="span4", aliases=("sp4_h_l[10]", "sp4_h_r[23]", )),
        Track(name="sp04_h[23]", type="span4", aliases=("sp4_h_l[11]", "sp4_h_r[22]", )),
        Track(name="sp04_h[24]", type="span4", aliases=("sp4_h_l[12]", "sp4_h_r[25]", )),
        Track(name="sp04_h[25]", type="span4", aliases=("sp4_h_l[13]", "sp4_h_r[24]", )),
        Track(name="sp04_h[26]", type="span4", aliases=("sp4_h_l[14]", "sp4_h_r[27]", )),
        Track(name="sp04_h[27]", type="span4", aliases=("sp4_h_l[15]", "sp4_h_r[26]", )),
        Track(name="sp04_h[28]", type="span4", aliases=("sp4_h_l[16]", "sp4_h_r[29]", )),
        Track(name="sp04_h[29]", type="span4", aliases=("sp4_h_l[17]", "sp4_h_r[28]", )),
        Track(name="sp04_h[30]", type="span4", aliases=("sp4_h_l[18]", "sp4_h_r[31]", )),
        Track(name="sp04_h[31]", type="span4", aliases=("sp4_h_l[19]", "sp4_h_r[30]", )),
        Track(name="sp04_h[32]", type="span4", aliases=("sp4_h_l[20]", "sp4_h_r[33]", )),
        Track(name="sp04_h[33]", type="span4", aliases=("sp4_h_l[21]", "sp4_h_r[32]", )),
        Track(name="sp04_h[34]", type="span4", aliases=("sp4_h_l[22]", "sp4_h_r[35]", )),
        Track(name="sp04_h[35]", type="span4", aliases=("sp4_h_l[23]", "sp4_h_r[34]", )),
        Track(name="sp04_h[36]", type="span4", aliases=("sp4_h_l[24]", "sp4_h_r[37]", )),
        Track(name="sp04_h[37]", type="span4", aliases=("sp4_h_l[25]", "sp4_h_r[36]", )),
        Track(name="sp04_h[38]", type="span4", aliases=("sp4_h_l[26]", "sp4_h_r[39]", )),
        Track(name="sp04_h[39]", type="span4", aliases=("sp4_h_l[27]", "sp4_h_r[38]", )),
        Track(name="sp04_h[40]", type="span4", aliases=("sp4_h_l[28]", "sp4_h_r[41]", )),
        Track(name="sp04_h[41]", type="span4", aliases=("sp4_h_l[29]", "sp4_h_r[40]", )),
        Track(name="sp04_h[42]", type="span4", aliases=("sp4_h_l[30]", "sp4_h_r[43]", )),
        Track(name="sp04_h[43]", type="span4", aliases=("sp4_h_l[31]", "sp4_h_r[42]", )),
        Track(name="sp04_h[44]", type="span4", aliases=("sp4_h_l[32]", "sp4_h_r[45]", )),
        Track(name="sp04_h[45]", type="span4", aliases=("sp4_h_l[33]", "sp4_h_r[44]", )),
        Track(name="sp04_h[46]", type="span4", aliases=("sp4_h_l[34]", "sp4_h_r[47]", )),
        Track(name="sp04_h[47]", type="span4", aliases=("sp4_h_l[35]", "sp4_h_r[46]", )),
        Track(name="sp04_h[48]", type="span4", aliases=("sp4_h_l[36]",                )),
        Track(name="sp04_h[49]", type="span4", aliases=("sp4_h_l[37]",                )),
        Track(name="sp04_h[50]", type="span4", aliases=("sp4_h_l[38]",                )),
        Track(name="sp04_h[51]", type="span4", aliases=("sp4_h_l[39]",                )),
        Track(name="sp04_h[52]", type="span4", aliases=("sp4_h_l[40]",                )),
        Track(name="sp04_h[53]", type="span4", aliases=("sp4_h_l[41]",                )),
        Track(name="sp04_h[54]", type="span4", aliases=("sp4_h_l[42]",                )),
        Track(name="sp04_h[55]", type="span4", aliases=("sp4_h_l[43]",                )),
        Track(name="sp04_h[56]", type="span4", aliases=("sp4_h_l[44]",                )),
        Track(name="sp04_h[57]", type="span4", aliases=("sp4_h_l[45]",                )),
        Track(name="sp04_h[58]", type="span4", aliases=("sp4_h_l[46]",                )),
        Track(name="sp04_h[59]", type="span4", aliases=("sp4_h_l[47]",                )),
        # Span 12 Horizontal
        Track(name="sp12_h[00]", type="span12", aliases=(                "sp12_h_r[1]",  )),
        Track(name="sp12_h[01]", type="span12", aliases=(                "sp12_h_r[0]",  )),
        Track(name="sp12_h[02]", type="span12", aliases=("sp12_h_l[0]",  "sp12_h_r[3]",  )),
        Track(name="sp12_h[03]", type="span12", aliases=("sp12_h_l[1]",  "sp12_h_r[2]",  )),
        Track(name="sp12_h[04]", type="span12", aliases=("sp12_h_l[2]",  "sp12_h_r[5]",  )),
        Track(name="sp12_h[05]", type="span12", aliases=("sp12_h_l[3]",  "sp12_h_r[4]",  )),
        Track(name="sp12_h[06]", type="span12", aliases=("sp12_h_l[4]",  "sp12_h_r[7]",  )),
        Track(name="sp12_h[07]", type="span12", aliases=("sp12_h_l[5]",  "sp12_h_r[6]",  )),
        Track(name="sp12_h[08]", type="span12", aliases=("sp12_h_l[6]",  "sp12_h_r[9]",  )),
        Track(name="sp12_h[09]", type="span12", aliases=("sp12_h_l[7]",  "sp12_h_r[8]",  )),
        Track(name="sp12_h[10]", type="span12", aliases=("sp12_h_l[8]",  "sp12_h_r[11]", )),
        Track(name="sp12_h[11]", type="span12", aliases=("sp12_h_l[9]",  "sp12_h_r[10]", )),
        Track(name="sp12_h[12]", type="span12", aliases=("sp12_h_l[10]", "sp12_h_r[13]", )),
        Track(name="sp12_h[13]", type="span12", aliases=("sp12_h_l[11]", "sp12_h_r[12]", )),
        Track(name="sp12_h[14]", type="span12", aliases=("sp12_h_l[12]", "sp12_h_r[15]", )),
        Track(name="sp12_h[15]", type="span12", aliases=("sp12_h_l[13]", "sp12_h_r[14]", )),
        Track(name="sp12_h[16]", type="span12", aliases=("sp12_h_l[14]", "sp12_h_r[17]", )),
        Track(name="sp12_h[17]", type="span12", aliases=("sp12_h_l[15]", "sp12_h_r[16]", )),
        Track(name="sp12_h[18]", type="span12", aliases=("sp12_h_l[16]", "sp12_h_r[19]", )),
        Track(name="sp12_h[19]", type="span12", aliases=("sp12_h_l[17]", "sp12_h_r[18]", )),
        Track(name="sp12_h[20]", type="span12", aliases=("sp12_h_l[18]", "sp12_h_r[21]", )),
        Track(name="sp12_h[21]", type="span12", aliases=("sp12_h_l[19]", "sp12_h_r[20]", )),
        Track(name="sp12_h[22]", type="span12", aliases=("sp12_h_l[20]", "sp12_h_r[23]", )),
        Track(name="sp12_h[23]", type="span12", aliases=("sp12_h_l[21]", "sp12_h_r[22]", )),
        Track(name="sp12_h[24]", type="span12", aliases=("sp12_h_l[22]",                 )),
        Track(name="sp12_h[25]", type="span12", aliases=("sp12_h_l[23]",                 )),
    ])
    #------------------------------
    # yapf: enable

if True:
    # yapf: disable
    # pylint: disable=line-too-long,bad-whitespace
    #------------------------------

    #span4_vert_b_{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}
    #span4_vert_t_{12,13,14,15}
    io_tracks = [
        Track(name="fabout", type="local", aliases=("fabout[0]", )),
        Track(name="sp4_h[00]", type="span4", aliases=(                    "span4_horz_r[0]",  )),
        Track(name="sp4_h[01]", type="span4", aliases=(                    "span4_horz_r[1]",  )),
        Track(name="sp4_h[02]", type="span4", aliases=(                    "span4_horz_r[2]",  )),
        Track(name="sp4_h[03]", type="span4", aliases=(                    "span4_horz_r[3]",  )),
        Track(name="sp4_h[04]", type="span4", aliases=("span4_horz_l[0]",  "span4_horz_r[4]",  )),
        Track(name="sp4_h[05]", type="span4", aliases=("span4_horz_l[1]",  "span4_horz_r[5]",  )),
        Track(name="sp4_h[06]", type="span4", aliases=("span4_horz_l[2]",  "span4_horz_r[6]",  )),
        Track(name="sp4_h[07]", type="span4", aliases=("span4_horz_l[3]",  "span4_horz_r[7]",  )),
        Track(name="sp4_h[08]", type="span4", aliases=("span4_horz_l[4]",  "span4_horz_r[8]",  )),
        Track(name="sp4_h[09]", type="span4", aliases=("span4_horz_l[5]",  "span4_horz_r[9]",  )),
        Track(name="sp4_h[10]", type="span4", aliases=("span4_horz_l[6]",  "span4_horz_r[10]", )),
        Track(name="sp4_h[11]", type="span4", aliases=("span4_horz_l[7]",  "span4_horz_r[11]", )),
        Track(name="sp4_h[12]", type="span4", aliases=("span4_horz_l[8]",  "span4_horz_r[12]", )),
        Track(name="sp4_h[13]", type="span4", aliases=("span4_horz_l[9]",  "span4_horz_r[13]", )),
        Track(name="sp4_h[14]", type="span4", aliases=("span4_horz_l[10]", "span4_horz_r[14]", )),
        Track(name="sp4_h[15]", type="span4", aliases=("span4_horz_l[11]", "span4_horz_r[15]", )),
        Track(name="sp4_h[16]", type="span4", aliases=("span4_horz_l[12]",                     )),
        Track(name="sp4_h[17]", type="span4", aliases=("span4_horz_l[13]",                     )),
        Track(name="sp4_h[18]", type="span4", aliases=("span4_horz_l[14]",                     )),
        Track(name="sp4_h[19]", type="span4", aliases=("span4_horz_l[15]",                     )),
        Track(name="sp4_v[00]", type="span4", aliases=(                    "span4_vert_t[0]",  )),
        Track(name="sp4_v[01]", type="span4", aliases=(                    "span4_vert_t[1]",  )),
        Track(name="sp4_v[02]", type="span4", aliases=(                    "span4_vert_t[2]",  )),
        Track(name="sp4_v[03]", type="span4", aliases=(                    "span4_vert_t[3]",  )),
        Track(name="sp4_v[04]", type="span4", aliases=("span4_vert_b[0]",  "span4_vert_t[4]",  )),
        Track(name="sp4_v[05]", type="span4", aliases=("span4_vert_b[1]",  "span4_vert_t[5]",  )),
        Track(name="sp4_v[06]", type="span4", aliases=("span4_vert_b[2]",  "span4_vert_t[6]",  )),
        Track(name="sp4_v[07]", type="span4", aliases=("span4_vert_b[3]",  "span4_vert_t[7]",  )),
        Track(name="sp4_v[08]", type="span4", aliases=("span4_vert_b[4]",  "span4_vert_t[8]",  )),
        Track(name="sp4_v[09]", type="span4", aliases=("span4_vert_b[5]",  "span4_vert_t[9]",  )),
        Track(name="sp4_v[10]", type="span4", aliases=("span4_vert_b[6]",  "span4_vert_t[10]", )),
        Track(name="sp4_v[11]", type="span4", aliases=("span4_vert_b[7]",  "span4_vert_t[11]", )),
        Track(name="sp4_v[12]", type="span4", aliases=("span4_vert_b[8]",  "span4_vert_t[12]", )),
        Track(name="sp4_v[13]", type="span4", aliases=("span4_vert_b[9]",  "span4_vert_t[13]", )),
        Track(name="sp4_v[14]", type="span4", aliases=("span4_vert_b[10]", "span4_vert_t[14]", )),
        Track(name="sp4_v[15]", type="span4", aliases=("span4_vert_b[11]", "span4_vert_t[15]", )),
        Track(name="sp4_v[16]", type="span4", aliases=("span4_vert_b[12]",                     )),
        Track(name="sp4_v[17]", type="span4", aliases=("span4_vert_b[13]",                     )),
        Track(name="sp4_v[18]", type="span4", aliases=("span4_vert_b[14]",                     )),
        Track(name="sp4_v[19]", type="span4", aliases=("span4_vert_b[15]",                     )),
    ]

    #span4_horz_{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47}
    for i in range(0, 48):
        io_tracks.extend([
            Track(name="sp4_v_term[%02i]" % i, type="span4", aliases=("span4_vert[%s]" % i, "sp4_v_t[%s]" % i, "sp4_v_b[%s]" % i)),
            Track(name="sp4_h_term[%02i]" % i, type="span4", aliases=("span4_horz[%s]" % i, "sp4_h_l[%s]" % i, "sp4_h_r[%s]" % i)),
        ])

    #span12_horz_{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23}
    for i in range(0, 24):
        io_tracks.extend([
            Track(name="sp12_v_term[%02i]" % i, type="span12", aliases=("span12_vert[%s]" % i, "sp12_v_t[%s]" % i, "sp12_v_b[%s]" % i)),
            Track(name="sp12_h_term[%02i]" % i, type="span12", aliases=("span12_horz[%s]" % i, "sp12_h_l[%s]" % i, "sp12_h_r[%s]" % i)),
        ])

    #------------------------------
    # yapf: enable

local_names = [
    "local_g%s[%s]" % (grp, idx) for grp in range(0, 4) for idx in range(0, 8)
]
global_names = ["glb_netwk[%s]" % i for i in [0, 1, 2, 3, 4, 5, 6, 7]]

mappings = []
for edge_src, edge_dst, delta in [
    ("v_t", "v_b", CompassDir.N),
    ("h_l", "h_r", CompassDir.E),
    ("v_b", "r_v_b", CompassDir.W),
]:
    # Span 4s
    for i in range(0, 48):
        src_net = "sp4_%s[%s]" % (edge_src, i)
        dst_net = "sp4_%s[%s]" % (edge_dst, i)
        mappings.append((src_net, delta, dst_net))

    if edge_src.startswith("r_"):
        continue

    # Span 12s
    for i in range(0, 24):
        src_net = "sp12_%s[%s]" % (edge_src, i)
        dst_net = "sp12_%s[%s]" % (edge_dst, i)
        mappings.append((src_net, delta, dst_net))

for edge_src, edge_dst, delta in [
    ("t", "b", CompassDir.N),
    ("l", "r", CompassDir.E),
        # Connection around the corners..
        #("t", "r", CompassDir.NW),
        #("t", "l", CompassDir.NE),
        #("l", "b", CompassDir.NW),
        #("l", "r", CompassDir.NE),
]:

    # IO Span 4s
    for i in range(0, 20):
        src_net = "sp4_io_%s[%s]" % (edge_src, i)
        dst_net = "sp4_io_%s[%s]" % (edge_dst, i)
        mappings.append((src_net, delta, dst_net))

mappings.append(("FCOUT[0]", CompassDir.N, "FCIN[0]"))


def segment_type(g, d):
    if d.type == 'span4':
        s_type = g.segments["span4"]
    elif d.type == 'span12':
        s_type = g.segments["span12"]
    elif d.type == 'glb2local':
        s_type = g.segments["glb2local"]
    elif d.type == 'global':
        s_type = g.segments["local"]
    elif d.type == 'local':
        s_type = g.segments["local"]
    else:
        assert False, "segment_type " + d.name

    if d.type in ("local", "global", "glb2local"):
        d_type = channel.Track.Type.Y
    elif '_h' in d.name:
        d_type = channel.Track.Type.X
    elif '_v' in d.name or '_rv' in d.name:
        d_type = channel.Track.Type.Y
    else:
        #d_type = channel.Track.Type.X
        assert False, "dir " + d.name

    return s_type, d_type


def edges_for(d):
    bits = [
        ('_v_t_', (CompassDir.N, )),
        ('_v_b_', (CompassDir.S, )),
        ('_h_l_', (CompassDir.W, )),
        ('_h_r_', (CompassDir.E, )),
        ('_horz_', (CompassDir.W, CompassDir.E)),
        ('_vert_', (CompassDir.N, CompassDir.S)),
    ]
    for b, r in bits:
        if b in d.name:
            return d.name.replace(b, ''), r


def side_for(block, pin):
    if pin.port_name == "FCOUT":
        return graph.RoutingNodeSide.TOP
    elif pin.port_name == "FCIN":
        return graph.RoutingNodeSide.BOTTOM
    return graph.RoutingNodeSide.RIGHT


def fix_name(n):
    n = re.sub("_([0-9]+)$", "[\\1]", n)
    if not n.endswith(']'):
        n = n + "[0]"
    n = n.replace("/", "_")
    return n


def icepos(pos):
    return pos.x - 1, pos.y - 1


def create_tracks(g, verbose=False):
    print("Block grid size: %s" % (g.block_grid.size, ))
    print("Channel grid size: %s" % (g.channels.size, ))

    import icebox
    ic = icebox.iceconfig()
    ic.setup_empty_384()

    #seg_timing = {'R_per_meter':420, 'C_per_meter':3.e-14}
    #segment = g.channels.create_segment('awesomesauce', timing=seg_timing)

    type_y = channel.Track.Type.Y
    type_x = channel.Track.Type.X
    bi_dir = channel.Track.Direction.BI

    short_xml = list(
        g._xml_graph.iterfind('//switches/switch/[@name="short"]')
    )[0]
    #short_xml.attrib['configurable'] = '0'
    #short_xml.attrib['buffered'] = '0'
    print("Rewrote short switch: ", ET.tostring(short_xml))

    #############################################################################
    # Internal Block wires
    #############################################################################
    segment_global = g.segments["global"]
    segment_local = g.segments["local"]

    for block in g.block_grid:
        tname = block.block_type.name

        if tname == "EMPTY":
            continue

        print("=" * 75)
        begin, end = block.position, block.position

        # Locals
        for l_n in local_names:
            track, _track_node = g.create_xy_track(
                begin, end, segment_local, typeh=type_y, direction=bi_dir
            )

            print("{} - {}".format(block, l_n))

            g.routing.localnames.add(begin, l_n, _track_node)

        for g_n in global_names:
            track, _track_node = g.create_xy_track(
                begin, end, segment_global, typeh=type_y, direction=bi_dir
            )

            print("{} - {}".format(block, g_n))

            g.routing.localnames.add(begin, g_n, _track_node)

        if tname == "PLB":
            tracks = plb_tracks
        elif tname.startswith("PIO"):
            tracks = io_tracks

        for d in tracks:
            s_type, d_type = segment_type(g, d)
            track, _track_node = g.create_xy_track(
                begin, end, s_type, typeh=d_type, direction=bi_dir
            )

            print("%s - Created track %s (%s)" % (block, d.aliases, track))

            g.routing.localnames.add(begin, d.name, _track_node)
            for alias in d.aliases:
                g.routing.localnames.add(begin, alias, _track_node)

    #############################################################################
    # Internal Block connections
    #############################################################################

    for src_block in g.block_grid:
        try:
            src_names = g.routing.localnames[src_block.position]
        except KeyError as e:
            print(src_block, e)
            continue

        print("=" * 75)

        pos = icepos(src_block.position)
        for entry in ic.tile_db(*pos):
            if not ic.tile_has_entry(*pos, entry):
                #print("{} - Skipping (tile_has_entry) {}".format(src_block, entry[1:]))
                continue
            if entry[1] not in ('buffer', 'routing'):
                #print("{} - Skipping (not buffer/routing) {}".format(src_block, entry[1:]))
                continue

            switch_type, src_name, dst_name = entry[1:]
            src_name = fix_name(src_name)
            dst_name = fix_name(dst_name)

            if src_name not in src_names:
                print(
                    "{} - Skipping (src not exist) **{}** -> {}".format(
                        src_block, src_name, dst_name
                    )
                )
                continue
            if dst_name not in src_names:
                print(
                    "{} - Skipping (dst not exist) {} -> **{}**".format(
                        src_block, src_name, dst_name
                    )
                )
                continue

            src_node = g.routing.localnames[(src_block.position, src_name)]
            dst_node = g.routing.localnames[(src_block.position, dst_name)]
            g.routing.create_edge_with_nodes(
                src_node, dst_node, g.switches[switch_type]
            )

            xml_id = graph.RoutingGraph._get_xml_id

            if entry[1] == 'routing':
                g.routing.create_edge_with_nodes(
                    dst_node, src_node, g.switches[switch_type]
                )

            dir_str = {
                'buffer': "->",
                'routing': "<->",
            }[entry[1]]

            print(
                src_block,
                src_name,
                xml_id(src_node),
                dir_str,
                dst_name,
                xml_id(dst_node),
            )

    #############################################################################
    # Block -> Block connections
    #############################################################################

    for src_block in g.block_grid:
        try:
            src_names = g.routing.localnames[src_block.position]
        except KeyError as e:
            print(src_block, e)
            continue

        for src_name, delta, dst_name in mappings:
            try:
                src_node = g.routing.localnames[(src_block.position, src_name)]
            except KeyError as e:
                print(src_name, "not found on", src_block, e)
                continue

            dst_pos = src_block.position + delta
            try:
                dst_node = g.routing.localnames[(dst_pos, dst_name)]
            except KeyError as e:
                print(
                    dst_name, "not found on block", delta, "(which is",
                    dst_pos, ")", e
                )
                continue

            dst_block = g.block_grid[dst_pos]

            print(
                "Found {}->{} on {} {} ({})".format(
                    src_name, dst_name, src_block, delta, dst_block
                )
            )
            g.routing.create_edge_with_nodes(
                src_node, dst_node, g.switches["short"]
            )
            #g.routing.create_edge_with_nodes(dst_node, src_node,
            #                                 g.switches["short"])

    #############################################################################


def patch_rr_graph(filename_in, filename_out, verbose=False):
    print('Importing input g')
    g = graph.Graph(
        rr_graph_file=filename_in,
        verbose=verbose,
        clear_fabric=True,
        sides=side_for
    )
    print('Source g loaded')
    print("Grid size: %s" % (g.block_grid.size, ))
    print()

    create_tracks(g, verbose=verbose)
    print()
    print("Completed rebuild")

    if filename_out:
        print('Writing to %s' % filename_out)
        open(filename_out, 'w').write(
            ET.tostring(g.to_xml(), pretty_print=True).decode('ascii')
        )
    else:
        print("Printing")
        print(ET.tostring(g.to_xml(), pretty_print=True).decode('ascii'))

    return g


def main():

    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--verbose", action='store_true')
    parser.add_argument("--read_rr_graph")
    parser.add_argument("--write_rr_graph", nargs='?')
    args = parser.parse_args()

    patch_rr_graph(
        args.read_rr_graph, args.write_rr_graph, verbose=args.verbose
    )


if __name__ == "__main__":
    main()
