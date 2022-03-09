#!/usr/bin/env python3
"""
This utility script allows to visualize VPR placement. It reads a VPR .place
file and generates a bitmap with the visualization.
"""
import argparse
import re
import itertools

from PIL import Image, ImageDraw

# =============================================================================


def load_placement(placement_file):
    """
    Loads VPR placement file. Returns a tuple with the grid size and a dict
    indexed by locations that contains top-level block names.
    """

    RE_PLACEMENT = re.compile(
        r"^\s*(?P<net>\S+)\s+(?P<x>[0-9]+)\s+(?P<y>[0-9]+)\s+(?P<z>[0-9]+)"
    )

    RE_GRID_SIZE = re.compile(
        r"Array size:\s+(?P<x>[0-9]+)\s+x\s+(?P<y>[0-9]+)\s+logic blocks"
    )

    # Load the file
    with open(placement_file, "r") as fp:
        lines = fp.readlines()

    # Parse
    grid_size = None
    placement = {}

    for line in lines:
        line = line.strip()

        if line.startswith("#"):
            continue

        # Placement
        match = RE_PLACEMENT.match(line)
        if match is not None:

            loc = (int(match.group("x")), int(match.group("y")))

            placement[loc] = match.group("net")

        # Grid size
        match = RE_GRID_SIZE.match(line)
        if match is not None:

            grid_size = (int(match.group("x")), int(match.group("y")))

    return grid_size, placement


def generate_image(grid_size, placement, block_size=8, colormap=None):
    """
    Generates a visualization of the placement.
    """

    block_size = max(block_size, 3)
    gap_size = 1
    cell_size = block_size + 2 * gap_size

    # Create new image
    dx = grid_size[0] * cell_size + 1
    dy = grid_size[1] * cell_size + 1
    image = Image.new("RGB", (dx, dy), color="#FFFFFF")

    # Draw stuff
    draw = ImageDraw.Draw(image)
    for cx, cy in itertools.product(range(grid_size[0]), range(grid_size[1])):

        x0 = cx * cell_size + gap_size
        y0 = cy * cell_size + gap_size
        x1 = x0 + block_size
        y1 = y0 + block_size

        if (cx, cy) in placement:
            name = placement[(cx, cy)]
            if colormap is not None and name in colormap:
                color = colormap[name]
            else:
                color = "#2080C0"
        else:
            color = "#FFFFFF"

        draw.rectangle((x0, y0, x1, y1), color, "#000000")

    return image


# =============================================================================


def main():

    # Parse arguments
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument("place", type=str, help="A VPR .place file")

    parser.add_argument(
        "-o", type=str, default="placement.png", help="Output image file"
    )

    parser.add_argument(
        "--block-size", type=int, default=4, help="Block size (def. 4)"
    )

    args = parser.parse_args()

    # Load placement
    grid_size, placement = load_placement(args.place)

    # Colormap
    colormap = {
        "$true": "#C02020",
        "$false": "#000000",
    }

    # Generate the image
    image = generate_image(grid_size, placement, args.block_size, colormap)
    image.save(args.o)


# =============================================================================

if __name__ == "__main__":
    main()
