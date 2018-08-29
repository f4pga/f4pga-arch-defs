Verilog To Routing Notes
========================

We have to do some kind of weird things to make VPR work for real
architectures, here are some tips;

 * VPR doesn't have channels right or above tiles on the right most / left most
   edge. To get these channels, pad the left most / right most edges with EMPTY
   tiles.

 * Generally we use the [`vpr/pad`](vpr/pad) object for the **actual** `.input`
   and `.output` BLIF definitions. These are then connected to the tile which
   has internal IO logic.
