import lxml.etree as ET
import os

xi_url = "http://www.w3.org/2001/XInclude"

xi_include = "{%s}include" % xi_url

def include_xml(parent, href, outfile, xptr = None):
    """
    Generate an XML include, using a relative path.

    Inputs
    ------
    parent : XML element to insert include into
    href : path to included file
    outfile : path to output file, for relative path generation
    xptr : optional value for xpointer attribute
    """
    outpath = os.path.dirname(outfile)
    relhref = os.path.relpath(href, outpath)
    xattrs = {'href': relhref}
    if xptr is not None:
        xattrs["xpointer"] = xptr
    return ET.SubElement(parent, xi_include, xattrs)
