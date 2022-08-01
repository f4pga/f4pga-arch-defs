"""
A tool for extracting module port definitions from PDF specifications
"""

# the following cases required specific adjustments to the base algorithm:
#   CFGLUT5, IDDR, IDELAYCTRL, IDELAYE2, ISERDESE2, KEEPER, LUT6, LUT6_2,
#   MMCME2_BASE, ODDR, OSERDESE2, PLLE2_BASE, RAM128X1D, RAM64M
# any changes to the algorithm should be checked against these entries

# we use pdfminer to parse the PDF document and interpret the elements
# for python3 support you need to `pip install pdfminer.six`
from pdfminer.pdfparser import PDFParser
from pdfminer.pdfdocument import PDFDocument
from pdfminer.pdfinterp import PDFResourceManager, PDFPageInterpreter
from pdfminer.pdfpage import PDFPage
from pdfminer.converter import PDFLayoutAnalyzer
from pdfminer.layout import LAParams, LTContainer, LTTextLineHorizontal

from collections import OrderedDict
import sys
import re

from datetime import datetime
from lxml import objectify, etree

PAGE_MARGIN = 60  # space ignored at the top and bottom of the page, for page header/footer
HEADER_MARGIN = 30  # space ignored at the start of the section due to the section header
COL_MARGIN = 5  # acceptable variation in x-position of entries in the same column


def rev_enumerate(it, last=None):
    for i in range(len(it))[last::-1]:
        yield i, it[i]


class PDFTableParser(PDFLayoutAnalyzer):
    """Custom interpreter that hooks into pdfminer to process PDF text elements"""

    def __init__(
            self, rsrcmgr, laparams=None, stop_at=None, top=None, bottom=None
    ):
        PDFLayoutAnalyzer.__init__(self, rsrcmgr, pageno=1, laparams=laparams)
        self.stop_at = stop_at
        self.reset(top, bottom)

    def process_text(self, bbox, txt, obj):
        # there's no guarantee on the order in which text strings appear
        # so store them all for post-processing after sorting them into order
        if self.stop_at is not None and txt.startswith(self.stop_at):
            self.done = True
            self.bottom = bbox[3] + COL_MARGIN
            return True
        txt = txt.replace(u'\u2019', "'")  # all HEX constants
        txt = txt.replace(u'\u2022', '\n*')  # bullet lists
        txt = txt.replace(
            u'\u201c', '"'
        )  # e.g. FRAME_ECCE2 (FRAME_RBT_IN_FILENAME)
        txt = txt.replace(
            u'\u201d', '"'
        )  # e.g. FRAME_ECCE2 (FRAME_RBT_IN_FILENAME)
        self.items.append([int(-bbox[3]), int(bbox[0]), txt])
        return True

    def reset(self, top, bottom):
        self.top = top
        self.bottom = bottom
        self.done = False
        self.items = []

    def receive_layout(self, ltpage):
        if self.done:
            return

        def render(item):
            # don't process it if it's outside the FOV
            if getattr(item, 'y1', self.bottom) <= self.bottom:
                return True
            if getattr(item, 'y0', self.top) >= self.top:
                return True
            # process individual lines of text
            if isinstance(item, LTTextLineHorizontal):
                if not self.process_text(item.bbox, item.get_text().strip(),
                                         item):
                    return False
            # process containers that (might) contain text (e.g. LTTextBoxHorizontal)
            elif isinstance(item, LTContainer):
                for child in item:
                    if not render(child):
                        return False
            return True

        # default to processing the entire page
        if self.top is None:
            self.top = ltpage.mediabox[3]
        if self.bottom is None:
            self.bottom = ltpage.mediabox[1]
        render(ltpage)
        self.items[:] = sorted(self.items)

    # don't bother doing any image/line rendering
    def render_image(self, name, stream):
        return

    def paint_path(self, gstate, stroke, fill, evenodd, path):
        return

    # data processing functions
    def process_table(self):
        # figure out the table header
        top = -self.bottom
        self.heads = []
        for y, x, t in self.items:
            if y < top:
                top = y
        for i, (y, x, t) in rev_enumerate(self.items):
            if y < top + COL_MARGIN:
                self.heads.append((x - COL_MARGIN, t))
                self.items.pop(i)
        self.heads = sorted(self.heads)
        # figure out the rows
        leftcol = self.heads[1][0]
        self.rows = []
        self.items[:] = sorted(self.items)
        for i, (y, x, t) in rev_enumerate(self.items):
            if x < leftcol:
                self.items.pop(i)
                if t[0] == '<' and t[-1] == '>':
                    continue  # IDELAYE2
                self.rows.append((y, t))
                if t.startswith('NOTE:') or not (
                        t.isupper()
                        or t in ['/', '-', 'to']) or y > -self.bottom:
                    self.bottom = -y
                    self.done = True
        self.rows = [(y, t) for y, t in self.rows[::-1] if y < -self.bottom]
        # join rows together if required
        for i, x in rev_enumerate(self.rows, -3):
            if self.rows[i + 1][1] in ('to', '/', '-'):
                self.rows[i] = (
                    x[0], x[1] + self.rows[i + 1][1] + self.rows.pop(i + 2)[1]
                )
                self.rows.pop(i + 1)
        for i, x in rev_enumerate(self.rows, -2):
            if x[1][-1] in ',_/' or x[1].endswith('to') or self.rows[
                    i + 1][1][0] == '_' or x[0] == self.rows[i + 1][0]:
                self.rows[i] = (x[0], x[1] + self.rows.pop(i + 1)[1])
        # correct y-positions
        for i, (y, x, t) in rev_enumerate(self.items):
            if y >= -self.bottom:
                self.items.pop(i)
            else:
                self.items[i][0] = int(y)
        # now sort items by corrected y-positions
        self.items = sorted(self.items)

    def get_row(self, y):
        for i, (y0, t) in enumerate(self.rows[1:]):
            if y < y0 - COL_MARGIN:
                return i
        return len(self.rows) - 1

    def arrange_items(self):
        data = []
        for r in self.rows:
            d = OrderedDict([(k[1], '') for k in self.heads])
            d[self.heads[0][1]] = r[1].replace(' ', '')
            data.append(d)
        for y, x, t in sorted(self.items):
            for x0, head in self.heads[::-1]:
                if x >= x0:
                    entry = data[self.get_row(y)]
                    if len(entry[head]
                           ) and entry[head][-1] != '_' and t[0] != '_':
                        t = ' ' + t
                    entry[head] += t
                    break
        return data


