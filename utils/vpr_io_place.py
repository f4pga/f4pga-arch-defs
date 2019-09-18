from __future__ import print_function
from collections import OrderedDict, namedtuple
import eblif
import lxml.etree as ET

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
        self.net_to_block = None

    def read_io_list_from_eblif(self, eblif_file):
        blif = eblif.parse_blif(eblif_file)

        self.inputs = set(blif['inputs']['args'])
        self.outputs = set(blif['outputs']['args'])

    def load_block_names_from_net_file(self, net_file):
        """
        .place files expect top-level block (cluster) names, not net names, so
        build a mapping from net names to block names from the .net file.
        """
        net_xml = ET.parse(net_file)
        net_root = net_xml.getroot()
        self.net_to_block = {}

        for block in net_root.xpath(
                "//block[@instance='inpad[0]'] | //block[@instance='outpad[0]']"
        ):
            top_block = block.getparent()
            assert top_block is not None
            while top_block.getparent() is not net_root:
                assert top_block is not None
                top_block = top_block.getparent()
            self.net_to_block[block.get("name")] = top_block.get("name")

    def constrain_net(self, net_name, loc, comment=""):
        assert len(loc) == 3
        assert net_name not in self.constraints

        assert net_name in self.inputs or net_name in self.outputs, "net {} not in eblif".format(
            net_name
        )

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

    def output_io_place(self, f):
        max_name_length = max(len(c.name) for c in self.constraints.values())
        print(
            HEADER_TEMPLATE.format(
                name="Block Name", nl=max_name_length, s=""
            ),
            file=f
        )

        for constraint in self.constraints.values():
            name = self.net_to_block.get(
                constraint.name
            ) if self.net_to_block else constraint.name

            # omit if no corresponding block name for the net
            if name is not None:
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
