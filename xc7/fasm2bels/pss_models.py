from collections import defaultdict

from .verilog_modeling import Site, Bel

from .connection_db_utils import get_wire_pkey, get_node_pkey, get_wires_in_node
from .make_routes import create_check_for_default
from .make_routes import create_check_downstream_default

# Set to True to verbose PS7 connectivity check
DEBUG = False

# =============================================================================

# This is a definition of all PS7 input and output ports along with their
# widths. Ports that do not go to the PL are not listed here
PS7_PINS = {
    "input":
        [
            ["DDRARB", 4],
            ["DMA0ACLK", 1],
            ["DMA0DAREADY", 1],
            ["DMA0DRLAST", 1],
            ["DMA0DRTYPE", 2],
            ["DMA0DRVALID", 1],
            ["DMA1ACLK", 1],
            ["DMA1DAREADY", 1],
            ["DMA1DRLAST", 1],
            ["DMA1DRTYPE", 2],
            ["DMA1DRVALID", 1],
            ["DMA2ACLK", 1],
            ["DMA2DAREADY", 1],
            ["DMA2DRLAST", 1],
            ["DMA2DRTYPE", 2],
            ["DMA2DRVALID", 1],
            ["DMA3ACLK", 1],
            ["DMA3DAREADY", 1],
            ["DMA3DRLAST", 1],
            ["DMA3DRTYPE", 2],
            ["DMA3DRVALID", 1],
            ["EMIOCAN0PHYRX", 1],
            ["EMIOCAN1PHYRX", 1],
            ["EMIOENET0EXTINTIN", 1],
            ["EMIOENET0GMIICOL", 1],
            ["EMIOENET0GMIICRS", 1],
            ["EMIOENET0GMIIRXCLK", 1],
            ["EMIOENET0GMIIRXD", 8],
            ["EMIOENET0GMIIRXDV", 1],
            ["EMIOENET0GMIIRXER", 1],
            ["EMIOENET0GMIITXCLK", 1],
            ["EMIOENET0MDIOI", 1],
            ["EMIOENET1EXTINTIN", 1],
            ["EMIOENET1GMIICOL", 1],
            ["EMIOENET1GMIICRS", 1],
            ["EMIOENET1GMIIRXCLK", 1],
            ["EMIOENET1GMIIRXD", 8],
            ["EMIOENET1GMIIRXDV", 1],
            ["EMIOENET1GMIIRXER", 1],
            ["EMIOENET1GMIITXCLK", 1],
            ["EMIOENET1MDIOI", 1],
            ["EMIOGPIOI", 64],
            ["EMIOI2C0SCLI", 1],
            ["EMIOI2C0SDAI", 1],
            ["EMIOI2C1SCLI", 1],
            ["EMIOI2C1SDAI", 1],
            ["EMIOPJTAGTCK", 1],
            ["EMIOPJTAGTDI", 1],
            ["EMIOPJTAGTMS", 1],
            ["EMIOSDIO0CDN", 1],
            ["EMIOSDIO0CLKFB", 1],
            ["EMIOSDIO0CMDI", 1],
            ["EMIOSDIO0DATAI", 4],
            ["EMIOSDIO0WP", 1],
            ["EMIOSDIO1CDN", 1],
            ["EMIOSDIO1CLKFB", 1],
            ["EMIOSDIO1CMDI", 1],
            ["EMIOSDIO1DATAI", 4],
            ["EMIOSDIO1WP", 1],
            ["EMIOSPI0MI", 1],
            ["EMIOSPI0SCLKI", 1],
            ["EMIOSPI0SI", 1],
            ["EMIOSPI0SSIN", 1],
            ["EMIOSPI1MI", 1],
            ["EMIOSPI1SCLKI", 1],
            ["EMIOSPI1SI", 1],
            ["EMIOSPI1SSIN", 1],
            ["EMIOSRAMINTIN", 1],
            ["EMIOTRACECLK", 1],
            ["EMIOTTC0CLKI", 3],
            ["EMIOTTC1CLKI", 3],
            ["EMIOUART0CTSN", 1],
            ["EMIOUART0DCDN", 1],
            ["EMIOUART0DSRN", 1],
            ["EMIOUART0RIN", 1],
            ["EMIOUART0RX", 1],
            ["EMIOUART1CTSN", 1],
            ["EMIOUART1DCDN", 1],
            ["EMIOUART1DSRN", 1],
            ["EMIOUART1RIN", 1],
            ["EMIOUART1RX", 1],
            ["EMIOUSB0VBUSPWRFAULT", 1],
            ["EMIOUSB1VBUSPWRFAULT", 1],
            ["EMIOWDTCLKI", 1],
            ["EVENTEVENTI", 1],
            ["FCLKCLKTRIGN", 4],
            ["FPGAIDLEN", 1],
            ["FTMDTRACEINATID", 4],
            ["FTMDTRACEINCLOCK", 1],
            ["FTMDTRACEINDATA", 32],
            ["FTMDTRACEINVALID", 1],
            ["FTMTF2PDEBUG", 32],
            ["FTMTF2PTRIG", 4],
            ["FTMTP2FTRIGACK", 4],
            ["IRQF2P", 20],
            ["MAXIGP0ACLK", 1],
            ["MAXIGP0ARREADY", 1],
            ["MAXIGP0AWREADY", 1],
            ["MAXIGP0BID", 12],
            ["MAXIGP0BRESP", 2],
            ["MAXIGP0BVALID", 1],
            ["MAXIGP0RDATA", 32],
            ["MAXIGP0RID", 12],
            ["MAXIGP0RLAST", 1],
            ["MAXIGP0RRESP", 2],
            ["MAXIGP0RVALID", 1],
            ["MAXIGP0WREADY", 1],
            ["MAXIGP1ACLK", 1],
            ["MAXIGP1ARREADY", 1],
            ["MAXIGP1AWREADY", 1],
            ["MAXIGP1BID", 12],
            ["MAXIGP1BRESP", 2],
            ["MAXIGP1BVALID", 1],
            ["MAXIGP1RDATA", 32],
            ["MAXIGP1RID", 12],
            ["MAXIGP1RLAST", 1],
            ["MAXIGP1RRESP", 2],
            ["MAXIGP1RVALID", 1],
            ["MAXIGP1WREADY", 1],
            ["SAXIACPACLK", 1],
            ["SAXIACPARADDR", 32],
            ["SAXIACPARBURST", 2],
            ["SAXIACPARCACHE", 4],
            ["SAXIACPARID", 3],
            ["SAXIACPARLEN", 4],
            ["SAXIACPARLOCK", 2],
            ["SAXIACPARPROT", 3],
            ["SAXIACPARQOS", 4],
            ["SAXIACPARSIZE", 2],
            ["SAXIACPARUSER", 5],
            ["SAXIACPARVALID", 1],
            ["SAXIACPAWADDR", 32],
            ["SAXIACPAWBURST", 2],
            ["SAXIACPAWCACHE", 4],
            ["SAXIACPAWID", 3],
            ["SAXIACPAWLEN", 4],
            ["SAXIACPAWLOCK", 2],
            ["SAXIACPAWPROT", 3],
            ["SAXIACPAWQOS", 4],
            ["SAXIACPAWSIZE", 2],
            ["SAXIACPAWUSER", 5],
            ["SAXIACPAWVALID", 1],
            ["SAXIACPBREADY", 1],
            ["SAXIACPRREADY", 1],
            ["SAXIACPWDATA", 64],
            ["SAXIACPWID", 3],
            ["SAXIACPWLAST", 1],
            ["SAXIACPWSTRB", 8],
            ["SAXIACPWVALID", 1],
            ["SAXIGP0ACLK", 1],
            ["SAXIGP0ARADDR", 32],
            ["SAXIGP0ARBURST", 2],
            ["SAXIGP0ARCACHE", 4],
            ["SAXIGP0ARID", 6],
            ["SAXIGP0ARLEN", 4],
            ["SAXIGP0ARLOCK", 2],
            ["SAXIGP0ARPROT", 3],
            ["SAXIGP0ARQOS", 4],
            ["SAXIGP0ARSIZE", 2],
            ["SAXIGP0ARVALID", 1],
            ["SAXIGP0AWADDR", 32],
            ["SAXIGP0AWBURST", 2],
            ["SAXIGP0AWCACHE", 4],
            ["SAXIGP0AWID", 6],
            ["SAXIGP0AWLEN", 4],
            ["SAXIGP0AWLOCK", 2],
            ["SAXIGP0AWPROT", 3],
            ["SAXIGP0AWQOS", 4],
            ["SAXIGP0AWSIZE", 2],
            ["SAXIGP0AWVALID", 1],
            ["SAXIGP0BREADY", 1],
            ["SAXIGP0RREADY", 1],
            ["SAXIGP0WDATA", 32],
            ["SAXIGP0WID", 6],
            ["SAXIGP0WLAST", 1],
            ["SAXIGP0WSTRB", 4],
            ["SAXIGP0WVALID", 1],
            ["SAXIGP1ACLK", 1],
            ["SAXIGP1ARADDR", 32],
            ["SAXIGP1ARBURST", 2],
            ["SAXIGP1ARCACHE", 4],
            ["SAXIGP1ARID", 6],
            ["SAXIGP1ARLEN", 4],
            ["SAXIGP1ARLOCK", 2],
            ["SAXIGP1ARPROT", 3],
            ["SAXIGP1ARQOS", 4],
            ["SAXIGP1ARSIZE", 2],
            ["SAXIGP1ARVALID", 1],
            ["SAXIGP1AWADDR", 32],
            ["SAXIGP1AWBURST", 2],
            ["SAXIGP1AWCACHE", 4],
            ["SAXIGP1AWID", 6],
            ["SAXIGP1AWLEN", 4],
            ["SAXIGP1AWLOCK", 2],
            ["SAXIGP1AWPROT", 3],
            ["SAXIGP1AWQOS", 4],
            ["SAXIGP1AWSIZE", 2],
            ["SAXIGP1AWVALID", 1],
            ["SAXIGP1BREADY", 1],
            ["SAXIGP1RREADY", 1],
            ["SAXIGP1WDATA", 32],
            ["SAXIGP1WID", 6],
            ["SAXIGP1WLAST", 1],
            ["SAXIGP1WSTRB", 4],
            ["SAXIGP1WVALID", 1],
            ["SAXIHP0ACLK", 1],
            ["SAXIHP0ARADDR", 32],
            ["SAXIHP0ARBURST", 2],
            ["SAXIHP0ARCACHE", 4],
            ["SAXIHP0ARID", 6],
            ["SAXIHP0ARLEN", 4],
            ["SAXIHP0ARLOCK", 2],
            ["SAXIHP0ARPROT", 3],
            ["SAXIHP0ARQOS", 4],
            ["SAXIHP0ARSIZE", 2],
            ["SAXIHP0ARVALID", 1],
            ["SAXIHP0AWADDR", 32],
            ["SAXIHP0AWBURST", 2],
            ["SAXIHP0AWCACHE", 4],
            ["SAXIHP0AWID", 6],
            ["SAXIHP0AWLEN", 4],
            ["SAXIHP0AWLOCK", 2],
            ["SAXIHP0AWPROT", 3],
            ["SAXIHP0AWQOS", 4],
            ["SAXIHP0AWSIZE", 2],
            ["SAXIHP0AWVALID", 1],
            ["SAXIHP0BREADY", 1],
            ["SAXIHP0RDISSUECAP1EN", 1],
            ["SAXIHP0RREADY", 1],
            ["SAXIHP0WDATA", 64],
            ["SAXIHP0WID", 6],
            ["SAXIHP0WLAST", 1],
            ["SAXIHP0WRISSUECAP1EN", 1],
            ["SAXIHP0WSTRB", 8],
            ["SAXIHP0WVALID", 1],
            ["SAXIHP1ACLK", 1],
            ["SAXIHP1ARADDR", 32],
            ["SAXIHP1ARBURST", 2],
            ["SAXIHP1ARCACHE", 4],
            ["SAXIHP1ARID", 6],
            ["SAXIHP1ARLEN", 4],
            ["SAXIHP1ARLOCK", 2],
            ["SAXIHP1ARPROT", 3],
            ["SAXIHP1ARQOS", 4],
            ["SAXIHP1ARSIZE", 2],
            ["SAXIHP1ARVALID", 1],
            ["SAXIHP1AWADDR", 32],
            ["SAXIHP1AWBURST", 2],
            ["SAXIHP1AWCACHE", 4],
            ["SAXIHP1AWID", 6],
            ["SAXIHP1AWLEN", 4],
            ["SAXIHP1AWLOCK", 2],
            ["SAXIHP1AWPROT", 3],
            ["SAXIHP1AWQOS", 4],
            ["SAXIHP1AWSIZE", 2],
            ["SAXIHP1AWVALID", 1],
            ["SAXIHP1BREADY", 1],
            ["SAXIHP1RDISSUECAP1EN", 1],
            ["SAXIHP1RREADY", 1],
            ["SAXIHP1WDATA", 64],
            ["SAXIHP1WID", 6],
            ["SAXIHP1WLAST", 1],
            ["SAXIHP1WRISSUECAP1EN", 1],
            ["SAXIHP1WSTRB", 8],
            ["SAXIHP1WVALID", 1],
            ["SAXIHP2ACLK", 1],
            ["SAXIHP2ARADDR", 32],
            ["SAXIHP2ARBURST", 2],
            ["SAXIHP2ARCACHE", 4],
            ["SAXIHP2ARID", 6],
            ["SAXIHP2ARLEN", 4],
            ["SAXIHP2ARLOCK", 2],
            ["SAXIHP2ARPROT", 3],
            ["SAXIHP2ARQOS", 4],
            ["SAXIHP2ARSIZE", 2],
            ["SAXIHP2ARVALID", 1],
            ["SAXIHP2AWADDR", 32],
            ["SAXIHP2AWBURST", 2],
            ["SAXIHP2AWCACHE", 4],
            ["SAXIHP2AWID", 6],
            ["SAXIHP2AWLEN", 4],
            ["SAXIHP2AWLOCK", 2],
            ["SAXIHP2AWPROT", 3],
            ["SAXIHP2AWQOS", 4],
            ["SAXIHP2AWSIZE", 2],
            ["SAXIHP2AWVALID", 1],
            ["SAXIHP2BREADY", 1],
            ["SAXIHP2RDISSUECAP1EN", 1],
            ["SAXIHP2RREADY", 1],
            ["SAXIHP2WDATA", 64],
            ["SAXIHP2WID", 6],
            ["SAXIHP2WLAST", 1],
            ["SAXIHP2WRISSUECAP1EN", 1],
            ["SAXIHP2WSTRB", 8],
            ["SAXIHP2WVALID", 1],
            ["SAXIHP3ACLK", 1],
            ["SAXIHP3ARADDR", 32],
            ["SAXIHP3ARBURST", 2],
            ["SAXIHP3ARCACHE", 4],
            ["SAXIHP3ARID", 6],
            ["SAXIHP3ARLEN", 4],
            ["SAXIHP3ARLOCK", 2],
            ["SAXIHP3ARPROT", 3],
            ["SAXIHP3ARQOS", 4],
            ["SAXIHP3ARSIZE", 2],
            ["SAXIHP3ARVALID", 1],
            ["SAXIHP3AWADDR", 32],
            ["SAXIHP3AWBURST", 2],
            ["SAXIHP3AWCACHE", 4],
            ["SAXIHP3AWID", 6],
            ["SAXIHP3AWLEN", 4],
            ["SAXIHP3AWLOCK", 2],
            ["SAXIHP3AWPROT", 3],
            ["SAXIHP3AWQOS", 4],
            ["SAXIHP3AWSIZE", 2],
            ["SAXIHP3AWVALID", 1],
            ["SAXIHP3BREADY", 1],
            ["SAXIHP3RDISSUECAP1EN", 1],
            ["SAXIHP3RREADY", 1],
            ["SAXIHP3WDATA", 64],
            ["SAXIHP3WID", 6],
            ["SAXIHP3WLAST", 1],
            ["SAXIHP3WRISSUECAP1EN", 1],
            ["SAXIHP3WSTRB", 8],
            ["SAXIHP3WVALID", 1],
        ],
    "output":
        [
            ["DMA0DATYPE", 2],
            ["DMA0DAVALID", 1],
            ["DMA0DRREADY", 1],
            ["DMA0RSTN", 1],
            ["DMA1DATYPE", 2],
            ["DMA1DAVALID", 1],
            ["DMA1DRREADY", 1],
            ["DMA1RSTN", 1],
            ["DMA2DATYPE", 2],
            ["DMA2DAVALID", 1],
            ["DMA2DRREADY", 1],
            ["DMA2RSTN", 1],
            ["DMA3DATYPE", 2],
            ["DMA3DAVALID", 1],
            ["DMA3DRREADY", 1],
            ["DMA3RSTN", 1],
            ["EMIOCAN0PHYTX", 1],
            ["EMIOCAN1PHYTX", 1],
            ["EMIOENET0GMIITXD", 8],
            ["EMIOENET0GMIITXEN", 1],
            ["EMIOENET0GMIITXER", 1],
            ["EMIOENET0MDIOMDC", 1],
            ["EMIOENET0MDIOO", 1],
            ["EMIOENET0MDIOTN", 1],
            ["EMIOENET0PTPDELAYREQRX", 1],
            ["EMIOENET0PTPDELAYREQTX", 1],
            ["EMIOENET0PTPPDELAYREQRX", 1],
            ["EMIOENET0PTPPDELAYREQTX", 1],
            ["EMIOENET0PTPPDELAYRESPRX", 1],
            ["EMIOENET0PTPPDELAYRESPTX", 1],
            ["EMIOENET0PTPSYNCFRAMERX", 1],
            ["EMIOENET0PTPSYNCFRAMETX", 1],
            ["EMIOENET0SOFRX", 1],
            ["EMIOENET0SOFTX", 1],
            ["EMIOENET1GMIITXD", 8],
            ["EMIOENET1GMIITXEN", 1],
            ["EMIOENET1GMIITXER", 1],
            ["EMIOENET1MDIOMDC", 1],
            ["EMIOENET1MDIOO", 1],
            ["EMIOENET1MDIOTN", 1],
            ["EMIOENET1PTPDELAYREQRX", 1],
            ["EMIOENET1PTPDELAYREQTX", 1],
            ["EMIOENET1PTPPDELAYREQRX", 1],
            ["EMIOENET1PTPPDELAYREQTX", 1],
            ["EMIOENET1PTPPDELAYRESPRX", 1],
            ["EMIOENET1PTPPDELAYRESPTX", 1],
            ["EMIOENET1PTPSYNCFRAMERX", 1],
            ["EMIOENET1PTPSYNCFRAMETX", 1],
            ["EMIOENET1SOFRX", 1],
            ["EMIOENET1SOFTX", 1],
            ["EMIOGPIOO", 64],
            ["EMIOGPIOTN", 64],
            ["EMIOI2C0SCLO", 1],
            ["EMIOI2C0SCLTN", 1],
            ["EMIOI2C0SDAO", 1],
            ["EMIOI2C0SDATN", 1],
            ["EMIOI2C1SCLO", 1],
            ["EMIOI2C1SCLTN", 1],
            ["EMIOI2C1SDAO", 1],
            ["EMIOI2C1SDATN", 1],
            ["EMIOPJTAGTDO", 1],
            ["EMIOPJTAGTDTN", 1],
            ["EMIOSDIO0BUSPOW", 1],
            ["EMIOSDIO0BUSVOLT", 3],
            ["EMIOSDIO0CLK", 1],
            ["EMIOSDIO0CMDO", 1],
            ["EMIOSDIO0CMDTN", 1],
            ["EMIOSDIO0DATAO", 4],
            ["EMIOSDIO0DATATN", 4],
            ["EMIOSDIO0LED", 1],
            ["EMIOSDIO1BUSPOW", 1],
            ["EMIOSDIO1BUSVOLT", 3],
            ["EMIOSDIO1CLK", 1],
            ["EMIOSDIO1CMDO", 1],
            ["EMIOSDIO1CMDTN", 1],
            ["EMIOSDIO1DATAO", 4],
            ["EMIOSDIO1DATATN", 4],
            ["EMIOSDIO1LED", 1],
            ["EMIOSPI0MO", 1],
            ["EMIOSPI0MOTN", 1],
            ["EMIOSPI0SCLKO", 1],
            ["EMIOSPI0SCLKTN", 1],
            ["EMIOSPI0SO", 1],
            ["EMIOSPI0SSNTN", 1],
            ["EMIOSPI0SSON", 3],
            ["EMIOSPI0STN", 1],
            ["EMIOSPI1MO", 1],
            ["EMIOSPI1MOTN", 1],
            ["EMIOSPI1SCLKO", 1],
            ["EMIOSPI1SCLKTN", 1],
            ["EMIOSPI1SO", 1],
            ["EMIOSPI1SSNTN", 1],
            ["EMIOSPI1SSON", 3],
            ["EMIOSPI1STN", 1],
            ["EMIOTRACECTL", 1],
            ["EMIOTRACEDATA", 32],
            ["EMIOTTC0WAVEO", 3],
            ["EMIOTTC1WAVEO", 3],
            ["EMIOUART0DTRN", 1],
            ["EMIOUART0RTSN", 1],
            ["EMIOUART0TX", 1],
            ["EMIOUART1DTRN", 1],
            ["EMIOUART1RTSN", 1],
            ["EMIOUART1TX", 1],
            ["EMIOUSB0PORTINDCTL", 2],
            ["EMIOUSB0VBUSPWRSELECT", 1],
            ["EMIOUSB1PORTINDCTL", 2],
            ["EMIOUSB1VBUSPWRSELECT", 1],
            ["EMIOWDTRSTO", 1],
            ["EVENTEVENTO", 1],
            ["EVENTSTANDBYWFE", 2],
            ["EVENTSTANDBYWFI", 2],
            ["FCLKCLK", 4],
            ["FCLKRESETN", 4],
            ["FTMTF2PTRIGACK", 4],
            ["FTMTP2FDEBUG", 32],
            ["FTMTP2FTRIG", 4],
            ["IRQP2F", 29],
            ["MAXIGP0ARADDR", 32],
            ["MAXIGP0ARBURST", 2],
            ["MAXIGP0ARCACHE", 4],
            ["MAXIGP0ARESETN", 1],
            ["MAXIGP0ARID", 12],
            ["MAXIGP0ARLEN", 4],
            ["MAXIGP0ARLOCK", 2],
            ["MAXIGP0ARPROT", 3],
            ["MAXIGP0ARQOS", 4],
            ["MAXIGP0ARSIZE", 2],
            ["MAXIGP0ARVALID", 1],
            ["MAXIGP0AWADDR", 32],
            ["MAXIGP0AWBURST", 2],
            ["MAXIGP0AWCACHE", 4],
            ["MAXIGP0AWID", 12],
            ["MAXIGP0AWLEN", 4],
            ["MAXIGP0AWLOCK", 2],
            ["MAXIGP0AWPROT", 3],
            ["MAXIGP0AWQOS", 4],
            ["MAXIGP0AWSIZE", 2],
            ["MAXIGP0AWVALID", 1],
            ["MAXIGP0BREADY", 1],
            ["MAXIGP0RREADY", 1],
            ["MAXIGP0WDATA", 32],
            ["MAXIGP0WID", 12],
            ["MAXIGP0WLAST", 1],
            ["MAXIGP0WSTRB", 4],
            ["MAXIGP0WVALID", 1],
            ["MAXIGP1ARADDR", 32],
            ["MAXIGP1ARBURST", 2],
            ["MAXIGP1ARCACHE", 4],
            ["MAXIGP1ARESETN", 1],
            ["MAXIGP1ARID", 12],
            ["MAXIGP1ARLEN", 4],
            ["MAXIGP1ARLOCK", 2],
            ["MAXIGP1ARPROT", 3],
            ["MAXIGP1ARQOS", 4],
            ["MAXIGP1ARSIZE", 2],
            ["MAXIGP1ARVALID", 1],
            ["MAXIGP1AWADDR", 32],
            ["MAXIGP1AWBURST", 2],
            ["MAXIGP1AWCACHE", 4],
            ["MAXIGP1AWID", 12],
            ["MAXIGP1AWLEN", 4],
            ["MAXIGP1AWLOCK", 2],
            ["MAXIGP1AWPROT", 3],
            ["MAXIGP1AWQOS", 4],
            ["MAXIGP1AWSIZE", 2],
            ["MAXIGP1AWVALID", 1],
            ["MAXIGP1BREADY", 1],
            ["MAXIGP1RREADY", 1],
            ["MAXIGP1WDATA", 32],
            ["MAXIGP1WID", 12],
            ["MAXIGP1WLAST", 1],
            ["MAXIGP1WSTRB", 4],
            ["MAXIGP1WVALID", 1],
            ["SAXIACPARESETN", 1],
            ["SAXIACPARREADY", 1],
            ["SAXIACPAWREADY", 1],
            ["SAXIACPBID", 3],
            ["SAXIACPBRESP", 2],
            ["SAXIACPBVALID", 1],
            ["SAXIACPRDATA", 64],
            ["SAXIACPRID", 3],
            ["SAXIACPRLAST", 1],
            ["SAXIACPRRESP", 2],
            ["SAXIACPRVALID", 1],
            ["SAXIACPWREADY", 1],
            ["SAXIGP0ARESETN", 1],
            ["SAXIGP0ARREADY", 1],
            ["SAXIGP0AWREADY", 1],
            ["SAXIGP0BID", 6],
            ["SAXIGP0BRESP", 2],
            ["SAXIGP0BVALID", 1],
            ["SAXIGP0RDATA", 32],
            ["SAXIGP0RID", 6],
            ["SAXIGP0RLAST", 1],
            ["SAXIGP0RRESP", 2],
            ["SAXIGP0RVALID", 1],
            ["SAXIGP0WREADY", 1],
            ["SAXIGP1ARESETN", 1],
            ["SAXIGP1ARREADY", 1],
            ["SAXIGP1AWREADY", 1],
            ["SAXIGP1BID", 6],
            ["SAXIGP1BRESP", 2],
            ["SAXIGP1BVALID", 1],
            ["SAXIGP1RDATA", 32],
            ["SAXIGP1RID", 6],
            ["SAXIGP1RLAST", 1],
            ["SAXIGP1RRESP", 2],
            ["SAXIGP1RVALID", 1],
            ["SAXIGP1WREADY", 1],
            ["SAXIHP0ARESETN", 1],
            ["SAXIHP0ARREADY", 1],
            ["SAXIHP0AWREADY", 1],
            ["SAXIHP0BID", 6],
            ["SAXIHP0BRESP", 2],
            ["SAXIHP0BVALID", 1],
            ["SAXIHP0RACOUNT", 3],
            ["SAXIHP0RCOUNT", 8],
            ["SAXIHP0RDATA", 64],
            ["SAXIHP0RID", 6],
            ["SAXIHP0RLAST", 1],
            ["SAXIHP0RRESP", 2],
            ["SAXIHP0RVALID", 1],
            ["SAXIHP0WACOUNT", 6],
            ["SAXIHP0WCOUNT", 8],
            ["SAXIHP0WREADY", 1],
            ["SAXIHP1ARESETN", 1],
            ["SAXIHP1ARREADY", 1],
            ["SAXIHP1AWREADY", 1],
            ["SAXIHP1BID", 6],
            ["SAXIHP1BRESP", 2],
            ["SAXIHP1BVALID", 1],
            ["SAXIHP1RACOUNT", 3],
            ["SAXIHP1RCOUNT", 8],
            ["SAXIHP1RDATA", 64],
            ["SAXIHP1RID", 6],
            ["SAXIHP1RLAST", 1],
            ["SAXIHP1RRESP", 2],
            ["SAXIHP1RVALID", 1],
            ["SAXIHP1WACOUNT", 6],
            ["SAXIHP1WCOUNT", 8],
            ["SAXIHP1WREADY", 1],
            ["SAXIHP2ARESETN", 1],
            ["SAXIHP2ARREADY", 1],
            ["SAXIHP2AWREADY", 1],
            ["SAXIHP2BID", 6],
            ["SAXIHP2BRESP", 2],
            ["SAXIHP2BVALID", 1],
            ["SAXIHP2RACOUNT", 3],
            ["SAXIHP2RCOUNT", 8],
            ["SAXIHP2RDATA", 64],
            ["SAXIHP2RID", 6],
            ["SAXIHP2RLAST", 1],
            ["SAXIHP2RRESP", 2],
            ["SAXIHP2RVALID", 1],
            ["SAXIHP2WACOUNT", 6],
            ["SAXIHP2WCOUNT", 8],
            ["SAXIHP2WREADY", 1],
            ["SAXIHP3ARESETN", 1],
            ["SAXIHP3ARREADY", 1],
            ["SAXIHP3AWREADY", 1],
            ["SAXIHP3BID", 6],
            ["SAXIHP3BRESP", 2],
            ["SAXIHP3BVALID", 1],
            ["SAXIHP3RACOUNT", 3],
            ["SAXIHP3RCOUNT", 8],
            ["SAXIHP3RDATA", 64],
            ["SAXIHP3RID", 6],
            ["SAXIHP3RLAST", 1],
            ["SAXIHP3RRESP", 2],
            ["SAXIHP3RVALID", 1],
            ["SAXIHP3WACOUNT", 6],
            ["SAXIHP3WCOUNT", 8],
            ["SAXIHP3WREADY", 1],
        ],
}

