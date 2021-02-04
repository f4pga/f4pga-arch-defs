#!/usr/bin/env python3
"""
Reads the input files and substitutes tags defined as {<tag>} with their
corresponding values provided as arguments. The modified content is written
to a new file
"""
import argparse

# =============================================================================


def main():

    # Parse arguments
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "-i",
        type=str,
        required=True,
        help="Input file"
    )

    parser.add_argument(
        "-o",
        type=str,
        required=True,
        help="Output file"
    )

    parser.add_argument(
        "--tags",
        type=str,
        default=[],
        nargs="*",
        help="A list of tags. Each tag provided as <key>=<value>"
    )

    args = parser.parse_args()

    # Read the input file
    with open(args.i, "r") as fp:
        template = fp.read()

    # Parse tag list. Make a dict
    tags = {}
    for tag_spec in args.tags:
        key, value = tag_spec.split("=", maxsplit=1)
        tags[key] = value

    # Substitute
    render = str(template)
    for key, value in tags.items():
        pattern = "{" + key + "}"
        render = render.replace(pattern, value)

    # Write the rendered template
    with open(args.o, "w") as fp:
        fp.write(render)

# =============================================================================


if __name__ == "__main__":
    main()
