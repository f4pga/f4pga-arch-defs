import re
import sys


def main():
    # Popping node CLBLM_R_X27Y37/CLBLM_M_AMUX (1923686) (cost: 0)
    POP_RE = re.compile(
        r'Popping node ([A-Za-z0-9_/]+) \([0-9]+\) \(cost: ([0-9+\-.e]+)\)'
    )

    # rt_node: CLBLM_R_X27Y37/CLBLM_M_AMUX (1923687) (OPIN)
    # rt_node: CLBLL_L_X38Y24/CLBLL_LL_C1 (3202101) (IPIN)
    PIN_RE = re.compile(
        r'rt_node: ([A-Za-z0-9_/]+) \([0-9]+\) \(([^\)]+)\)(\*?)'
    )

    print(
        """
proc animate {idx node_length} {
    select_objects [get_nodes -of [get_wires [lindex $nodes $idx]]]
    set idx [expr $idx+1]
    if { $idx < $node_length } {
        after 100 [animate $idx $node_length]
    }
}"""
    )
    print('set nodes {}')

    wires = []

    final_route = []

    for l in sys.stdin:
        m = POP_RE.search(l)

        if m:
            wires.append(m.group(1))

        m = PIN_RE.search(l)
        if m:
            if m.group(3) == '*':
                continue

            final_route.append((m.group(1), m.group(2)))

    assert final_route[0][1] == 'OPIN', final_route[0]

    for r in final_route[1:-1]:
        assert r[1] in ['CHANX', 'CHANY'], r
    assert final_route[-1][1] == 'IPIN', final_route[-1]

    print('unhighlight_objects')

    for idx, (wire, _) in enumerate(final_route):
        print(
            'highlight_objects -color_index {} [get_nodes -of [get_wires {}]]'.
            format((idx % 20) + 1, wire)
        )

    for wire in wires:
        print('select_objects [get_nodes -of [get_wires {}]]'.format(wire))


if __name__ == "__main__":
    main()