# =============================================================================


def expand_ps_sink(
        conn, c, sink_wire_pkey, source_to_sink_pip_map, check_for_default
):
    """
    Expand a PS7 site sink. Returns pkey of the upstream wire of the first
    encountered active PIP. Returns None if no active PIP is found.
    """

    # Get node pkey
    sink_node_pkey = get_node_pkey(conn, sink_wire_pkey)

    # Check for an acitve PIP
    for node_wire_pkey in get_wires_in_node(conn, sink_node_pkey):

        # Got an active PIP, the sink is connected.
        if node_wire_pkey in source_to_sink_pip_map:
            upstream_sink_wire_pkey = source_to_sink_pip_map[node_wire_pkey]
            return upstream_sink_wire_pkey

    # No active PIPs to move upstream, find a PPIP upstream.
    for node_wire_pkey in get_wires_in_node(conn, sink_node_pkey):
        c.execute(
            "SELECT phy_tile_pkey, wire_in_tile_pkey FROM wire WHERE pkey = ?;",
            (node_wire_pkey, )
        )
        phy_tile_pkey, wire_in_tile_pkey = c.fetchone()
        upstream_sink_wire_in_tile_pkey = check_for_default(wire_in_tile_pkey)

        # Got a PPIP, move upstream.
        if upstream_sink_wire_in_tile_pkey is not None:
            c.execute(
                "SELECT pkey FROM wire WHERE wire_in_tile_pkey = ? AND phy_tile_pkey = ?;",
                (
                    upstream_sink_wire_in_tile_pkey,
                    phy_tile_pkey,
                )
            )
            upstream_sink_wire_pkey = c.fetchone()[0]

            if DEBUG:
                print(upstream_sink_wire_pkey, "", end='')

            # Recurse
            return expand_ps_sink(
                conn=conn,
                c=c,
                sink_wire_pkey=upstream_sink_wire_pkey,
                source_to_sink_pip_map=source_to_sink_pip_map,
                check_for_default=check_for_default
            )

    # No active PIP and PPIP, the sink is unconnected.
    return None


