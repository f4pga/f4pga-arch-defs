import re

def parse_pcf(f, pin_map, icecube2_hacks=False):
    pcf_data = {}
    for i, oline in enumerate(f):
        line = oline
        if icecube2_hacks and not re.search(" # ICE_(GB_)?IO", line):
            continue
        line = re.sub(r"#.*", "", line.strip()).split()
        if "--warn-no-port" in line:
            line.remove("--warn-no-port")
        if len(line) and line[0] == "set_io":
            p = line[1]
            if icecube2_hacks:
                p = p.lower()
                p = re.sub(r"_ibuf$", "", p)
                p = re.sub(r"_obuft$", "", p)
                p = re.sub(r"_obuf$", "", p)
                p = re.sub(r"_gb_io$", "", p)
                p = re.sub(r"_pad(_[0-9]+|)$", r"\1", p)
            if not re.match(r"[a-zA-Z_][a-zA-Z0-9_]*(\[[0-9]*\])?$", p):
                p = "\\%s " % p
            if len(line) > 3:
                pinloc = tuple([int(s) for s in line[2:]])
            else:
                pinloc = (line[2],)

            for l in pinloc:
                if l not in pin_map:
                    raise SyntaxError("""\
Pin name {} doesn't exist!
Line: {}
{}""".format(l, i, oline))
                pcf_data[p] = (pin_map[l], oline.strip())
    return pcf_data