def resolve_goto_action(doc, a):
    """Resolves a "goto" action from the PDF outline into the associated page
    object and position on that page"""
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


def parse_module_pages(doc, start_at):
    """Deconstruct the PDF outline into a list of modules, with links to the
    start and end of the associated "port descriptions" section"""
    parts = OrderedDict()
    module = None
    start = None
    process = False
    pgs = PDFPage.create_pages(doc)
    for (level, title, dest, a, se) in doc.get_outlines():
        if level == 2:  # chapter titles
            # modules are defined in chapter 4
            process = title.startswith('Ch. 4:')
        elif process and level == 3:  # module names are defined at level 3 of the TOC
            module = title
        elif level == 4 and module is not None and title.startswith(start_at):
            # NB: possible incosistency in "title" name (e.g. LUT6)
            start = resolve_goto_action(doc, a)
        elif start is not None and module not in parts:  # i.e. this is the FIRST following section
            stop = resolve_goto_action(doc, a)
            parts[module] = find_pages(pgs, start, stop)
            start = None
    return parts


def process_ports(tbl):
    """Process the text elements corresponding to the "port descriptions"
    table and return an ordered list of ports"""
    if not len(tbl.items):
        return []
    # fixes for MMCME2_BASE
    for i, (y, x, t) in rev_enumerate(tbl.items):
        if tbl.items[i][2] == 'Clock' and tbl.items[i + 1][2] == 'Inputs':
            tbl.items[i][2] = 'CLKIN1'
            tbl.items.pop(i + 1)
        elif tbl.items[i][2] == 'Status' and tbl.items[i + 1][2] == 'Ports':
            tbl.items[i][2] = 'LOCKED'
            tbl.items.pop(i + 1)
        elif t == 'Direction Width':
            tbl.items[i][2] = 'Direction'
            tbl.items.insert(
                i + 1, (y, (x + tbl.items[i + 1][1]) / 2, 'Width')
            )
    tbl.process_table()
    # transform headers as necessary
    for i, (x, name) in enumerate(tbl.heads):
        if name.lower().startswith('direction'):
            tbl.heads[i] = (x, 'Type')
    # sort the items into categories
    ports = tbl.arrange_items()
    # process the rows one-by-one (in reverse, because we might insert new entries)
    for i, x in rev_enumerate(ports):
        # process the "width" entry
        M = re.match(
            r'([0-9]+)', x['Width']
        )  # remove any additional text (e.g. ODDR, KEEPER)
        if M is None:
            print(
                '\tInvalid width %s on %s, skipping item' %
                (repr(x['Width']), repr(x['Port']))
            )
            return []
        x['Width'] = wid = int(M.group(0))
        # process the "direction" entry
        if x['Type'] == 'Input':
            dir = 'input'
        elif x['Type'] == 'Output':
            dir = 'output'
        elif x['Type'] == 'In/out':
            dir = 'inout'
        else:
            assert False, 'Invalid pin type %s' % repr(x['Type'])
        x['Type'] = dir
        # process the port name
        name = re.sub(
            r'\s', '', x['Port']
        )  # remove any spaces from (multiline) name entries (e.g. MMCME2_BASE)
        if '<' in name:  # bus pins MIGHT be explicitly listed in name; perform sanity check
            name, bits = name.split('<', 1)
            assert bits == '%d:0>' % (wid - 1)
        elif '-' in name:  # entry is a range of pins (e.g. ISERDESE2)
            n, start, stop = re.match(
                r'([A-Z]+)([0-9]+)\s*-\s*[A-Z]+([0-9]+)', name
            ).groups()
            ports.pop(i)
            for j in range(int(start), int(stop) + 1):
                y = x.copy()
                y['Port'] = n + '%d' % j
                ports.insert(i + j - 1, y)
            continue
        # is the entry actually a LIST of pins? (e.g. CFGLUT5, OSERDESE2, ODDR)
        M = re.split(r'[,/:]', name)
        if len(M) > 1:
            ports.pop(i)
            for j, n in enumerate(M):
                y = x.copy()
                y['Port'] = n.strip()
                ports.insert(i + j, y)
        else:
            x['Port'] = name
    return ports


