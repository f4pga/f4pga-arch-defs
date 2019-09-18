from __future__ import print_function
from collections import OrderedDict, namedtuple
import eblif

IoConstraint = namedtuple('IoConstraint', 'name x y z comment')

HEADER_TEMPLATE = """\
#{name:<{nl}} x   y   z    pcf_line
#{s:-^{nl}} --  --  -    ----"""

CONSTRAINT_TEMPLATE = '{name:<{nl}} {x: 3} {y: 3} {z: 2}  # {comment}'


class IoPlace(object):
    def __init__(self):
        self.constraints = OrderedDict()
        self.inputs = set()
        self.outputs = set()

    def read_io_list_from_eblif(self, eblif_file):
        blif = eblif.parse_blif(eblif_file)

        self.inputs = set(blif['inputs']['args'])
        self.outputs = set(blif['outputs']['args'])

    def constrain_net(self, net_name, loc, comment=""):
        assert len(loc) == 3
        assert net_name not in self.constraints

        assert net_name in self.inputs or net_name in self.outputs

        # VPR prefixes output constraints with "out:"
        if net_name in self.outputs:
            net_name = 'out:' + net_name

        self.constraints[net_name] = IoConstraint(
            name=net_name,
            x=loc[0],
            y=loc[1],
            z=loc[2],
            comment=comment,
        )

    def output_io_place(self, f, net_to_block=None):
        max_name_length = max(len(c.name) for c in self.constraints.values())
        print(
            HEADER_TEMPLATE.format(
                name="Block Name", nl=max_name_length, s=""
            ),
            file=f
        )

        for constraint in self.constraints.values():
            name = net_to_block[constraint.name] if net_to_block else constraint.name
            print(
                CONSTRAINT_TEMPLATE.format(
                    name=name,
                    nl=max_name_length,
                    x=constraint.x,
                    y=constraint.y,
                    z=constraint.z,
                    comment=constraint.comment
                ),
                file=f
            )

    def is_net(self, net):
        return net in self.inputs or net in self.outputs

    def get_nets(self):
        for net in self.inputs:
            yield net
        for net in self.outputs:
            yield net
