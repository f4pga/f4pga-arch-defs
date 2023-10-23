#!/usr/bin/env python3
"""
This script extracts coloring scheme of tile grid from a given documentation
webpage. Like that ones:

 - https://symbiflow.github.io/prjxray-db/artix7/index.html
 - https://symbiflow.github.io/prjtrellis-db/ECP5/LFE5U-25F/index.html

For now the webpage needs to be read from a file.
"""
import re
import json
import argparse

from html.parser import HTMLParser

# =============================================================================


class MyHTMLParser(HTMLParser):
    def __init__(self, *args, **kwargs):

        # Call base constructor
        HTMLParser.__init__(self, *args, **kwargs)

        self.tree = []
        self.hierarchy = ""
        self.color = None

        # Tile type colors
        self.tile_colors = {}

    @staticmethod
    def get_hierarchy(tree):
        hierarchy = [node[0] for node in tree]
        return "/".join(hierarchy)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)

        self.tree.append((tag, attrs))
        self.hierarchy = self.get_hierarchy(self.tree)

        # Got a table entry (for prjxray doc)
        if self.hierarchy == "html/body/table/tr/td":

            # Check if it is the one we are looking for
            if "bgcolor" in attrs.keys() and "title" in attrs.keys():

                # Get tile type from its name
                tile_type = attrs["title"].split("\n")[0]
                match = re.match("(.*)_X[0-9]*Y[0-9]*", tile_type)

                if match is None:
                    return

                tile_type = match.group(1)

                # Store the color
                if tile_type not in self.tile_colors.keys():
                    self.tile_colors[tile_type] = attrs["bgcolor"].upper()
                    print(
                        "{} {}".format(self.tile_colors[tile_type], tile_type)
                    )

        # Got a table entry (for prjtrellis doc)
        if self.hierarchy == "html/body/table/tr/td/div":

            # Extract color from style and store it
            if "style" in attrs and "background-color" in attrs["style"]:
                style = attrs["style"]
                self.color = style.rsplit(":", maxsplit=1)[1].strip().upper()

    def handle_endtag(self, tag):
        self.tree.pop()
        self.hierarchy = self.get_hierarchy(self.tree)

    def handle_data(self, data):

        # Got tile type (for prjtrellis doc)
        if self.hierarchy == "html/body/table/tr/td/div/strong/a":
            if self.color is not None:

                # Store the color
                tile_type = data
                if tile_type not in self.tile_colors.keys():
                    self.tile_colors[tile_type] = self.color
                    print(
                        "{} {}".format(self.tile_colors[tile_type], tile_type)
                    )

                self.color = None


# =============================================================================


def main():

    # Parse arguments
    parser = argparse.ArgumentParser(
        description=__doc__.strip(),
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument("-i", type=str, required=True, help="Input HTML file")
    parser.add_argument(
        "-o",
        type=str,
        default="tile_colormap.json",
        help="Output color scheme JSON file"
    )

    args = parser.parse_args()

    html_parser = MyHTMLParser()

    # Parse the html
    with open(args.i, "r") as fp:
        html_data = fp.read()
        html_parser.feed(html_data)

    # Format the scheme structure
    scheme = []
    for tile_type, color in html_parser.tile_colors.items():
        scheme.append({"type": tile_type, "color": color})

    # Save the scheme
    with open(args.o, "w") as fp:
        json.dump(scheme, fp, sort_keys=True, indent=1)


# =============================================================================

if __name__ == "__main__":
    main()
