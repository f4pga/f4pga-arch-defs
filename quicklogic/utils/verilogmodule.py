import re
from collections import namedtuple, defaultdict

Element = namedtuple('Element', 'loc type name ios')
Wire = namedtuple('Wire', 'srcloc name inverted')
VerilogIO = namedtuple('VerilogIO', 'name direction ioloc')

from data_structs import PinDirection

def loc2str(loc):
    return "X" + str(loc.x) + "Y" + str(loc.y)

class VModule(object):
    '''Represents a Verilog module for QLAL4S3B FASM'''

    def __init__(
            self,
            vpr_tile_grid,
            vpr_tile_types,
            cells_library,
            pcf_data,
            belinversions,
            interfaces,
            designconnections,
            inversionpins,
            io_to_fbio,
            useinversionpins=True
    ):
        '''Prepares initial structures.

        Refer to fasm2bels.py for input description.
        '''

        self.vpr_tile_grid = vpr_tile_grid
        self.vpr_tile_types = vpr_tile_types
        self.cells_library = cells_library
        self.pcf_data = pcf_data
        self.belinversions = belinversions
        self.interfaces = interfaces
        self.designconnections = designconnections
        self.inversionpins = inversionpins
        self.useinversionpins = useinversionpins
        self.io_to_fbio = io_to_fbio

        # dictionary holding inputs, outputs
        self.ios = {}
        # dictionary holding declared wires (wire value;)
        self.wires = {}
        # dictionary holding Verilog elements
        self.elements = defaultdict(dict)
        # dictionary holding assigns (assign key = value;)
        self.assigns = {}

        # helper representing last input id
        self.last_input_id = 0
        # helper representing last output id
        self.last_output_id = 0

        self.qlal4s3bmapping = {
            'LOGIC': 'logic_cell_macro',
            'ASSP': 'qlal4s3b_cell_macro',
            'BIDIR': 'gpio_cell_macro',
            'RAM' : 'ram8k_2x1_cell_macro',
            'MULT' : 'qlal4s3_mult_cell_macro',
            'inv': 'inv'
        }

    def group_vector_signals(self, signals, io = False):

        # IOs beside name, have also direction, convert them to format
        # we can process
        if io:
            orig_ios = signals
            ios = dict()
            for s in signals:
                id = Wire(s.name, 'io', False)
                ios[id] = s.name
            signals = ios

        vectors = dict()
        new_signals = dict()

        array = re.compile(
            r'(?P<varname>[a-zA-Z_][a-zA-Z_0-9$]+)\[(?P<arrindex>[0-9]+)\]'
        )

        # first find the vectors
        for signalid in signals:
            match = array.match(signals[signalid])
            if match:
                varname = match.group('varname')
                arrayindex = int(match.group('arrindex'))

                if varname not in vectors:
                    vectors[varname] = dict()
                    vectors[varname]['max'] = 0
                    vectors[varname]['min'] = 0

                if arrayindex > vectors[varname]['max']:
                    vectors[varname]['max'] = arrayindex

                if arrayindex < vectors[varname]['min']:
                    vectors[varname]['min'] = arrayindex

            # if signal is not a part of a vector leave it
            else:
                new_signals[signalid] = signals[signalid]

        # add vectors to signals dict
        for vec in vectors:
            name = '[{max}:{min}] {name}'.format(
                    max = vectors[vec]['max'],
                    min = vectors[vec]['min'],
                    name = vec)
            id = Wire(name, 'vector', False)
            new_signals[id] = name

        if io:
            # we need to restore the direction info
            new_ios = list()
            for s in new_signals:
                signalname = new_signals[s].split()
                signalname = signalname[-1]
                io = [x.direction for x in orig_ios if x.name.startswith(signalname)]
                direction = io[0]
                new_ios.append((direction, new_signals[s]))
            return new_ios
        else:
            return new_signals

    def group_array_values(self, parameters: dict):
        '''Groups pin names that represent array indices.

        Parameters
        ----------
        parameters: dict
            A dictionary holding original parameters

        Returns
        -------
        dict: parameters with grouped array indices
        '''
        newparameters = dict()
        arraydst = re.compile(
            r'(?P<varname>[a-zA-Z_][a-zA-Z_0-9$]+)\[(?P<arrindex>[0-9]+)\]'
        )
        for dst, src in parameters.items():
            match = arraydst.match(dst)
            if match:
                varname = match.group('varname')
                arrindex = int(match.group('arrindex'))
                if varname not in newparameters:
                    newparameters[varname] = {arrindex: src}
                else:
                    newparameters[varname][arrindex] = src
            else:
                newparameters[dst] = src
        return newparameters

    def form_simple_assign(self, loc, parameters):
        bloc = loc2str(loc)
        ioname = self.get_io_name(loc)

        assign = ""
        direction = self.get_io_config(parameters)
        if direction == 'input':
            assign = "    assign {} = {};".format(parameters["IZ"], ioname)
        elif direction == 'output':
            assign = "    assign {} = {};".format(ioname, parameters["OQI"])
        else:
            assert False, "Unknown IO configuration"

        return assign

    def form_verilog_element(self, loc, typ: str, name: str, parameters: dict):
        '''Creates an entry representing single Verilog submodule.

        Parameters
        ----------
        loc: Loc
            Cell coordinates
        typ: str
            Cell type
        name: str
            Name of the submodule
        parameters: dict
            Map from input pin to source wire

        Returns
        -------
        str: Verilog entry
        '''
        if typ == 'BIDIR':
            # We do not emit the BIDIR cell for non inout IOs
            if self.get_io_config(parameters) != 'inout':
                return self.form_simple_assign(loc, parameters)

        params = []
        moduletype = self.qlal4s3bmapping[typ]
        result = f'    {moduletype} {name} ('
        fixedparameters = self.group_array_values(parameters)
        for inpname, inp in fixedparameters.items():
            if isinstance(inp, dict):
                arr = []
                maxindex = max([val for val in inp.keys()])
                for i in range(maxindex + 1):
                    if i not in inp:
                        arr.append("1'b0")
                    else:
                        arr.append(inp[i])
                arrlist = ', '.join(arr)
                params.append(f'.{inpname}({{{arrlist}}})')
            else:
                params.append(f'.{inpname}({inp})')
        if self.useinversionpins:
            if typ in self.inversionpins:
                for toinvert, inversionpin in self.inversionpins[typ].items():
                    if toinvert in self.belinversions[loc][typ]:
                        params.append(f".{inversionpin}(1'b1)")
                    else:
                        params.append(f".{inversionpin}(1'b0)")
        # handle BIDIRs
        if typ == 'BIDIR':
            bloc = loc2str(loc)
            ioname = self.get_io_name(loc)
            params.append(f".IP({ioname})")

        result += f',\n{" " * len(result)}'.join(sorted(params)) + ');\n'
        return result

    @staticmethod
    def get_element_name(type, loc):
        '''Forms element name from its type and FASM feature name.'''
        return f'{type}_X{loc.x}_Y{loc.y}'

    def get_bel_type(self, loc, connections, direction):
        '''Returns bel type for a given connection list'''

        tile_type = self.vpr_tile_grid[loc].type
        cells = self.vpr_tile_types[tile_type].cells

        # check which BEL from the tile has a required pin
        if type(connections) == str:
            inputname = connections
        else:
            inputname = list(connections.keys())[0]
        for cell in cells:
            cellpins = [pin for pin in self.cells_library[cell].pins if pin.direction == direction]
            for pin in cellpins:
                if inputname == pin.name:
                    return cell

        raise Exception('No feasible cell found')

    def new_io_name(self, direction):
        '''Creates a new IO name for a given direction.

        Parameters
        ----------
        direction: str
            Direction of the IO, can be 'input' or 'output'
        '''
        # TODO add support for inout
        assert direction in ['input', 'output', 'inout']
        if direction == 'output':
            name = f'out_{self.last_output_id}'
            self.last_output_id += 1
        elif direction == 'input':
            name = f'in_{self.last_input_id}'
            self.last_input_id += 1
        else:
            pass
        return name

    def get_wire(self, loc, wire, inputname):
        '''Creates or gets an existing wire for a given source.

        Parameters
        ----------
        loc: Loc
            Location of the destination cell
        wire: tuple
            A tuple of location of the source cell and source pin name
        inputname: str
            A name of the destination pin

        Returns
        -------
        str: wire name
        '''
        isoutput = self.vpr_tile_grid[loc].type == 'SYN_IO'
        if isoutput:
            # outputs are never inverted
            inverted = False
        else:
            # determine if inverted
            inverted = (
                inputname in self.belinversions[loc][
                    self.vpr_tile_grid[loc].type]
            )
        wireid = Wire(wire[0], wire[1], inverted)
        if wireid in self.wires:
            # if wire already exists, use it
            return self.wires[wireid]

        # first create uninverted wire
        uninvertedwireid = Wire(wire[0], wire[1], False)
        if uninvertedwireid in self.wires:
            # if wire already exists, use it
            wirename = self.wires[uninvertedwireid]
        else:
            srcname = self.vpr_tile_grid[wire[0]].name
            srctype = self.get_bel_type(wire[0], wire[1], PinDirection.OUTPUT)
            srconame = wire[1]
            if srctype == 'SYN_IO':
                # if source is input, use its name
                if wire[0] not in self.ios:
                    self.ios[wire[0]] = VerilogIO(
                        name=self.new_io_name('input'),
                        direction='input',
                        ioloc=wire[0]
                    )
                assert self.ios[wire[0]].direction == 'input'
                wirename = self.ios[wire[0]].name
            else:
                # form a new wire name
                wirename = f'{srcname}_{srconame}'
            if srctype not in self.elements[wire[0]]:
                # if the source element does not exist, create it
                self.elements[wire[0]][srctype] = Element(
                    wire[0], srctype,
                    self.get_element_name(srctype, wire[0]),
                    {srconame: wirename}
                )
            else:
                # add wirename to the existing element
                self.elements[wire[0]][srctype].ios[srconame] = wirename
            if not isoutput and srctype != 'SYN_IO':
                # add wire
                self.wires[uninvertedwireid] = wirename
            elif isoutput:
                # add assign to output
                self.assigns[self.ios[loc].name] = wirename

        if not inverted or (
                self.useinversionpins and
                inputname in self.inversionpins[self.vpr_tile_grid[loc].type]):
            # if not inverted or we're not inverting, just finish
            return wirename

        # else create an inverted and wire for it
        invertername = f'{wirename}_inverter'

        invwirename = f'{wirename}_inv'

        inverterios = {'Q': invwirename, 'A': wirename}

        inverterelement = Element(wire[0], 'inv', invertername, inverterios)
        self.elements[wire[0]]['inv'] = inverterelement
        invertedwireid = Wire(wire[0], wire[1], True)
        self.wires[invertedwireid] = invwirename
        return invwirename

    def parse_bels(self):
        '''Converts BELs to Verilog-like structures.'''
        # TODO add support for direct input-to-output
        # first parse outputs to create wires for them

        # parse outputs first to properly handle namings
        for currloc, connections in self.designconnections.items():
            if self.vpr_tile_grid[currloc].type == 'SYN_IO':
                if 'OQI' in connections:
                    self.ios[currloc] = VerilogIO(
                        name=self.new_io_name('output'),
                        direction='output',
                        ioloc=currloc
                    )
                    self.get_wire(currloc, connections['OQI'], 'OQI')
                # TODO parse IE/INEN, check iz


        # process of BELs
        for currloc, connections in self.designconnections.items():
            # Extract type and form name for the BEL
            # currtype = self.vpr_tile_grid[currloc].type
            currtype = self.get_bel_type(currloc, connections, PinDirection.INPUT)
            currname = self.get_element_name(currtype, currloc)
            inputs = {}
            # form all inputs for the BEL
            for inputname, wire in connections.items():
                if wire[1] == 'VCC':
                    inputs[inputname] = "1'b1"
                    continue
                elif wire[1] == 'GND':
                    inputs[inputname] = "1'b0"
                    continue
                srctype = self.vpr_tile_grid[wire[0]].type
                srctype_cells = self.vpr_tile_types[srctype].cells
                if len(set(srctype_cells).intersection(set(['BIDIR', 'LOGIC', 'ASSP', 'RAM', 'MULT']))) > 0:
                    # FIXME handle already inverted pins
                    # TODO handle inouts
                    wirename = self.get_wire(currloc, wire, inputname)
                    inputs[inputname] = wirename
                else:
                    raise Exception('Not supported cell type {}'.format(srctype))
            if currtype not in self.elements[currloc]:
                # If Element does not exist, create it
                self.elements[currloc][currtype] = Element(
                    currloc, currtype, currname, inputs
                )
            else:
                # else update IOs
                self.elements[currloc][currtype].ios.update(inputs)


    def get_io_name(self, loc):

        # default pin name
        name = loc2str(loc) + '_inout'
        wirename = name
        # check if we have the original name for this io
        if self.pcf_data is not None:
            pin = self.io_to_fbio[loc]
            if pin in self.pcf_data:
                name = self.pcf_data[pin]
                name = name.replace('(', '[')
                name = name.replace(')', ']')

        return name

    def get_io_config(self, ios):
        # decode direction
        # direction is configured by routing 1 or 0 to certain inputs

        output_en = ios['IE'] != "1'b0"
        input_en = ios['INEN'] != "1'b0"

        if input_en and output_en:
            direction = 'inout'
        elif input_en:
            direction = 'input'
        elif output_en:
            direction = 'output'
        else:
            assert False, "Unknown IO configuration"

        return direction

    def generate_ios(self):
        '''Generates IOs and their wires

        Returns
        -------
        None
        '''
        for eloc, locelements in self.elements.items():
            for element in locelements.values():
                if element.type == 'BIDIR' or element.type == 'SDIOMUX':
                    direction = self.get_io_config(element.ios)

                    name = self.get_io_name(eloc)
                    self.ios[eloc] = VerilogIO(
                        name=name,
                        direction=direction,
                        ioloc=eloc
                    )
                    # keep the original wire name for generating the wireid
                    wireid = Wire(name, "inout_pin", False)
                    self.wires[wireid] = name

    def generate_verilog(self):
        '''Creates Verilog module

        Returns
        -------
        str: A Verilog module for given BELs
        '''
        ios = ''
        wires = ''
        assigns = ''
        elements = ''

        self.generate_ios()

        if len(self.ios) > 0:
            sortedios = sorted(
                self.ios.values(), key=lambda x: (x.direction, x.name)
            )
            grouped_ios = self.group_vector_signals(sortedios, True)
            ios = '\n    '
            ios += ',\n    '.join(
                [f'{x[0]} {x[1]}' for x in grouped_ios]
            )

        grouped_wires = self.group_vector_signals(self.wires)
        if len(grouped_wires) > 0:
            wires += '\n'
            for wire in grouped_wires.values():
                wires += f'    wire {wire};\n'

        if len(self.assigns) > 0:
            assigns += '\n'
            for dst, src in self.assigns.items():
                assigns += f'    assign {dst} = {src};\n'

        if len(self.elements) > 0:
            for eloc, locelements in self.elements.items():
                for element in locelements.values():
                    if element.type != 'SYN_IO':
                        elements += '\n'
                        elements += self.form_verilog_element(
                            eloc, element.type, element.name, element.ios
                        )

        verilog = (
            f'module top ({ios});\n'
            f'{wires}'
            f'{assigns}'
            f'{elements}'
            f'\n'
            f'endmodule'
        )
        return verilog

    def generate_pcf(self):
        pcf = ''
        for io in self.ios.values():
            pcf += f'set_io {io.name} {self.io_to_fbio[io.ioloc]}\n'
        return pcf

    def generate_qcf(self):
        qcf = '#[Fixed Pin Placement]\n'
        for io in self.ios.values():
            qcf += f'place {io.name} {self.io_to_fbio[io.ioloc]}\n'
        return qcf