def check_for_active_ps_sinks(conn, db, active_pips, tile, site):
    """
    Loops over all PS7 inpus pins and checks if any of them is connected to
    the PL through an active PIP. Returns True when at least one is, False
    otherwise.
    """

    if DEBUG:
        print("Checking PS7 active sinks...")

    # Build source to sink map
    source_to_sink_pip_map = {}

    for sink_wire_pkey, source_wire_pkey in active_pips:
        assert source_wire_pkey not in source_to_sink_pip_map
        source_to_sink_pip_map[source_wire_pkey] = sink_wire_pkey

    # Create PPIP checker.
    check_for_default = create_check_for_default(db, conn)

    # Identify sinks
    sinks = []
    for signal, width in PS7_PINS["input"]:
        if width == 1:
            sinks.append(signal)
        else:
            for i in range(width):
                sinks.append("{}{}".format(signal, i))

    prefix = site.type
    wires = [prefix + "_" + s for s in sinks]

    # Expand each wire sink upstream until an active PIP is found.
    cur = conn.cursor()
    wire_pkeys = [get_wire_pkey(conn, tile, w) for w in wires]
    for wire, wire_pkey in zip(wires, wire_pkeys):

        if DEBUG:
            print("//", wire, "", end='')

        # Check if it is connected to anything. If it is so then return True,
        # there is no need to check further.
        pkey = expand_ps_sink(
            conn=conn,
            c=cur,
            sink_wire_pkey=wire_pkey,
            source_to_sink_pip_map=source_to_sink_pip_map,
            check_for_default=check_for_default
        )

        if DEBUG:
            print(pkey)

        if pkey is not None:
            return True

    # None of PS sinks is connected.
    return False


