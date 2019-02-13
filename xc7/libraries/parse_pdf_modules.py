"""
A tool for extracting module port definitions from PDF specifications
"""

# the following cases required specific adjustments to the base algorithm:
#   CFGLUT5, IDDR, IDELAYCTRL, IDELAYE2, ISERDESE2, KEEPER, LUT6, LUT6_2, MMCME2_BASE, ODDR, OSERDESE2, PLLE2_BASE, RAM128X1D, RAM64M
# any changes to the algorithm should be checked against these entries

# we use pdfminer to parse the PDF document and interpret the elements
# for python3 support you need to `pip install pdfminer.six`
from pdfminer.pdfparser import PDFParser
from pdfminer.pdfdocument import PDFDocument
from pdfminer.pdfinterp import PDFResourceManager, PDFPageInterpreter
from pdfminer.pdfpage import PDFPage
from pdfminer.converter import PDFLayoutAnalyzer
from pdfminer.layout import LAParams, LTText, LTContainer

from collections import OrderedDict
import re

PAGE_MARGIN = 60    # space ignored at the top and bottom of the page, for page header/footer
HEADER_MARGIN = 25  # space ignored at the start of the section due to the section header
COL_MARGIN = 5      # acceptable variation in x-position of entries in the same column

class PortParser(PDFLayoutAnalyzer):
    """Custom interpreter that hooks into pdfminer to process PDF text elements"""
    def __init__(self, rsrcmgr, laparams=None, top=None, bottom=None):
        PDFLayoutAnalyzer.__init__(self, rsrcmgr, pageno=1, laparams=laparams)
        self.set_bounds(top, bottom)
    def process_text(self, bbox, txt):
        if txt.lower() == 'direction' or txt == 'Direction Width':  # the two headers might get mashed together in some tables
            txt = 'Type'
        if txt in self.heads:
            self.heads[txt] = int(bbox[0]-COL_MARGIN)
        else:
            self.text_items.append((-int(bbox[3]), int(bbox[0]), txt))
    def set_bounds(self, top, bottom):
        self.top = top
        self.bottom = bottom
        self.text_items = []
        self.heads = OrderedDict(Function=None, Width=None, Type=None, Port=None)
    def receive_layout(self, ltpage):
        def render(item):
            # don't process it if it's outside the FOV
            if getattr(item,'y1',self.bottom) <= self.bottom: return
            if getattr(item,'y0',self.top) >= self.top: return
            # process text or any items that might contain text
            if isinstance(item, LTText):
                self.process_text(item.bbox, item.get_text().strip())
            elif isinstance(item, LTContainer):
                for child in item:
                    render(child)
        # default to the entire page
        if self.top is None: self.top = ltpage.mediabox[3]
        if self.bottom is None: self.bottom = ltpage.mediabox[1]
        render(ltpage)
    # don't bother doing any image/line rendering
    def render_image(self, name, stream):
        return
    def paint_path(self, gstate, stroke, fill, evenodd, path):
        return

def resolve_goto_action(doc, a):
    """Resolves a "goto" action from the PDF outline into the associated page object and position on that page"""
    a = a.resolve()
    assert a['S'].name == 'GoTo'
    link = doc.get_dest(a['D']).resolve()['D']
    y = link[3] if link[1].name == 'XYZ' else 0
    return link[0], y

def find_pages(pgs, start, stop):
    """Find all the pages between the resolved "start" and "stop" actions"""
    extract = False
    bottom = PAGE_MARGIN
    for pg in pgs:
        if pg.pageid == start[0].objid:
            extract = True
            top = start[1] - HEADER_MARGIN
        else:
            top = pg.mediabox[3] - PAGE_MARGIN
        if pg.pageid == stop[0].objid:
            bottom = stop[1]
        if extract:
            yield pg, top, bottom
        if pg.pageid == stop[0].objid:
            return

def parse_module_pages(doc):
    """Deconstruct the PDF outline into a list of modules, with links to the start and end of the associated "port descriptions" section"""
    parts = OrderedDict()
    module = None
    start = None
    process = False
    pgs = PDFPage.create_pages(doc)
    for (level, title, dest, a, se) in doc.get_outlines():
        if level == 2:
            process = title.startswith('Ch. 4:')  # modules are defined in chapter 4
        elif process and level == 3:  # module names are defined at level 3 of the TOC
            module = title
        elif level == 4 and module is not None and title.startswith('Port Description'):   # might not be plural (e.g. LUT6)
            start = resolve_goto_action(doc, a)
        elif start is not None and module not in parts: # i.e. this is the FIRST following section
            stop = resolve_goto_action(doc, a)
            parts[module] = list(find_pages(pgs, start, stop))
            start = None
    return parts

