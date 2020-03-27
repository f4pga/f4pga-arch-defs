import argparse
import pickle
import re
from collections import defaultdict, namedtuple
import fasm

from connections import get_name_and_hop

from pathlib import Path
from data_structs import Loc, SwitchboxPinLoc, PinDirection
from verilogmodule import VModule

from quicklogic_fasm.qlfasm import QL732BAssembler, load_quicklogic_database

Feature = namedtuple('Feature', 'loc typ signature value')
RouteEntry = namedtuple('RouteEntry', 'typ stage_id switch_id mux_id sel_id')


class Fasm2Bels(object):
    '''Class for parsing FASM file and producing BEL representation.
    '''

    class Fasm2BelsException(Exception):
        '''Exception for Fasm2Bels errors and unsupported features.
        '''

        def __init__(self, message):
            self.message = message

        def __str__(self):
            return self.message

    def __init__(self, vpr_db):
        '''Prepares required structures.

        Parameters
        ----------
        vpr_db: dict
            A dictionary containing cell_library, loc_map, vpr_tile_types,
            vpr_tile_grid, vpr_switchbox_types, vpr_switchbox_grid,
            connections, vpr_package_pinmaps
        '''
        self.cells_library = db["cells_library"]
        self.loc_map = db["loc_map"]
        self.vpr_tile_types = db["vpr_tile_types"]
        self.vpr_tile_grid  = db["vpr_tile_grid"]
        self.vpr_switchbox_types = db["vpr_switchbox_types"]
        self.vpr_switchbox_grid  = db["vpr_switchbox_grid"]
        self.connections = db["connections"]

        self.connections_by_loc =defaultdict(list)
        for connection in self.connections:
            self.connections_by_loc[connection.dst].append(connection)
            self.connections_by_loc[connection.src].append(connection)

        self.featureparsers = {
            'LOGIC': self.parse_logic_line,
            'QMUX': self.parse_logic_line,
            'GMUX': self.parse_logic_line,
            'INTERFACE': self.parse_interface_line,
            'ROUTING': self.parse_routing_line
        }

        self.routingdata = defaultdict(list)
        self.belinversions = defaultdict(lambda: defaultdict(list))
        self.interfaces = defaultdict(lambda: defaultdict(list))
        self.designconnections = defaultdict(dict)
        self.designhops = defaultdict(dict)

    def parse_logic_line(self, feature: Feature):
        belname, setting = feature.signature.split('.', 1)
        if feature.value == 1:
            # FIXME handle ZINV pins
            if 'ZINV.' in setting:
                setting = setting.replace('ZINV.', '')
            elif 'INV.' in setting:
                setting = setting.replace('INV.', '')
            self.belinversions[feature.loc][belname].append(setting)

    def parse_interface_line(self, feature: Feature):
        belname, setting = feature.signature.split('.', 1)
        if feature.value == 1:
            setting = setting.replace('ZINV.', '')
            setting = setting.replace('INV.', '')
            self.interfaces[feature.loc][belname].append(setting)

    def parse_routing_line(self, feature: Feature):
        match = re.match(
            r'^I_highway\.IM(?P<switch_id>[0-9]+)\.I_pg(?P<sel_id>[0-9]+)$',
            feature.signature)
        if match:
            typ = 'HIGHWAY'
            stage_id = 3 # FIXME: Get HIGHWAY stage id from the switchbox def
            switch_id = int(match.group('switch_id'))
            mux_id = 0
            sel_id = int(match.group('sel_id'))
        match = re.match(
                r'^I_street\.Isb(?P<stage_id>[0-9])(?P<switch_id>[0-9])\.I_M(?P<mux_id>[0-9]+)\.I_pg(?P<sel_id>[0-9]+)$',  # noqa: E501
            feature.signature)
        if match:
            typ = 'STREET'
            stage_id = int(match.group('stage_id')) - 1
            switch_id = int(match.group('switch_id')) - 1
            mux_id = int(match.group('mux_id'))
            sel_id = int(match.group('sel_id'))
        self.routingdata[feature.loc].append(RouteEntry(
            typ=typ,
            stage_id=stage_id,
            switch_id=switch_id,
            mux_id=mux_id,
            sel_id=sel_id))

    def parse_fasm_lines(self, fasmlines):
        '''Parses FASM lines.
        
        Parameters
        ----------
        fasmlines: list
            A list of FasmLine objects
        '''
    
        loctyp = re.compile(r'^X(?P<x>[0-9]+)Y(?P<y>[0-9]+)\.(?P<type>[A-Z]+)\.(?P<signature>.*)$')  # noqa: E501

        for line in fasmlines:
            if not line.set_feature:
                continue
            match = loctyp.match(line.set_feature.feature)
            if not match:
                raise self.Fasm2BelsException(f'FASM features have unsupported format:  {line.set_feature}')  # noqa: E501
            loc = Loc(
                x=int(match.group('x')),
                y=int(match.group('y')))
            typ=match.group('type')
            feature = Feature(
                loc=loc,
                typ=typ,
                signature=match.group('signature'),
                value=line.set_feature.value)
            self.featureparsers[typ](feature)

    def decode_switchbox(self, switchbox, features):
        # Group switchbox connections by destinationa
        conn_by_dst = defaultdict(set)
        for c in switchbox.connections:
            conn_by_dst[c.dst].add(c)

        # Prepare data structure
        mux_sel = {}
        for stage_id, stage in switchbox.stages.items():
            mux_sel[stage_id] = {}
            for switch_id, switch in stage.switches.items():
                mux_sel[stage_id][switch_id] = {}
                for mux_id, mux in switch.muxes.items():
                    mux_sel[stage_id][switch_id][mux_id] = None

        for feature in features:
            assert mux_sel[feature.stage_id][feature.switch_id][feature.mux_id] is None, feature  # noqa: E501
            mux_sel[feature.stage_id][feature.switch_id][feature.mux_id] = feature.sel_id  # noqa: E501

        def expand_mux(out_loc):
            """
            Expands a multiplexer output until a switchbox input is reached.
            Returns name of the input or None if not found.
            """

            # Get mux selection, If it is set to None then the mux is
            # not active
            sel = mux_sel[out_loc.stage_id][out_loc.switch_id][out_loc.mux_id]
            if sel is None:
                return None  # TODO can we return None?

            stage = switchbox.stages[out_loc.stage_id]
            switch = stage.switches[out_loc.switch_id]
            mux = switch.muxes[out_loc.mux_id]
            pin = mux.inputs[sel]

            if pin.name is not None:
                return pin.name

            inp_loc = SwitchboxPinLoc(
                stage_id=out_loc.stage_id,
                switch_id=out_loc.switch_id,
                mux_id=out_loc.mux_id,
                pin_id=sel,
                pin_direction=PinDirection.INPUT
            )

            # Expand all "upstream" muxes that connect to the selected
            # input pin
            assert inp_loc in conn_by_dst, inp_loc
            for c in conn_by_dst[inp_loc]:
                inp = expand_mux(c.src)
                if inp is not None:
                    return inp

            # Nothing found
            return None  # TODO can we return None?

        # For each output pin of a switchbox determine to which input is it
        # connected to.
        routes = {}
        for out_pin in switchbox.outputs.values():
            out_loc = out_pin.locs[0]
            routes[out_pin.name] = expand_mux(out_loc)

        return routes

    def process_switchbox(self, loc, switchbox, features):
        routes = self.decode_switchbox(switchbox, features)
        for k, v in routes.items():
            if v is not None:
                if re.match('[VH][0-9][LRBT][0-9]', k):
                    self.designhops[(loc.x, loc.y)][k] = v
                else:
                    self.designconnections[loc][k] = v

    def resolve_hops(self):
        for loc, conns in self.designconnections.items():
            for pin, source in conns.items():
                hop = get_name_and_hop(source)
                tloc = loc
                while hop[1] is not None:
                    tloc = Loc(tloc[0] + hop[1][0], tloc[1] + hop[1][1])
                    hop = get_name_and_hop(self.designhops[tloc][hop[0]])
                self.designconnections[loc][pin] = (tloc, hop[0])

    def resolve_connections(self):
        '''Resolves connections between BELs based on switchboxes.
        '''
        keys = sorted(self.routingdata.keys(), key=lambda loc: (loc.x, loc.y))
        for phy_loc in keys:
            routingfeatures = self.routingdata[phy_loc]
            # map location to VPR coordinates
            if phy_loc not in self.loc_map.fwd:
                continue
            loc = self.loc_map.fwd[phy_loc]

            if loc in self.vpr_switchbox_grid:
                typ = self.vpr_switchbox_grid[loc]
                switchbox = self.vpr_switchbox_types[typ]
                self.process_switchbox(loc, switchbox, routingfeatures)
        self.resolve_hops()

    def produce_verilog(self):
        module = VModule(
            self.vpr_tile_grid,
            self.belinversions,
            self.interfaces,
            self.designconnections)
        module.parse_bels()
        verilog = module.generate_verilog()
        return verilog