# =============================================================================


def expand_ps_source(
        conn, c, source_wire_pkey, sink_to_source_pip_map, check_for_default
):
    """
    Expands a PS source. Returns a set of pkeys of sink wires of found active
    PIPs. Returns None if no active PIP is found.
    """
    source_node_pkey = get_node_pkey(conn, source_wire_pkey)

    # Check for an acitve PIP
    for node_wire_pkey in get_wires_in_node(conn, source_node_pkey):

        # Got an active PIP, the sink is connected.
        if node_wire_pkey in sink_to_source_pip_map:
            upstream_sink_wire_pkeys = sink_to_source_pip_map[node_wire_pkey]
            return upstream_sink_wire_pkeys

    # No active PIPs to move downstream, find a PPIP downstream.
    for wire_pkey in get_wires_in_node(conn, source_node_pkey):
        c.execute(
            "SELECT phy_tile_pkey, wire_in_tile_pkey FROM wire WHERE pkey = ?",
            (wire_pkey, )
        )
        phy_tile_pkey, wire_in_tile_pkey = c.fetchone()
        downstream_wire_in_tile_pkey = check_for_default(wire_in_tile_pkey)

        # Got a PPIP, move downstream
        if downstream_wire_in_tile_pkey is not None:
            c.execute(
                "SELECT pkey FROM wire WHERE phy_tile_pkey = ? AND wire_in_tile_pkey = ?",
                (
                    phy_tile_pkey,
                    downstream_wire_in_tile_pkey,
                )
            )
            downstream_wire_pkey = c.fetchone()[0]

            if DEBUG:
                print(downstream_wire_pkey, "", end='')

            # Recurse
            return expand_ps_source(
                conn=conn,
                c=c,
                source_wire_pkey=downstream_wire_pkey,
                sink_to_source_pip_map=sink_to_source_pip_map,
                check_for_default=check_for_default
            )

    # No active PIP and PPIP, the source is unconnected.
    return None


