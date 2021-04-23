#!/usr/bin/env python3
import os
import sys
import tempfile

import lxml.etree as ET

sys.path.append(os.path.join(os.path.dirname(__file__), "..", ".."))
from packed_netlist import PackedNetlist  # noqa: E402

# =============================================================================


def test_netlist_roundtrip():

    basedir = os.path.dirname(__file__)
    golden_file = os.path.join(basedir, "netlist.golden.net")

    # Load the XSLT for sorting
    xslt_file = os.path.join(basedir, "../sort_netlist.xsl")
    xslt = ET.parse(xslt_file)
    xform = ET.XSLT(xslt)

    # Load the golden netlist XML
    xml_tree = ET.parse(golden_file, ET.XMLParser(remove_blank_text=True))

    with tempfile.TemporaryDirectory() as tempdir:

        # Transform and save the golden file
        sorted_golden_file = os.path.join(tempdir, "netlist.golden.sorted.net")
        with open(sorted_golden_file, "w") as fp:
            et = xform(xml_tree)
            st = '<?xml version="1.0">\n' \
                 + ET.tostring(et, pretty_print=True).decode("utf-8")
            fp.write(st)

        # Build packed netlist
        netlist = PackedNetlist.from_etree(xml_tree.getroot())

        # Convert the netlist back to element tree
        xml_tree = ET.ElementTree(netlist.to_etree())

        # Transform and save the output file
        sorted_output_file = os.path.join(tempdir, "netlist.output.sorted.net")
        with open(sorted_output_file, "w") as fp:
            et = xform(xml_tree)
            st = '<?xml version="1.0">\n' \
                 + ET.tostring(et, pretty_print=True).decode("utf-8")
            fp.write(st)

        # Compare the two files
        with open(sorted_golden_file, "r") as fp:
            golden_data = fp.read()
        with open(sorted_output_file, "r") as fp:
            output_data = fp.read()

        assert golden_data == output_data
