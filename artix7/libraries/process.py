#!/usr/bin/env python3

import re
header = re.compile('(acro:|imitive:)')
caps_only = re.compile('^[A-Z0-9_]+$')
vhdl_param = re.compile('([A-Z0-9_]+)\s*=>\s*([XOB]?"[^"]*"|[0-9.]+|[A-Z0-9_]+)[^-]*(--.*)?')
vhdl_template = re.compile('--.*Xilinx.*HDL.*Language.*Template')

bit_extract = re.compile('\s*([0-9]*)\s*.bit[^i]*(input|output):')
output_filter = re.compile('\s(output\s+(register|clock|control)|enable\s+output)')

bits = {}
current_header = ''

i = 0
lines = open('ug953-vivado-7series-libraries.2.txt').readlines()
while i < len(lines):
    line = lines[i]
    if current_header not in bits:
        bits[current_header] = []
    bits[current_header].append(line.strip())
    i += 1

    if header.search(line):
        header_name_line = ''
        j = 2
        while not header_name_line:
            header_name_line = lines[i-j].strip()
            j += 1
        if not caps_only.match(header_name_line):
            continue

        current_header = header_name_line


from collections import OrderedDict
modules = {}
for obj_name in sorted(bits):
    lines = list(bits[obj_name])

    while lines and not vhdl_template.search(lines[0]):
        lines.pop(0)
    if len(lines) > 1:
        lines.pop(0)
    else:
        print("No template for ", obj_name)

    param_lines = OrderedDict()
    while lines and 'port map' not in lines[0]:
        m = vhdl_param.match(lines[0])
        if m:
            init_name, init_value, init_comment = m.groups()
            init_value = init_value.strip()
            if init_value.endswith('"'):
                if init_value.startswith('B"'): # Binary
                    init_value = int("".join(i for i in init_value if i in ('0', '1')), 2)
                elif init_value.startswith('O"'): # Octal
                    init_value = int(init_value[2:-1], 8)
                elif init_value.startswith('X"'): # Hexidecimal
                    init_value = int(init_value[2:-1], 16)
                else:
                    assert init_value.startswith('"')
                    init_type = '' # A String
            elif init_value == 'FALSE':
                init_type = ''
                init_value = '"FALSE"'
            elif init_value == 'TRUE':
                init_type = ''
                init_value = '"TRUE"'
            elif '.' in init_value:
                init_type = 'real'
                init_value = float(init_value)
            else:
                print(obj_name, repr(lines[0]), repr(init_value))
                init_type = 'integer'
                init_value = int(init_value)

            param_lines[init_name] = (init_type, init_value)
        lines.pop(0)

    port_lines = OrderedDict()
    while lines and '-- End of' not in lines[0]:
        m = vhdl_param.match(lines[0])
        if m:
            port_name, _, port_comment = m.groups()
            if not port_comment:
                port_comment = ''

            b = bit_extract.search(port_comment)
            if b:
                width = int(b.group(1))
                modes = [b.group(2)]
            else:
                assert not 'bit ' in m.group(1), m.group(1)
                width = 1

                modes = []
                if 'input' in port_comment:
                    modes.append('input')
                if 'output' in output_filter.sub('', port_comment):
                    # Hack to work around tristate input on iobufs
                    if not obj_name.startswith('IOBUF') or not lines[0].strip().startswith('T'):
                        modes.append('output')

                if not modes:
                    modes.append('input')

            assert len(modes) == 1, (modes, obj_name, lines[0])

            if width == 1:
                port_type = ''
            else:
                port_type = '[%s:]' % width
                print(obj_name, port_name, port_type)

            port_lines[port_name] = (port_type, modes[0])
        lines.pop(0)

    print()
    print(obj_name)
    print("-"*75)
    for i in param_lines:
        print(i)
    print("-"*75)
    for i in port_lines:
        print(i)
    print("="*75)

    modules[obj_name] = (param_lines, port_lines)


from jinja2 import Template
template = Template(open('cells_xtra.v.jinja2').read())
with open('cells_xtra.v', 'w') as f:
    f.write(re.sub('\n\n+', '\n\n', template.render(modules=modules)))
