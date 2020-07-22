import json
import sys


def find_top_module(design):
    """
    Looks for the top-level module in the design. Returns its name. Throws
    an exception if none was found.
    """

    for name, module in design["modules"].items():
        attrs = module["attributes"]
        if "top" in attrs and int(attrs["top"]) == 1:
            return name

    raise RuntimeError("No top-level module found in the design!")


def find_carry4_chains(design, top_module, bit_to_cells):
    cells = design["modules"][top_module]["cells"]

    used_carry4s = set()
    root_carry4s = []
    nonroot_carry4s = {}
    for cellname in cells:
        cell = cells[cellname]
        if cell["type"] != "CARRY4_VPR":
            continue
        connections = cell["connections"]

        if "CIN" in connections:
            cin_connections = connections["CIN"]
            assert len(cin_connections) == 1

            # Goto driver of CIN, should be a CARRY_COUT_PLUG.
            plug_cellname, port, bit_idx = bit_to_cells[cin_connections[0]][0]
            plug_cell = cells[plug_cellname]
            assert plug_cell["type"] == "CARRY_COUT_PLUG", plug_cellname
            assert port == "COUT"

            plug_connections = plug_cell["connections"]

            cin_connections = plug_connections["CIN"]
            assert len(cin_connections) == 1

            # Goto driver of CIN, should be a CARRY_CO_DIRECT.
            direct_cellname, port, bit_idx = bit_to_cells[cin_connections[0]
                                                          ][0]
            direct_cell = cells[direct_cellname]
            assert direct_cell["type"] == "CARRY_CO_DIRECT", direct_cellname
            assert port == "OUT"

            direct_connections = direct_cell["connections"]

            co_connections = direct_connections["CO"]
            assert len(co_connections) == 1

            nonroot_carry4s[co_connections[0]] = cellname
        else:
            used_carry4s.add(cellname)
            root_carry4s.append(cellname)

    # Walk from each root CARRY4 to each child CARRY4 module.
    chains = []
    for cellname in root_carry4s:
        chain = [cellname]

        while True:
            # Follow CO3 to the next CARRY4, if any.
            cell = cells[cellname]
            connections = cell["connections"]

            co3_connections = connections.get("CO3", None)
            if co3_connections is None:
                # No next CARRY4, stop here.
                break

            found_next_link = False
            for connection in co3_connections:
                next_cellname = nonroot_carry4s.get(connection, None)
                if next_cellname is not None:
                    cellname = next_cellname
                    used_carry4s.add(cellname)
                    chain.append(cellname)
                    found_next_link = True
                    break

            if not found_next_link:
                break

        chains.append(chain)

    # Make sure all non-root CARRY4's got used.
    for bit, cellname in nonroot_carry4s.items():
        assert cellname in used_carry4s, (bit, cellname)

    return chains


def create_bit_to_cell_map(design, top_module):
    bit_to_cells = {}

    cells = design["modules"][top_module]["cells"]

    for cellname in cells:
        cell = cells[cellname]
        port_directions = cell["port_directions"]
        for port, connections in cell["connections"].items():
            is_output = port_directions[port] == "output"
            for bit_idx, bit in enumerate(connections):

                list_of_cells = bit_to_cells.get(bit, None)
                if list_of_cells is None:
                    list_of_cells = [None]
                    bit_to_cells[bit] = list_of_cells

                if is_output:
                    # First element of list of cells is net driver.
                    assert list_of_cells[0] is None, (
                        bit, list_of_cells[0], cellname
                    )
                    list_of_cells[0] = (cellname, port, bit_idx)
                else:
                    list_of_cells.append((cellname, port, bit_idx))

    return bit_to_cells


def is_bit_used(bit_to_cells, bit):
    list_of_cells = bit_to_cells[bit]

    return len(list_of_cells) > 1


def is_bit_used_other_than_carry4_cin(design, top_module, bit, bit_to_cells):
    cells = design["modules"][top_module]["cells"]
    list_of_cells = bit_to_cells[bit]
    assert len(list_of_cells) == 2, bit

    direct_cellname, port, _ = list_of_cells[1]
    direct_cell = cells[direct_cellname]
    assert direct_cell['type'] == "CARRY_CO_DIRECT"
    assert port == "CO"

    # Follow to output
    connections = direct_cell["connections"]["OUT"]
    assert len(connections) == 1

    for cellname, port, bit_idx in bit_to_cells[connections[0]][1:]:
        cell = cells[cellname]
        if cell["type"] == "CARRY_COUT_PLUG" and port == "CIN":
            continue
        else:
            return True, direct_cellname

    return False, direct_cellname


def fixup_cin(design, top_module, bit_to_cells, co_bit, direct_cellname):
    """ Move connection from CARRY_CO_LUT.OUT -> CARRY_COUT_PLUG.CIN to
        directly to preceeding CARRY4.
    """
    cells = design["modules"][top_module]["cells"]

    direct_cell = cells[direct_cellname]
    assert direct_cell["type"] == "CARRY_CO_LUT"

    # Follow to output
    connections = direct_cell["connections"]["OUT"]
    assert len(connections) == 1

    for cellname, port, bit_idx in bit_to_cells[connections[0]][1:]:
        cell = cells[cellname]
        if cell["type"] == "CARRY_COUT_PLUG" and port == "CIN":
            assert bit_idx == 0

            cells[cellname]["connections"]["CIN"][0] = co_bit


def fixup_congested_rows(design, top_module, bit_to_cells, chain):
    cells = design["modules"][top_module]["cells"]

    O_ports = ["O0", "O1", "O2", "O3"]
    CO_ports = ["CO0", "CO1", "CO2", "CO3"]

    # Carry chain is congested if both O and CO is used at the same level.
    # CO to next element in the chain is fine.
    for chain in chain:
        cell = cells[chain]
        connections = cell["connections"]
        for o, co in zip(O_ports, CO_ports):
            o_conns = connections[o]
            assert len(o_conns) == 1
            o_bit = o_conns[0]

            co_conns = connections[co]
            assert len(co_conns) == 1
            co_bit = co_conns[0]

            is_o_used = is_bit_used(bit_to_cells, o_bit)
            is_co_used, direct_cellname = is_bit_used_other_than_carry4_cin(
                design, top_module, co_bit, bit_to_cells
            )

            if is_o_used and is_co_used:
                # Output at this row is congested.
                # Change CARRY_CO_DIRECT to CARRY_CO_LUT, but also directly
                # connected the carry chain (if any).
                direct_cell = cells[direct_cellname]
                direct_cell["type"] = "CARRY_CO_LUT"

                fixup_cin(
                    design, top_module, bit_to_cells, co_bit, direct_cellname
                )


def main():
    design = json.load(sys.stdin)
    top_module = find_top_module(design)

    bit_to_cells = create_bit_to_cell_map(design, top_module)

    for chain in find_carry4_chains(design, top_module, bit_to_cells):
        fixup_congested_rows(design, top_module, bit_to_cells, chain)

    json.dump(design, sys.stdout, indent=2)


if __name__ == "__main__":
    main()