def process_attributes(tbl):
    if not len(tbl.items):
        return []
    tbl.process_table()
    # transform headers as necessary
    for i, (x, name) in enumerate(tbl.heads):
        if name in ('Allowed Values', 'Allowed_Values'):
            tbl.heads[i] = (x, 'Allowed')
        if name == 'Descriptions':
            tbl.heads[i] = (x, 'Description')
    # transform text as necessary
    for i, (y, x, t) in enumerate(tbl.items):
        t = t.replace(u'\u2122', '(tm)')  # IOBUF (DRIVE)
        t = t.replace('""', '"')  # RAM18E1 (SIM_DEVICE)
        tbl.items[i][2] = t
    # sort the items into categories
    attribs = tbl.arrange_items()
    # post-process the entries
    for i, x in rev_enumerate(attribs):
        if x['Type'] == 'STRING' and x[
                'Default'] == 'None':  # ICAPE2 (SIM_CFG_FILE_NAME)
            x['Default'] = '""'
        if x['Default'][0] == '"' and x['Default'][
                -1] != '"':  # RAMB18E1 (WRITE_MODE_A)
            s1, s2 = x['Default'].rsplit('"', 1)
            x['Default'] = s1 + '"'
            x['Description'] = s2 + ' ' + x['Description']
        if x['Default'].startswith('All'):
            if 'one' in x['Default']:
                val = 'F'
            elif 'zero' in x['Default']:
                val = '0'
            else:
                raise TypeError
            assert x['Type'] == 'HEX'
            M = re.search(r'(\d+)[-\s][Bb]it', x['Allowed'])
            if M is None:
                break
            sz = int(M.group(1))
            pad = 1 if sz % 4 else 0
            x['Default'] = "%d'h%s" % (sz, val * ((sz // 4) + pad))
        elif x['Default'].startswith("0'h"):  # ICAPE2 (DEVICE_ID)
            x['Default'] = "32'h0" + x['Default'][3:]
        if ',' in x['Attribute']:
            attribs.pop(i)
            for j, n in enumerate(x['Attribute'].split(',')):
                n = n.strip()
                if not len(n):
                    continue
                y = x.copy()
                y['Attribute'] = n
                attribs.insert(i + j, y)
        M = re.match(
            r'([A-Z_]+)([0-9A-F]+)?(_[A-Z_]+)?to([A-Z_]+)([0-9A-F]+)(_[A-Z_]+)?',
            x['Attribute']
        )
        if M is not None:
            pre1, start, post1, pre2, stop, post2 = M.groups()
            attribs.pop(i)
            if start is None:
                y = x.copy()
                y['Attribute'] = pre1
                attribs.insert(i, y)
                start = '0'
                pre1 = pre2
                post1 = post2
                i += 1
            else:
                assert pre1 == pre2 and post1 == post2 and len(start
                                                               ) == len(stop)
                if post1 is None:
                    post1 = ''
            nchar = len(stop)
            if re.match(r'[0-9]+$', start) is not None and re.match(
                    r'[0-9]+$', stop) is not None:
                start = int(start)
                stop = int(stop)
                fmt = '%s%0*d%s'
            else:
                start = int(start, 16)
                stop = int(stop, 16)
                fmt = '%s%0*X%s'
            for j in range(start, stop + 1):
                y = x.copy()
                y['Attribute'] = fmt % (pre1, nchar, j, post1)
                attribs.insert(i + j, y)
    return attribs


def process_specs(infile, modules=None):
    """Process the module specifications in the input PDF into an XML tree"""
    # initialise the pdfminer interface --
    # we use a custom "render device" to receive the text objects in the PDF for further processing
    resman = PDFResourceManager()
    doc = PDFDocument(PDFParser(open(infile, 'rb')))
    laparams = LAParams(
        line_margin=0.1, char_margin=0.7
    )  # parameters optimised to prevent incorrectly joining together words

    device = PDFTableParser(resman, laparams, stop_at='VHDL')
    interpreter = PDFPageInterpreter(resman, device)

    # parse the PDF table of contents to figure out what modules exist and which pages to process
    port_pages = parse_module_pages(doc, 'Port Desc')
    if modules is None or len(modules) == 0:
        modules = port_pages.keys()  # default to processing ALL modules
    attrib_list = parse_module_pages(
        doc, 'Available Attrib'
    )  # NB: not all modules have attributes

    # parse the specifications and generate an XML tree
    E = objectify.ElementMaker(annotate=False)
    root = E.xml(source=infile, processed=datetime.now().isoformat())

    # run through the modules
    for module in modules:
        sys.stderr.write('Processing %s...\n' % module)
        node = E.module(name=module)
        # process the ports of this module
        for pg, top, bottom in port_pages[module]:
            device.reset(top, bottom)
            interpreter.process_page(pg)
            for P in process_ports(device):
                node.append(
                    E.port(
                        name=P['Port'], type=P['Type'], width=str(P['Width'])
                    )
                )
            if device.done:
                break
        # process the attributes of this module
        for pg, top, bottom in attrib_list.get(module, []):
            device.reset(top, bottom)
            interpreter.process_page(pg)
            for A in process_attributes(device):
                node.append(
                    E.attribute(
                        name=A['Attribute'],
                        type=A['Type'],
                        default=A['Default'].replace('"', ''),
                        values=A['Allowed'].replace('"', '')
                    )
                )
            if device.done:
                break
        # add it to the root object
        root.append(node)
    return root


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--input',
        '-i',
        nargs='?',
        default='ug953-vivado-7series-libraries.pdf'
    )
    parser.add_argument(
        '--output',
        '-o',
        nargs='?',
        type=argparse.FileType('w'),
        default=sys.stdout
    )
    parser.add_argument('--modules', '-m', nargs='*')
    args = parser.parse_args()

    xml = process_specs(args.input, args.modules)
    args.output.write(etree.tostring(xml, pretty_print=True).decode('ascii'))