if __name__ == '__main__':
    # Parse arguments
    parser = argparse.ArgumentParser(description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument(
        "input_file",
        type=Path,
        help="Input fasm file"
    )

    parser.add_argument(
        "--vpr-db",
        type=str,
        required=True,
        help="VPR database file"
    )

    parser.add_argument(
        "--input-type",
        type=str,
        choices=['bitstream', 'fasm'],
        default='fasm',
        help="Determines whether the input is a FASM file or bitstream"
    )

    parser.add_argument(
        "--output-verilog",
        type=Path,
        required=True,
        help="Output Verilog file"
    )

    args = parser.parse_args()

    # Load data from the database
    print("Loading database...")
    with open(args.vpr_db, "rb") as fp:
        db = pickle.load(fp)
    print('Database loaded')

    f2b = Fasm2Bels(db)

    if args.input_type == 'bitstream':
        qlfasmdb = load_quicklogic_database()
        assembler = QL732BAssembler(qlfasmdb)
        assembler.read_bitstream(args.input_file)
        fasmlines = assembler.disassemble()
        fasmlines = [line for line in fasm.parse_fasm_string('\n'.join(fasmlines))]
    else:
        fasmlines = [line for line in fasm.parse_fasm_filename(args.input_file)]

    f2b.parse_fasm_lines(fasmlines)
    f2b.resolve_connections()

    verilog = f2b.produce_verilog()
    with open(args.output_verilog, 'w') as outv:
        outv.write(verilog)
