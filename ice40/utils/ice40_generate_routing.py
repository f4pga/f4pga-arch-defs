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
MYDIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(MYDIR, "..", "..", "utils"))

from collections import namedtuple, OrderedDict
import os
import re

import lxml.etree as ET

from lib.asserts import assert_type
from lib.collections_extra import CompassDir
from lib.rr_graph import Offset
from lib.rr_graph import Position
from lib.rr_graph import single_element

import lib.rr_graph.channel as channel
import lib.rr_graph.graph as graph

IC = None

edges = [CompassDir.NN, CompassDir.EE, CompassDir.SS, CompassDir.WW]

_Track = namedtuple("Track", ("name", "type", "aliases"))
class Track(_Track):
    def __new__(cls, name, type, aliases):
        assert_type(aliases, (tuple, list))
        return _Track.__new__(cls, name, type, aliases)

    def __str__(self):
        return self.name

    def __repr__(self):
        return "{}({}, {})".format(
            self.type.tile(), self.name, self.aliases)

_Switch = namedtuple("Switch", ("type", "src", "dst"))
class Switch(_Switch):
    pass


if True:
    # yapf: disable
    # pylint: disable=line-too-long,bad-whitespace
    #------------------------------
    plb_tracks = []
    plb_tracks_i = []
    plb_tracks.extend([
        # Span 4 Vertical
        Track(name="sp04_v----", type="space", aliases=()),
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
    ])
    plb_tracks.extend([
        # Span 4 Right Vertical
        Track(name="sp04_rv----", type="space", aliases=()),
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
    ])
    plb_tracks.extend([
        # Span 12 Vertical
        Track(name="sp12_v----", type="space", aliases=()),
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
    ])
    plb_tracks.extend([
        # Span 4 Horizontal
        Track(name="sp04_h----", type="space", aliases=()),
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
    ])
    plb_tracks.extend([
        # Span 12 Horizontal
        Track(name="sp12_h----", type="space", aliases=()),
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
    io_tracks = []
    io_switches = []

    # Globals shared between the two IO blocks inside the tile.
    io_tracks.extend([
        Track(name="fabout", type="local", aliases=("fabout[0]",)),
        Track(name="inclk",  type="local", aliases=("io_global/inclk[0]",)),
        Track(name="outclk", type="local", aliases=("io_global/outclk[0]",)),
        Track(name="cen",    type="local", aliases=("io_global/cen[0]",)),
    ])

    io_switches.extend([
        Switch(type="clk", src="io_global/inclk[0]",  dst="[0]INCLK[0]", ),
        Switch(type="clk", src="io_global/inclk[0]",  dst="[1]INCLK[0]", ),
        Switch(type="clk", src="io_global/outclk[0]", dst="[0]OUTCLK[0]",),
        Switch(type="clk", src="io_global/outclk[0]", dst="[1]OUTCLK[0]",),
        Switch(type="cen", src="io_global/cen[0]",    dst="[0]CEN[0]",   ),
        Switch(type="cen", src="io_global/cen[0]",    dst="[1]CEN[0]",   ),
    ])

    # ------------------------------------------

    io_tracks_h = []
    # Span4's inside the IO tile
    #span4_vert_b_{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}
    #span4_vert_t_{12,13,14,15}
    io_tracks_h.extend([
        Track(name="sp4_v----", type="space", aliases=()),
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
    ])

    # Termination of the span4's from the fabric
    #span4_horz_{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47}
    io_tracks_h.extend([
        Track(name="sp4_h_term---", type="space", aliases=()),
    ])
    for i in range(0, 48):
        io_tracks_h.extend([
            Track(name="sp4_h_term[%02i]" % i, type="span4", aliases=("span4_horz[%i]" % i,)), #"span4_horz[%s]" % i, "sp4_h_l[%s]" % i, "sp4_h_r[%s]" % i)),
        ])

    # Termination of the span12's from the fabric
    #span12_horz_{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23}
    io_tracks_h.extend([
        Track(name="sp12_h_term---", type="space", aliases=()),
    ])
    for i in range(0, 24):
        io_tracks_h.extend([
            Track(name="sp12_h_term[%02i]" % i, type="span12", aliases=("span12_horz[%i]" % i,)), #"span12_horz[%s]" % i, "sp12_h_l[%s]" % i, "sp12_h_r[%s]" % i)),
        ])

    # ------------------------------------------

    io_tracks_v = []
    # Span4's inside the IO tile
    #span4_horz_r_{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}
    #span4_horz_l_{12,13,14,15}
    io_tracks_v.extend([
        Track(name="sp4_h----", type="space", aliases=()),
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
    ])

    # Termination of the span4's from the fabric
    #span4_vert_{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47}
    io_tracks_v.extend([
        Track(name="sp4_v_term---", type="space", aliases=()),
    ])
    for i in range(0, 48):
        io_tracks_v.extend([
            Track(name="sp4_v_term[%02i]" % i, type="span4", aliases=("span4_vert[%i]" % i,)), #"span4_vert[%s]" % i, "sp4_v_t[%s]" % i, "sp4_v_b[%s]" % i)),
        ])

    # Termination of the span12's from the fabric
    #span12_vert_{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23}
    io_tracks_v.extend([
        Track(name="sp12_v_term---", type="space", aliases=()),
    ])
    for i in range(0, 24):
        io_tracks_v.extend([
            Track(name="sp12_v_term[%02i]" % i, type="span12", aliases=("span12_vert[%i]" % i,)), #"span12_vert[%s]" % i, "sp12_v_t[%s]" % i, "sp12_v_b[%s]" % i)),
        ])

    #------------------------------
    # yapf: enable

io_local_names = []
io_local_names.extend([
    "local_g%s[%s]" % (grp, idx) for grp in range(0, 2) for idx in range(0, 8)
])

plb_local_names = []
plb_local_names.extend([
    "local_g%s[%s]" % (grp, idx) for grp in range(0, 4) for idx in range(0, 8)
])
plb_local_names.extend([
    "glb2local[%s]" % i for i in [0, 1, 2, 3]
])

# neighbourhood
#neigh_op
#bnl,bnr,bot,lft,rgt,tnl,tnr,top
#{0,1,2,3,4,5,6,7}
# ?? - logic_op_rgt


mappings = []
# Logic to Logic tile connections
for (tile_src, edge_src), delta, (tile_dst, edge_dst) in [
    (("PLB", "v_b"), CompassDir.S, ("PLB", "v_t")),
    (("PLB", "h_r"), CompassDir.E, ("PLB", "h_l")),
    (("RAM", "v_b"), CompassDir.S, ("RAM", "v_t")),
    # Left
    (("RAM", "h_r"), CompassDir.E, ("PLB", "h_l")),
    (("PLB", "h_r"), CompassDir.E, ("RAM", "h_l")),
    # Access to the v_b on the right
    (("PLB", "r_v_b"), CompassDir.E, ("PLB", "v_b")),
]:
    # Span 4s
    for i in range(0, 48):
        src_net = "sp4_%s[%s]" % (edge_src, i)
        dst_net = "sp4_%s[%s]" % (edge_dst, i)
        mappings.append((
            (tile_src, src_net),
            delta,
            (tile_dst, dst_net),
            "joiner",
        ))

    if edge_dst.startswith("r_"):
        continue

    # Span 12s
    for i in range(0, 24):
        src_net = "sp12_%s[%s]" % (edge_src, i)
        dst_net = "sp12_%s[%s]" % (edge_dst, i)
        mappings.append((
            (tile_src, src_net),
            delta,
            (tile_dst, dst_net),
            "joiner",
        ))

mappings.append((
    ("PLB", "FCOUT[0]"),
    CompassDir.S,
    ("PLB", "FCIN[0]"),
    "carry",
))

# Logic to IO tile connections
for (tile_src, edge_src), delta, (tile_dst, edge_dst) in [
    (("PIO", "vert"), CompassDir.N, ("PLB", "v_b")),
    (("PIO", "vert"), CompassDir.N, ("RAM", "v_b")),
    (("PIO", "horz"), CompassDir.E, ("PLB", "h_l")),
    (("PIO", "vert"), CompassDir.S, ("PLB", "v_t")),
    (("PIO", "vert"), CompassDir.S, ("RAM", "v_t")),
    (("PIO", "horz"), CompassDir.W, ("PLB", "h_r")),
]:
    # Span 4s
    for i in range(0, 48):
        src_net = "span4_%s[%i]" % (edge_src, i)
        dst_net = "sp4_%s[%i]" % (edge_dst, i)
        mappings.append((
            (tile_src, src_net),
            delta,
            (tile_dst, dst_net),
            "joiner",
        ))

    # Span 12s
    for i in range(0, 24):
        src_net = "span12_%s[%i]" % (edge_src, i)
        dst_net = "sp12_%s[%i]" % (edge_dst, i)
        mappings.append((
            (tile_src, src_net),
            delta,
            (tile_dst, dst_net),
            "joiner",
        ))

# IO to IO tile connections
for (tile_src, edge_src), delta, (tile_dst, edge_dst) in [
    (("PIO", "b"), CompassDir.S, ("PIO", "t")),
    (("PIO", "r"), CompassDir.E, ("PIO", "l")),
    # Connection around the corners..
    #("t", "r", CompassDir.NW),
    #("t", "l", CompassDir.NE),
    #("l", "b", CompassDir.NW),
    #("l", "r", CompassDir.NE),
]:

    if delta == CompassDir.S:
        d = "vert"
    elif delta == CompassDir.E:
        d = "horz"
    else:
        assert False, "Unknown delta %s" % delta

    # IO Span 4s
    for i in range(0, 16):
        src_net = "span4_%s_%s[%s]" % (d, edge_src, i)
        dst_net = "span4_%s_%s[%s]" % (d, edge_dst, i)
        mappings.append((
            (tile_src, src_net),
            delta,
            (tile_dst, dst_net),
            "joiner",
        ))

###################################################################

class PositionIcebox(graph.Position):
    def __str__(self):
        return "PI(%2s,%2s)" % self
    def __repr__(self):
        return str(self)


class PositionVPR(graph.Position):
    def __str__(self):
        return "PV(%2s,%2s)" % self
    def __repr__(self):
        return str(self)


def pos_icebox2vpr(pos):
    '''Convert icebox to VTR coordinate system by adding 1 for dummy blocks'''
    assert_type(pos, PositionIcebox)
    return PositionVPR(pos.x + 2, pos.y + 2)


def pos_vpr2icebox(pos):
    '''Convert VTR to icebox coordinate system by subtracting 1 for dummy blocks'''
    assert_type(pos, PositionVPR)
    return PositionIcebox(pos.x - 2, pos.y - 2)


def pos_icebox2vprpin(pos):
    global IC
    if pos.x == 0:
        return PositionVPR(1, pos.y+2)
    elif pos.y == 0:
        return PositionVPR(pos.x+2, 1)
    elif pos.x == IC.max_x:
        return PositionVPR(pos.x+2+1, pos.y+2)
    elif pos.y == IC.max_y:
        return PositionVPR(pos.x+2, pos.y+2+1)
    assert False, (pos, (IC.max_x, IC.max_y))

def is_corner(ic, pos):
    return pos in (
        (0, 0), (0, ic.max_y), (ic.max_x, 0), (ic.max_x, ic.max_y))

def tiles(ic):
    for x in range(ic.max_x + 1):
        for y in range(ic.max_y + 1):
            p = PositionIcebox(x, y)
            if is_corner(ic, p):
                continue
            yield p

#------------------------------

class RunOnStr:
    """Don't run function until a str() is called."""

    def __init__(self, f, *args, **kw):
        self.f = f
        self.args = args
        self.kw = kw
        self.s = None

    def __str__(self):
        if not self.s:
            self.s = self.f(*self.args, **self.kw)
        return self.s

    def __format__(self, *args, **kw):
        return str(self)


def format_node(g, node):
    if node is None:
        return "None"
    assert isinstance(node, ET._Element), node
    if node.tag == "node":
        return graph.RoutingGraphPrinter.node(node, g.block_grid)
    elif node.tag == "edge":
        return graph.RoutingGraphPrinter.edge(g.routing, node, g.block_grid)


###################################################################


def segment_type(g, d):
    if d.type == "space":
        s_type = g.segments["dummy"]
    elif d.type == 'span4':
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


def ram_pin_offset(pin):
    global IC

    ram_pins_0to8 = ["WADDR[0]", "WCLKE[0]", "WCLK[0]", "WE[0]"]
    for i in range(8):
        ram_pins_0to8.extend([
            "RDATA[{}]".format(i),
            "MASK[{}]".format(i),
            "WDATA[{}]".format(i),
        ])
    ram_pins_0to8.extend(['WADDR[{}]'.format(i) for i in range(0, 11)])

    ram_pins_8to16 = ["RCLKE[0]", "RCLK[0]", "RE[0]"]
    for i in range(8,16):
        ram_pins_8to16.extend([
            "RDATA[{}]".format(i),
            "MASK[{}]".format(i),
            "WDATA[{}]".format(i),
        ])
    ram_pins_8to16.extend(['RADDR[{}]'.format(i) for i in range(0, 11)])

    if IC.device == '384':
        assert False, "384 device doesn't have RAM!"
    elif IC.device == '1k':
        top_pins = ram_pins_8to16
        bot_pins = ram_pins_0to8
    else:
        assert IC.device in ('5k', '8k'), "{} is unknown device".format(IC.device)
        top_pins = ram_pins_0to8
        bot_pins = ram_pins_8to16

    if pin.name in top_pins:
        return Offset(0, 1)
    elif pin.name in bot_pins:
        return Offset(0, 0)
    else:
        assert False, "RAM pin {} doesn't match name expected for metadata".format(pin.name)


def get_pin_meta(block, pin):
    global IC
    grid_sz = PositionVPR(IC.max_x+1+4, IC.max_y+1+4)
    if "PIN" in block.block_type.name:
        if block.position.x == 1:
            return (graph.RoutingNodeSide.RIGHT, Offset(0, 0))
        elif block.position.y == 1:
            return (graph.RoutingNodeSide.TOP, Offset(0, 0))
        elif block.position.y == grid_sz.y-2:
            return (graph.RoutingNodeSide.BOTTOM, Offset(0, 0))
        elif block.position.x == grid_sz.x-2:
            return (graph.RoutingNodeSide.LEFT, Offset(0, 0))

    if "RAM" in block.block_type.name:
        return (graph.RoutingNodeSide.RIGHT, ram_pin_offset(pin))

    if "PIO" in block.block_type.name:
        if pin.name.startswith("O[") or pin.name.startswith("I["):
            if block.position.x == 2:
                return (graph.RoutingNodeSide.LEFT, Offset(0, 0))
            elif block.position.y == 2:
                return (graph.RoutingNodeSide.BOTTOM, Offset(0, 0))
            elif block.position.y == grid_sz.y-3:
                return (graph.RoutingNodeSide.TOP, Offset(0, 0))
            elif block.position.x == grid_sz.x-3:
                return (graph.RoutingNodeSide.RIGHT, Offset(0, 0))
        return (graph.RoutingNodeSide.RIGHT, Offset(0, 0))

    if "PLB" in block.block_type.name:
        if "FCIN" in pin.port_name:
            return (graph.RoutingNodeSide.BOTTOM, Offset(0, 0))
        elif "FCOUT" in pin.port_name:
            return (graph.RoutingNodeSide.TOP, Offset(0, 0))

        return (graph.RoutingNodeSide.RIGHT, Offset(0, 0))

    assert False, (block, pin)


# tile globals
#io_global/inclk
#lutff_global/clk
#lutff_global/s_r

#Adding pin BLK_TL-PLB(0)->lutff_0/in[0]
#  on tile (P(x=3, y=3) , P(x=3, y=3) )@   0 BLK_TL-PLB(0)->lutff_0/in[0]
#Adding pin BLK_TL-PLB(32)->lutff_global/cen[0]
#  on tile (P(x=3, y=3) , P(x=3, y=3) )@  32 BLK_TL-PLB(32)->lutff_global/cen[0]
#Adding pin BLK_TL-PIO[0](0)->D_OUT[0]
#  on tile (P(x=2, y=6) , P(x=2, y=6) )@   0 BLK_TL-PIO[0](0)->D_OUT[0]

#BLK_TL-PIO@P(x=2, y=18) - Skipping (src not exist) **io_1/D_IN[1]** -> span4_vert_b[3]
#BLK_TL-PIO@P(x=2, y=18) - Skipping (src not exist) **io_1/D_IN[1]** -> span4_vert_b[7]

#'BLK_TL-PLB.lutff_{}/in[{}]' -> 'lutff_{}/in_{}'

# Specific cells
#io_0_D_IN
#lutff_0_in
def fix_name(n, is_io=False):
    """
    >>> fix_name("io_1/D_IN_1")
    "[1]D_IN[1]"

    >>> fix_name("lutff_global/cen")
    "lutff_global/cen[0]"
    >>> fix_name("io_global/inclk")
    "io_global/inclk[0]"

    """
    n = re.sub("_([0-9]+)$", "[\\1]", n)
    if not n.endswith(']'):
        n = n + "[0]"
    n = re.sub("io_([01])/", "[\\1]", n)
    n = n.replace("ram/", "")
    return n


def add_globals(g, ic):
    glb = g.segments["global"]

    # Create the global networks
    for gn in range(0, 8):
        glb_name = "glb_netwk[{}]".format(gn)
        glb_tracks = g.connect_all(
            pos_icebox2vpr(PositionIcebox(0, 0)),
            pos_icebox2vpr(PositionIcebox(ic.max_x, ic.max_y)),
            glb_name,
            glb,
            switch=g.switches["glbshort"],
        )
        for t_node in glb_tracks:
            print("Added global track {} {}".format(glb_name, format_node(g, t_node)))

    padin_db = ic.padin_pio_db()
    iolatch_db = ic.iolatch_db()

    # Create the padin_X localname aliases for the glb_network_Y
    # FIXME: Why do these exist!?
    for gn, (gx, gy, gz) in enumerate(padin_db):
        vpos = pos_icebox2vpr(PositionIcebox(gx, gy))

        glb_netwk_node = g.routing.get_by_name("glb_netwk[{}]".format(gn), vpos)
        g.routing.localnames.add(vpos, "padin_{}".format(gz), glb_netwk_node)

    # Create the IO->global drivers which exist in some IO tiles.
    GLOBAL_BUF = "GLOBAL_BUFFER_OUTPUT"
    for gn, (gx, gy, gz) in enumerate(padin_db):
        ipos = PositionIcebox(gx, gy)
        vpos = pos_icebox2vpr(ipos)

        # Create the GLOBAL_BUFFER_OUTPUT track
        _, glb_buf_node = g.create_xy_track(
            vpos, vpos,
            segment=glb,
            typeh=channel.Track.Type.Y,
            direction=channel.Track.Direction.BI)
        glb_buf_node.set_metadata(
            "hlc_name", "io_{}/{}".format(gz, GLOBAL_BUF))
        g.routing.localnames.add(vpos, GLOBAL_BUF, glb_buf_node)

        # Short it to the PACKAGE_PIN output to the GLOBAL_BUFFER_OUT track.
        pin_name = "[{}]PACKAGE_PIN[0]".format(gz)
        pin_node = g.routing.get_by_name(pin_name, vpos)
        g.routing.create_edge_with_nodes(
            pin_node, glb_buf_node, switch=g.switches["buffer"])

        print("Global driver short  {} {:>40s}{}{:s}".format(
            vpos,
            format_node(g, pin_node)+" "+pin_name,
            " -- ",
            format_node(g, glb_buf_node)+" "+GLOBAL_BUF,
        ))

        # Create the switch to enable the GLOBAL_BUFFER_OUTPUT track to
        # drive the global network.
        glb_netwk_name = "glb_netwk[{}]".format(gn)
        glb_netwk_node = g.routing.get_by_name(glb_netwk_name, vpos)
        # FIXME: g.switches["buffer"] - Is this right?
        g.routing.create_edge_with_nodes(
            glb_buf_node, glb_netwk_node, switch=g.switches["buffer"])

        print("Global driver switch {} {:>40s}{}{:s}".format(
            vpos,
            format_node(g, glb_buf_node)+" "+GLOBAL_BUF,
            " -> ",
            format_node(g, glb_netwk_node)+" "+glb_netwk_name,
        ))

    # Work out for which tiles the fabout is directly shorted to a global
    # network.
    fabout_to_glb = {}
    for gn, (gx, gy, gz) in enumerate(padin_db):
        ipos = PositionIcebox(gx, gy)
        assert ipos not in fabout_to_glb, (ipos, fabout_to_glb)
        gn = None
        for igx, igy, ign in ic.gbufin_db():
            if ipos == (igx, igy):
                gn = ign
        assert gn is not None, (ipos, gz, gn)

        fabout_to_glb[ipos] = (gz, gn)

    # Create the fabout track. Every IO tile has a fabout track, but
    # sometimes the track is special;
    # - drives a glb_netwk_X,
    # - drives the io_global/latch for the bank
    for ipos in list(tiles(ic)):
        tile_type = ic.tile_type(*ipos)
        if tile_type != "IO":
            continue

        vpos = pos_icebox2vpr(ipos)
        fabout_node = g.routing.get_by_name("fabout", vpos)

        # Fabout drives a global network?
        if ipos in fabout_to_glb:
            gz, gn = fabout_to_glb[ipos]

            glb_netwk_name = "glb_netwk[{}]".format(gn)
            glb_netwk_node = g.routing.get_by_name(glb_netwk_name, vpos)

            g.routing.create_edge_with_nodes(
                fabout_node, glb_netwk_node, switch=g.switches["fabout"])

            print("Global driver switch {} {:>40s}{}{:s}".format(
                vpos,
                format_node(g, fabout_node)+" fabout",
                " -- ",
                format_node(g, glb_netwk_node)+" "+glb_netwk_name,
            ))

        # Fabout drives the io_global/latch?
        #if ipos in iolatch_db:
        #    g.routing.create_edge_with_nodes(
        #        fabout_node, g.routing.get_by_name("io_global/latch", vpos), short)


def generate_routing(g, verbose=False):
    global IC
    print("Block grid size: %s" % (g.block_grid.size, ))
    print("Channel grid size: %s" % (g.channels.size, ))

    #seg_timing = {'R_per_meter':420, 'C_per_meter':3.e-14}
    #segment = g.channels.create_segment('awesomesauce', timing=seg_timing)

    type_y = channel.Track.Type.Y
    type_x = channel.Track.Type.X
    bi_dir = channel.Track.Direction.BI

    glbshort = graph.Switch(
        id=g.switches.next_id(), type=graph.SwitchType.MUX, name="glbshort",
        timing=graph.SwitchTiming(R=0, Cin=0, Cout=0, Tdel=0),
        sizing=graph.SwitchSizing(mux_trans_size=0, buf_size=0),
    )
    g.add_switch(glbshort)

    # Join tracks together
    joiner = graph.Switch(
        id=g.switches.next_id(), type=graph.SwitchType.SHORT, name="joiner",
        timing=graph.SwitchTiming(R=0, Cin=0, Cout=0, Tdel=0),
        sizing=graph.SwitchSizing(mux_trans_size=0, buf_size=0),
    )
    g.add_switch(joiner)

    carry = graph.Switch(
        id=g.switches.next_id(), type=graph.SwitchType.MUX, name="carry",
        timing=graph.SwitchTiming(R=0, Cin=0, Cout=0, Tdel=0),
        sizing=graph.SwitchSizing(mux_trans_size=0, buf_size=0),
    )
    g.add_switch(carry)

    package_pin = graph.Switch(
        id=g.switches.next_id(), type=graph.SwitchType.MUX, name="package_pin",
        timing=graph.SwitchTiming(R=0, Cin=0, Cout=0, Tdel=0),
        sizing=graph.SwitchSizing(mux_trans_size=0, buf_size=0),
    )
    g.add_switch(package_pin)

    fabout = graph.Switch(
        id=g.switches.next_id(), type=graph.SwitchType.MUX, name="fabout",
        timing=graph.SwitchTiming(R=0, Cin=0, Cout=0, Tdel=0),
        sizing=graph.SwitchSizing(mux_trans_size=0, buf_size=0),
    )
    g.add_switch(fabout)

    clk = graph.Switch(
        id=g.switches.next_id(), type=graph.SwitchType.MUX, name="clk",
        timing=graph.SwitchTiming(R=0, Cin=0, Cout=0, Tdel=0),
        sizing=graph.SwitchSizing(mux_trans_size=0, buf_size=0),
    )
    g.add_switch(clk)

    cen = graph.Switch(
        id=g.switches.next_id(), type=graph.SwitchType.MUX, name="cen",
        timing=graph.SwitchTiming(R=0, Cin=0, Cout=0, Tdel=0),
        sizing=graph.SwitchSizing(mux_trans_size=0, buf_size=0),
    )
    g.add_switch(cen)

    dummy = graph.Switch(
        id=g.switches.next_id(), type=graph.SwitchType.MUX, name="dummy",
        timing=graph.SwitchTiming(R=0, Cin=0, Cout=0, Tdel=0),
        sizing=graph.SwitchSizing(mux_trans_size=0, buf_size=0),
    )
    g.add_switch(dummy)


    print("#############################################################################")
    print("# Internal Block wires")
    print("#############################################################################")
    segment_global = g.segments["global"]
    segment_dummy = g.segments["dummy"]
    segment_local = g.segments["local"]

    for block in g.block_grid:
        tname = block.block_type.name
        if tname == "EMPTY":
            continue

        for pos in block.positions:
            begin, end = pos, pos

            print("=" * 75)

            if "PLB" in tname or "RAM" in tname:
                local_names = plb_local_names
                tracks = plb_tracks
            elif "PIO" in tname:
                local_names = io_local_names
                if pos.x == 2 or pos.x == (g.block_grid.size.width-3):
                    tracks = io_tracks + io_tracks_h
                else:
                    tracks = io_tracks + io_tracks_v

            # Locals
            for l_n in local_names:
                track, track_node = g.create_xy_track(
                    begin, end, segment_local, typeh=type_y, direction=bi_dir)

                print("{} ({}) - Creating local track {} ({}) {}".format(
                    block, pos, l_n, track, format_node(g, track_node)))

                g.routing.localnames.add(begin, l_n, track_node)

            # Padding ------------------------------------------------
            g.create_xy_track(
                begin, end, segment_dummy, typeh=type_y, direction=bi_dir)
            print()
            # --------------------------------------------------------

            for d in tracks:
                s_type, d_type = segment_type(g, d)
                track, track_node = g.create_xy_track(
                    begin, end, s_type, typeh=d_type, direction=bi_dir)

                print("{} ({}) - Creating {} track {} {} ({}) {}".format(
                    block, pos, track.type, d.name, d.aliases, track,
                    format_node(g, track_node)))

                g.routing.localnames.add(begin, d.name, track_node)
                for alias in d.aliases:
                    g.routing.localnames.add(begin, alias, track_node)

            # Padding ------------------------------------------------
            g.create_xy_track(
                begin, end, segment_dummy, typeh=type_y, direction=bi_dir)
            print()
            # --------------------------------------------------------

    print("#############################################################################")
    print("# Adding global drivers")
    print("#############################################################################")
    add_globals(g, IC)
    print("#############################################################################")
    print("# Internal Block switches")
    print("#############################################################################")

    for src_block in g.block_grid:
        tname = src_block.block_type.name
        if tname == "EMPTY":
            continue

        for src_pos in src_block.positions:
            try:
                src_names = g.routing.localnames[src_pos]
            except KeyError as e:
                print(src_block, e)
                continue

            print("=" * 75)

            if "PIO" in tname:
                switches = io_switches
            else:
                switches = []

            for sw in switches:
                src_node = g.routing.localnames[(src_pos, sw.src)]
                dst_node = g.routing.localnames[(src_pos, sw.dst)]
                g.routing.create_edge_with_nodes(
                    src_node, dst_node, g.switches[sw.type])

                print("Custom Internal block switch {} {} {:>40s} {} {:s}".format(
                    src_block, src_pos,
                    format_node(g, src_node)+" "+sw.src,
                    sw.type,
                    format_node(g, dst_node)+" "+sw.dst,
                ))

            ipos = pos_vpr2icebox(PositionVPR(*src_pos))
            for entry in IC.tile_db(*ipos):
                if not IC.tile_has_entry(*ipos, entry):
                    print("{} - Skipping (icebox says tile doesn't have entry) {}".format(src_block, entry[1:]))
                    continue
                if entry[1] not in ('buffer', 'routing'):
                    print("{} - Skipping (not buffer/routing) {}".format(src_block, entry[1:]))
                    continue

                switch_type, src_name, dst_name = entry[1:]
                src_name = fix_name(src_name, "PIO" in tname)
                dst_name = fix_name(dst_name, "PIO" in tname)

                # FIXME: Ignore neighbour hood wires for now...
                if "op" in src_name or "op" in dst_name:
                    print("{} - Skipping op {} -> {}".format(
                        src_block, src_name, dst_name))
                    continue

                if src_name not in src_names:
                    print("{} - Skipping (src not exist) **{}** -> {}".format(
                        src_block, src_name, dst_name))
                    continue
                if dst_name not in src_names:
                    print("{} - Skipping (dst not exist) {} -> **{}**".format(
                        src_block, src_name, dst_name))
                    continue

                src_node = g.routing.localnames[(src_pos, src_name)]
                dst_node = g.routing.localnames[(src_pos, dst_name)]
                g.routing.create_edge_with_nodes(
                    src_node, dst_node, g.switches[switch_type])

                dir_str = {
                    'buffer':  " -> ",
                    'routing': " ~> ",
                }[entry[1]]

                print("Internal block switch {} {} {:>40s}{}{:s}".format(
                    src_block, src_pos,
                    format_node(g, src_node)+" "+src_name,
                    dir_str,
                    format_node(g, dst_node)+" "+dst_name,
                ))

    print("#############################################################################")
    print("# Block -> Block connections")
    print("#############################################################################")

    for src_block in g.block_grid:
        src_tname = src_block.block_type.name
        if src_tname == "EMPTY":
            continue

        for src_pos in src_block.positions:
            src_names = g.routing.localnames[src_pos]

            print("=" * 75)

            for (src_tt, src_name), delta, (dst_tt, dst_name), sw in mappings:
                if src_tt not in src_tname:
                    continue

                dst_pos = src_pos + delta
                dst_block = g.block_grid[dst_pos]
                dst_tname = dst_block.block_type.name
                if dst_tt not in dst_tname:
                    continue

                print("Connecting {:>55s} {} {:55s} ({})".format(
                    "{}({}):{}".format(src_block, src_pos, src_name),
                    sw,
                    "{}:{}".format(dst_name, dst_block),
                    delta),
                    end=" ")

                try:
                    src_node = g.routing.localnames[(src_pos, src_name)]
                except KeyError as e:
                    print("    {:16s} not found on src block {} {}".format(
                        src_name, src_block, e))
                    raise
                    continue

                try:
                    dst_node = g.routing.localnames[(dst_pos, dst_name)]
                except KeyError as e:
                    print("    {:16s} not found on dst block {} (which is {}) {}".format(
                        dst_name, delta, dst_block, e))
                    raise
                    continue

                g.routing.create_edge_with_nodes(
                    src_node, dst_node, g.switches[sw], bidir=sw != "carry")
                print()

    print("#############################################################################")


def patch_rr_graph(filename_in, filename_out, verbose=False):
    print('Importing input g')
    g = graph.Graph(
        rr_graph_file=filename_in,
        verbose=verbose,
        clear_fabric=True,
        switch_name='__vpr_delayless_switch__',
        pin_meta=get_pin_meta,
    )
    print("Grid size: %s" % (g.block_grid.size, ))
    print()

    print('Generating routing')
    print('='*80)
    generate_routing(g, verbose=verbose)

    print('Padding channels')
    print('='*80)
    dummy_segment = g.segments['dummy']
    g.pad_channels(dummy_segment.id)

    if filename_out:
        print('Writing to %s' % filename_out)
        open(filename_out, 'w').write(
            ET.tostring(g.to_xml(), pretty_print=True).decode('ascii'))
    else:
        print("Printing")
        print(ET.tostring(g.to_xml(), pretty_print=True).decode('ascii'))

    return g


def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--verbose", action='store_true')
    parser.add_argument('--device', help='')
    parser.add_argument("--read_rr_graph")
    parser.add_argument("--write_rr_graph", nargs='?')
    args = parser.parse_args()

    device_name = args.device.lower()[2:]

    sys.path.insert(0, os.path.join(MYDIR, "..", "..", "third_party", "icestorm", "icebox"))
    import icebox
    global IC
    IC = icebox.iceconfig()
    {
        #'t4':  IC.setup_empty_t4,
        '8k': IC.setup_empty_8k,
        '5k': IC.setup_empty_5k,
        '1k': IC.setup_empty_1k,
        '384': IC.setup_empty_384,
    }[device_name]()

    patch_rr_graph(
        args.read_rr_graph, args.write_rr_graph, verbose=args.verbose)


if __name__ == "__main__":
    main()
