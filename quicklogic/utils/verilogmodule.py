from collections import namedtuple, defaultdict

Element = namedtuple('Element', 'loc type name ios')
Wire = namedtuple('Wire', 'srcloc name inverted')
VerilogIO = namedtuple('VerilogIO', 'name direction')

class VModule(object):
    '''Represents a Verilog module for QLAL4S3B FASM'''

    def __init__(
        self,
        vpr_tile_grid,
        belinversions,
        interfaces,
        designconnections):

        self.vpr_tile_grid = vpr_tile_grid
        self.belinversions = belinversions
        self.interfaces = interfaces
        self.designconnections = designconnections

        self.ios = {}
        self.wires = {}
        self.elements = defaultdict(dict)

        self.last_input_id = 0
        self.last_output_id = 0

    @staticmethod
    def form_verilog_element(typ: str, name: str, parameters: dict):
        result = f'    {typ} {name} ('
        params = []
        for inpname, inp in parameters.items():
            params.append(f'.{inpname}({inp})')
        result += f',\n{" " * len(result)}'.join(sorted(params)) + ');\n'
        return result

    @staticmethod
    def get_element_name(tile):
        return f'{tile.type}_{tile.name}'

    def new_io_name(self, direction):
        # TODO add support for inout
        assert direction in ['input', 'output']
        if direction == 'output':
            name = f'out_{self.last_output_id}'
            self.last_output_id += 1
        elif direction == 'input':
            name = f'in_{self.last_input_id}'
            self.last_input_id += 1
        else:
            pass
        return name
    
    @staticmethod
    def form_element_out_name(tilename, outname):
        return f'{tilename}_{outname}'

    def get_wire(self, loc, wire, inputname):
        isoutput = self.vpr_tile_grid[loc].type == 'SYN_IO'
        if isoutput:
            inverted = False
        else:
            inverted = (inputname in
                        self.belinversions[loc][self.vpr_tile_grid[loc].type])
        wireid = Wire(wire[0], wire[1], inverted)
        if wireid in self.wires:
            return self.wires[wireid]

        uninvertedwireid = Wire(wire[0], wire[1], False)
        if uninvertedwireid in self.wires:
            wirename = self.wires[uninvertedwireid]
        else:
            srcname = self.vpr_tile_grid[wire[0]].name
            srctype = self.vpr_tile_grid[wire[0]].type
            srconame = wire[1]
            if isoutput:
                wirename = self.ios[loc].name
            else:
                wirename = f'{srcname}_{srconame}'
            if not srctype in self.elements[wire[0]]:
                self.elements[wire[0]][srctype] = Element(
                    wire[0],
                    srctype,
                    self.get_element_name(self.vpr_tile_grid[wire[0]]),
                    {srconame: wirename})
            else:
                self.elements[wire[0]][srctype].ios[srconame] = wirename
            if not isoutput:
                self.wires[uninvertedwireid] = wirename

        if not inverted:
            return wirename

        invertername = f'{wirename}_inverter'

        invwirename = f'{wirename}_inv'

        inverterios = {
            'Q': invwirename,
            'A': wirename
        }

        inverterelement = Element(wire[0], 'inv', invertername, inverterios)
        self.elements[wire[0]]['inv'] = inverterelement
        invertedwireid = Wire(wire[0], wire[1], True)
        self.wires[invertedwireid] = invwirename
        return invwirename

    def parse_bels(self):
        # TODO add support for direct input-to-output
        # first parse outputs to create wires for them
        for currloc, connections in self.designconnections.items():
            if self.vpr_tile_grid[currloc].type == 'SYN_IO':
                if 'OQI' in connections:
                    self.ios[currloc] = VerilogIO(
                        name=self.new_io_name('output'),
                        direction='output')
                    self.get_wire(currloc, connections['OQI'], 'OQI')
                # TODO parse IE/INEN, check iz

        for currloc, connections in self.designconnections.items():
            currtype = self.vpr_tile_grid[currloc].type
            if currtype == 'SYN_IO':
                continue
            currname = self.get_element_name(self.vpr_tile_grid[currloc])
            inputs = {}
            for inputname, wire in connections.items():
                if wire[1] == 'VCC':
                    inputs[inputname] = "1'b1"
                    continue
                elif wire[1] == 'GND':
                    inputs[inputname] = "1'b0"
                    continue
                srctype = self.vpr_tile_grid[wire[0]].type
                if srctype == 'SYN_IO':
                    if wire[0] not in self.ios:
                        self.ios[wire[0]] = VerilogIO(
                            name=self.new_io_name('input'),
                            direction='input')
                    # TODO handle inouts
                    assert self.ios[wire[0]].direction == 'input'
                    inputs[inputname] = self.ios[wire[0]].name
                elif srctype == 'LOGIC':
                    # FIXME handle already inverted pins
                    wirename = self.get_wire(currloc, wire, inputname)
                    inputs[inputname] = wirename
                elif srctype == 'ASSP':
                    wirename = self.get_wire(currloc, wire, inputname)
                    inputs[inputname] = wirename
                else:
                    raise Exception('Not supported cell type')
            if not currtype in self.elements[currloc]:
                self.elements[currloc][currtype] = Element(
                    currloc,
                    currtype,
                    currname,
                    inputs)
            else:
                self.elements[currloc][currtype].ios.update(inputs)

    def generate_verilog(self):
        ios = ''
        wires = ''
        elements = ''

        qlal4s3bmapping = {
            'LOGIC': 'logic_cell_macro',
            'ASSP': 'qlal4s3b_cell_macro',
            'inv' : 'inv'
        }

        if len(self.ios) > 0:
            sortedios = sorted(
                self.ios.values(), key=lambda x: (x.direction, x.name))
            ios = '\n    '
            ios += ',\n    '.join(
                [f'{x.direction} {x.name}' for x in sortedios])

        if len(self.wires) > 0:
            wires += '\n'
            for wire in self.wires.values():
                wires += f'    wire {wire};\n'

        if len(self.elements) > 0:
            for locelements in self.elements.values():
                for element in locelements.values():
                    if element.type != 'SYN_IO':
                        elements += '\n'
                        elements += self.form_verilog_element(
                            qlal4s3bmapping[element.type],
                            element.name,
                            element.ios)
                    else:
                        # FIXME add support for assign
                        pass

        verilog = (
            f'module top ({ios});\n'
            f'{wires}'
            f'{elements}'
            f'\n'
            f'endmodule'
        )
        return verilog
