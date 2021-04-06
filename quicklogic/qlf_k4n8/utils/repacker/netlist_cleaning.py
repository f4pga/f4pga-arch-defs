#!/usr/bin/env python3
"""
Utilities for cleaning circuit netlists
"""

import logging

# =============================================================================


def absorb_buffer_luts(netlist):
    """
    Performs downstream absorbtion of buffer LUTs. All buffer LUTs are absorbed
    except for those that drive top-level output ports not to change output
    net names.

    Returns a net map that defines the final net remapping after some nets
    got absorbed downstream.
    """

    INP_PORT = "lut_in[0]"
    OUT_PORT = "lut_out"

    def is_buffer_lut(cell):
        """
        Returns True when a cell is a buffer LUT to be absorbed.
        """

        # A pass-through LUT
        if cell.type == "$lut" and cell.init == [0, 1]:

            assert OUT_PORT in cell.ports, cell
            net_out = cell.ports[OUT_PORT]

            # Must not be driving any top-level outputs
            if net_out in netlist.outputs:
                return False

            return True

        return False

    # Identify LUT buffers
    buffers = {
        key: cell
        for key, cell in netlist.cells.items()
        if is_buffer_lut(cell)
    }

    # Merge them downstream
    net_map = {}
    for cell in buffers.values():

        # Get input and output nets
        assert INP_PORT in cell.ports, cell
        net_inp = cell.ports[INP_PORT]

        assert OUT_PORT in cell.ports, cell
        net_out = cell.ports[OUT_PORT]

        # Replace the output net in all cells with the input one
        for c in netlist.cells.values():
            for port, net in c.ports.items():
                if net == net_out:
                    c.ports[port] = net_inp

        # Update net map
        for net in net_map:
            if net_map[net] == net_out:
                net_map[net] = net_inp

        net_map[net_out] = net_inp

        # Remove the cell
        del netlist.cells[cell.name]

    logging.debug(" Absorbed {} buffer LUTs".format(len(buffers)))
    return net_map


def sweep_dangling_cells(netlist):
    # TODO:
    pass
