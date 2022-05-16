from __future__ import print_function
import lxml.etree as ET


def read_xml_file(rr_graph_file):
    return ET.parse(rr_graph_file, ET.XMLParser(remove_blank_text=True))