def check_for_active_ps_sources(conn, db, active_pips, tile, site):
    """
    Loops over all PS7 output pins and checks if any of them is connected to
    the PL through an active PIP. Returns True when at least one is, False
    otherwise.
    """

    if DEBUG:
        print("Checking for active PS7 sources...")

    # Build sink to source PIP map
    sink_to_source_pip_map = defaultdict(lambda: set())

    for sink_wire_pkey, source_wire_pkey in active_pips:
        sink_to_source_pip_map[sink_wire_pkey].add(source_wire_pkey)

    # Create PPIP checker.
    check_for_default = create_check_downstream_default(conn, db)

    # Identify sources
    sources = []
    for signal, width in PS7_PINS["output"]:
        if width == 1:
            sources.append(signal)
        else:
            for i in range(width):
                sources.append("{}{}".format(signal, i))

    prefix = site.type
    wires = [prefix + "_" + s for s in sources]

    # Expand each wire source upstream until an active PIP is found.
    cur = conn.cursor()
    wire_pkeys = [get_wire_pkey(conn, tile, w) for w in wires]
    for wire, wire_pkey in zip(wires, wire_pkeys):

        if DEBUG:
            print("//", wire, "", end='')

        # Check if it is connected to anything. If it is so then return True,
        # there is no need to check further.
        pkeys = expand_ps_source(
            conn=conn,
            c=cur,
            source_wire_pkey=wire_pkey,
            sink_to_source_pip_map=sink_to_source_pip_map,
            check_for_default=check_for_default
        )

        if DEBUG:
            print(pkeys)

        if pkeys is not None:
            return True

    # None of PS sources is connected.
    return False


