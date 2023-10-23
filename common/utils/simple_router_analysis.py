import argparse
import sys
import re
import scipy.io as sio

# Popping node CLBLL_L_X28Y15/CLBLL_LL_C (2993186) (cost: 4.59618e-13)
POP_RE = re.compile(
    r'Popping node ([A-Za-z0-9_/]+) \(([0-9]+)\) \(cost: ([0-9+\-.e]+)\)'
)

# Adding node  2993187 to heap from init route tree with cost 4.59618e-13
ADD_RE = re.compile(
    r'Adding node[ ]+([0-9]+) to heap from init route tree with cost ([0-9.e\-+])'
)

# rt_node: CLBLM_R_X27Y37/CLBLM_M_AMUX (1923687) (OPIN)
# rt_node: CLBLL_L_X38Y24/CLBLL_LL_C1 (3202101) (IPIN)
PIN_RE = re.compile(
    r'rt_node: ([A-Za-z0-9_/]+) \(([0-9]+)\) \(([^\)]+)\)(\*?)'
)


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument('--outmat')

    args = parser.parse_args()

    final_route = []

    pop_map = {}
    inode_cost = {}
    inode_names = {}

    pops = 0
    for idx, l in enumerate(sys.stdin):
        m = POP_RE.search(l)
        if m is not None:
            pops += 1
            inode = int(m.group(2))
            if inode not in pop_map:
                pop_map[inode] = (idx + 1, pops)

            new_cost = float(m.group(3))
            if new_cost < inode_cost.get(inode, float('inf')):
                inode_cost[inode] = new_cost

        m = PIN_RE.search(l)
        if m is not None:
            final_route.append(int(m.group(2)))
            inode_names[int(m.group(2))] = m.group(1)
    if args.outmat:
        mat_data = {
            'final_route': final_route,
            'pop_map_inodes': list(pop_map.keys()),
            'inode_cost_inodes': list(inode_cost.keys()),
            'inode_names_inodes': list(inode_names.keys()),
        }

        mat_data['pop_map'] = [
            pop_map[inode] for inode in mat_data['pop_map_inodes']
        ]
        mat_data['inode_cost'] = [
            inode_cost[inode] for inode in mat_data['inode_cost_inodes']
        ]
        mat_data['inode_names'] = [
            inode_names[inode] for inode in mat_data['inode_names_inodes']
        ]

        mat_data['route_pop'] = [
            pop_map[inode] for inode in final_route if inode in pop_map
        ]
        mat_data['route_pop_inodes'] = [
            inode for inode in final_route if inode in pop_map
        ]

        mat_data['route_cost'] = [
            inode_cost[inode] for inode in final_route if inode in inode_cost
        ]
        mat_data['route_cost_inodes'] = [
            inode for inode in final_route if inode in inode_cost
        ]

        sio.savemat(args.outmat, mat_data)
    else:
        for idx, inode in enumerate(final_route):
            if inode not in pop_map:
                pop_str = 'unknown'
            else:
                line, pop_count = pop_map[inode]

                pop_str = '{} ({} %) @ {}'.format(
                    pop_count, 100. * float(pop_count) / pops, line
                )

            print(
                '{}. {} "{}", cost = {}, first explored at pop {}'.format(
                    idx + 1, inode, inode_names.get(inode, "N/A"),
                    inode_cost.get(inode, 'N/A'), pop_str
                )
            )


if __name__ == "__main__":
    main()
