top_level = [
    "model",
    "inputs",
    "outputs",
    "names",
    "latch",
    "subckt",
]

sub_level = [
    "cname",
    "attr",
]


def parse_blif(f):
    current = None

    data = {}

    def add(d):
        if d['type'] not in data:
            data[d['type']] = []
        data[d['type']].append(d)

    current = None
    for oline in f:
        line = oline
        if '#' in line:
            line = line[:line.find('#')]
        line = line.strip()
        if not line:
            continue

        if line.startswith("."):
            args = line.split(" ", maxsplit=1)
            if len(args) < 2:
                args.append("")

            ctype = args.pop(0)
            assert ctype.startswith("."), ctype
            ctype = ctype[1:]

            if ctype in top_level:
                if current:
                    add(current)
                current = {
                    'type': ctype,
                    'args': args[-1].split(),
                    'data': [],
                }
            else:
                current[ctype] = args[-1].split()
            continue
        current['data'].append(line.strip().split())
    assert len(data['inputs']) == 1
    data['inputs'] = data['inputs'][0]
    assert len(data['outputs']) == 1
    data['outputs'] = data['outputs'][0]
    return data