# =============================================================================


def check_ps7_connection(conn, db, active_pips, tile, site):
    """
    Checks whether the PS7 is connected to the PL through any active PIP.
    """

    # Check for active sinks and sources on the PS7
    got_active_sinks = check_for_active_ps_sinks(
        conn, db, active_pips, tile, site
    )

    got_active_sources = check_for_active_ps_sources(
        conn, db, active_pips, tile, site
    )

    return got_active_sinks or got_active_sources


# =============================================================================


def get_ps7_site(db):
    """
    Looks for tile and site that contains the PS7 in the tilegrid.
    """

    # Check if there are any PSS tiles. If not then there is no PS7
    pss_tiles = [t for t in db.get_tile_types() if t.startswith("PSS")]
    if len(pss_tiles) == 0:
        return None, None

    # Loop over the gird and find the PS7
    grid = db.grid()
    for tile_name in grid.tiles():
        if tile_name.startswith("PSS"):
            gridinfo = grid.gridinfo_at_tilename(tile_name)

            tile_type = db.get_tile_type(gridinfo.tile_type)
            sites = tile_type.get_instance_sites(gridinfo)
            sites = [s for s in sites if s.type == "PS7"]

            if len(sites) > 0:
                return tile_name, sites[0]

    # No PS7 found
    return None, None


def insert_ps7(top, pss_tile, ps7_site):
    """
    Adds the PS7 instance to the design
    """

    # Add the site+bel
    site = Site(None, ps7_site, pss_tile)
    bel = Bel("PS7")

    # Add sources
    for signal, width in PS7_PINS["output"]:
        if width == 1:
            site.add_source(bel, signal, signal)
        else:
            for i in range(width):
                site.add_source(
                    bel, "{}[{}]".format(signal, i), "{}{}".format(signal, i)
                )

    # Add sinks
    for signal, width in PS7_PINS["input"]:
        if width == 1:
            site.add_sink(bel, signal, signal)
        else:
            for i in range(width):
                site.add_sink(
                    bel, "{}[{}]".format(signal, i), "{}{}".format(signal, i)
                )

    # Add everything
    site.add_bel(bel)
    top.add_site(site)
