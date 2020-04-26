from __future__ import print_function
from collections import OrderedDict, namedtuple
import lxml.etree as ET

PlaceConstraint = namedtuple('PlaceConstraint', 'name x y z comment')

HEADER_TEMPLATE = """\
#{name:<{nl}} x   y   z    pcf_line
#{s:-^{nl}} --  --  -    ----"""

CONSTRAINT_TEMPLATE = '{name:<{nl}} {x: 3} {y: 3} {z: 2}  # {comment}'


def get_root_cluster(curr):
    while True:
        parent = curr.getparent()
        if parent is None:
            return None

        parent_parent = parent.getparent()
        if parent_parent is None:
            return curr

        curr = parent


class PlaceConstraints(object):
    def __init__(self):
        self.constraints = OrderedDict()
        self.block_to_loc = dict()

    def load_loc_sites_from_net_file(self, net_file):
        """
        .place files expect top-level block (cluster) names, not net names, so
        build a mapping from net names to block names from the .net file.
        """
        net_xml = ET.parse(net_file)
        net_root = net_xml.getroot()
        self.net_to_block = {}
        self.block_to_root_block = {}

        for el in net_root.iter('block'):
            root_block = get_root_cluster(el)
            if root_block is not None:
                self.block_to_root_block[el.attrib['name']
                                         ] = root_block.attrib['name']

        for attr in net_root.xpath("//attribute"):
            name = attr.attrib["name"]
            if name != 'LOC':
                continue

            # Get block name
            top_block = attr.getparent()
            assert top_block is not None
            while top_block.getparent() is not net_root:
                assert top_block is not None
                top_block = top_block.getparent()

            self.block_to_loc[top_block.get("name")] = attr.text

    def constrain_block(self, block_name, loc, comment=""):
        assert len(loc) == 3
        assert block_name not in self.constraints, block_name

        place_constraint = PlaceConstraint(
            name=block_name,
            x=loc[0],
            y=loc[1],
            z=loc[2],
            comment=comment,
        )

        root_block = self.block_to_root_block[block_name]

        self.constraints[root_block] = place_constraint

    def output_place_constraints(self, f):
        if not self.constraints:
            return

        max_name_length = max(len(c.name) for c in self.constraints.values())

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
        if self.block_to_loc is None:
            return

        for loc in self.block_to_loc:
            yield (loc, self.block_to_loc[loc])