def generate_xml(module, ports):
    """Generate some trashy XML to describe the module"""
    s = '<module name="%s">\n'%module
    for p in ports: s += '\t<port name="%s" type="%s" width="%d" />\n'%p
    s += '</module>\n\n'
    return s
    
def generate_verilog(module, ports):
    """Generate some Verilog describing the module"""
    s = 'module %s (%s);\n'%(module, ", ".join([p[0] for p in ports]))
    for name, type, wid in ports:
        if wid > 1: name = ('[%d:0]\t'%(wid-1)) + name
        s += '\t%-8s%s\n'%(type,name)
    s += "endmodule\n\n"
    return s

def process_items(heads, items):
    """Process the text elements corresponding to the "port descriptions" table and return an ordered list of ports"""
    if not len(items): return []
    # workarounds for the table headers
    if heads['Function'] is None and heads['Port'] is None: # no table present
        return []
    if heads['Width'] is None: # "Width" too close to "Direction" heading (e.g. RAM128X1D)
        heads['Width'] = (heads['Type']+heads['Function'])/2. - COL_MARGIN
    # sort the items into categories
    categories = {k: [] for k in heads}
    for y,x,t in sorted(items):
        for head,x0 in heads.items():
            if x > x0:
                categories[head].append(t)
                break
    # we don't care about descriptions
    categories.pop('Function')
    # check for multiport specs (e.g. CFGLUT5 or LUT6)
    for i in range(len(categories['Port']))[-1::-1]:
        if categories['Port'][i].endswith(','):
            categories['Port'][i] += categories['Port'].pop(i+1)
    # combine the entries into rows
    # this zip only works because we _know_ each category has one entry per row. if we didn't drop descriptions, this would be more complicated
    ports = [item[::-1] for item in zip(*categories.values())]
    # process the rows one-by-one (in reverse, because we might insert new entries)
    for i in range(len(ports))[::-1]:
        name, dir, wid = ports[i]
        if not name.isupper(): # remove strings AFTER the table (e.g. RAM128X1D)
            ports.pop(i)
            continue
        # process the "width" entry
        M = re.match(r'([0-9]+)', wid)   # remove any additional text (e.g. ODDR, KEEPER)
        if M is None:
            print('\tInvalid width %s, skipping item'%repr(wid))
            return []
        wid = int(M.group(0))
        # process the "direction" entry
        if dir == 'Input':      dir = 'input'
        elif dir == 'Output':   dir = 'output'
        elif dir == 'In/out':   dir = 'inout'
        else:                   assert False, 'Invalid pin type %s'%repr(dir)
        # process the port name
        name = re.sub(r'\s','',name)    # remove any spaces from (multiline) name entries (e.g. MMCME2_BASE)
        if '<' in name:   # bus pins MIGHT be explicitly listed in name; perform sanity check
            name, bits = name.split('<',1)
            assert bits == '%d:0>'%(wid-1)
        elif '-' in name:  # entry is a range of pins (e.g. ISERDESE2)
            n, start, stop = re.match(r'([A-Z]+)([0-9]+)\s*-\s*[A-Z]+([0-9]+)',name).groups()
            ports.pop(i)
            for j in range(int(start),int(stop)+1):
                ports.insert(i+j, (n+'%d'%j, dir, wid))
            continue
        # is the entry actually a LIST of pins? (e.g. CFGLUT5, OSERDESE2, ODDR)
        M = re.split(r'[,/:]', name)
        if len(M) > 1:
            ports.pop(i)
            for n in M: ports.insert(i, (n.strip(), dir, wid))
        else:
            ports[i] = (name, dir, wid)
    return ports
    
    
def run(infp, outfp, flush=True):
    """Process the specific input PDF into the output XML"""
    resman = PDFResourceManager()
    doc = PDFDocument(PDFParser(infp))
    laparams = LAParams(line_margin=0.1, char_margin=0.8)   # parameters optimised to prevent incorrectly joining together words
    device = PortParser(resman, laparams)
    interpreter = PDFPageInterpreter(resman, device)
    
    for module, pages in parse_module_pages(doc).items():
        print(module)
        ports = []
        for pg, top, bottom in pages:
            device.set_bounds(top, bottom)
            interpreter.process_page(pg)
            ports += process_items(device.heads, device.text_items)
        if len(ports):
            outfp.write(generate_verilog(module, ports))
            if flush: outfp.flush()
        
if __name__ == '__main__':
    import sys
    infile = sys.argv[1] if len(sys.argv) > 1 else 'ug953-vivado-7series-libraries.pdf'
    outfile = sys.argv[2] if len(sys.argv) > 2 else 'cells_xtra.v'
    run(open(infile,'rb'), open(outfile,'w'))
