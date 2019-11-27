from __future__ import print_function
from collections import OrderedDict, namedtuple
import itertools
import lxml.etree as ET

PlaceConstraint = namedtuple('PlaceConstraint', 'name x y z comment')

HEADER_TEMPLATE = """\
#{name:<{nl}} x   y   z    pcf_line
#{s:-^{nl}} --  --  -    ----"""

CONSTRAINT_TEMPLATE = '{name:<{nl}} {x: 3} {y: 3} {z: 2}  # {comment}'


class PlaceConstraints(object):
    def __init__(self):
        self.constraints = OrderedDict()
        self.block_to_loc = None

    def load_loc_sites_from_net_file(self, net_file):
        """
        .place files expect top-level block (cluster) names, not net names, so
        build a mapping from net names to block names from the .net file.
        """
        net_xml = ET.parse(net_file)
        net_root = net_xml.getroot()
        self.net_to_block = {}

        for attr in net_root.xpath(
                "//attribute[@name='LOC']"
        ):
            # Get block name
            top_block = attr.getparent()
            assert block is not None
            while top_block.getparent() is not net_root:
                assert top_block is not None
                top_block = top_block.getparent()

            self.block_to_loc[top_block.get("name")] = attr.text

    def constrain_block(self, block_name, loc, comment=""):
        assert len(loc) == 3
        assert net_name not in self.constraints

        assert block_name not in self.block_to_loc, "block {} not in net".format(block_name)

        self.constraints[block_name] = PlaceConstraint(
            name=block_name,
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

        constrained_blocks = {}

        for vpr_net, constraint in self.constraints.items():
            name = constraint.name

            # This block is already constrained, check if there is no
            # conflict there.
            if name in constrained_blocks:
                existing = constrained_blocks[name]

                if existing.x != constraint.x or\
                   existing.y != constraint.y or\
                   existing.z != constraint.z:

                    print(
                        "Error: block '{}' has multiple conflicting constraints!"
                        .format(name)
                    )
                    print("", constrained_blocks[name])
                    print("", constraint)
                    exit(-1)

                # Don't write the second constraing
                continue

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

                # Add to constrained block list
                constrained_blocks[name] = constraint

    def get_loc_sites(self):
        for loc in self.block_to_loc:
            yield loc
