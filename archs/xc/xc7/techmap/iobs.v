module IBUF (
  (* iopad_external_pin *)
  input  I,
  output O
);

  parameter IOSTANDARD   = "default";
  parameter IBUF_LOW_PWR = 0;
  parameter IN_TERM = "NONE";  // Not supported by Vivado ?
  parameter IO_LOC_PAIRS = ""; // Used by read_xdc.

  assign O = I;
  specify
    (I => O) = 0;
  endspecify

endmodule

module OBUF (
  input  I,
  (* iopad_external_pin *)
  output O
);

  parameter IOSTANDARD   = "default";
  parameter DRIVE        = 12;
  parameter SLEW         = "SLOW";
  parameter IO_LOC_PAIRS = ""; // Used by read_xdc.

  assign O = I;
  specify
    (I => O) = 0;
  endspecify

endmodule

module SYN_OBUF(
    input I,
    (* iopad_external_pin *)
    output O);
  assign O = I;
endmodule

module SYN_IBUF(
    output O,
    (* iopad_external_pin *)
    input I);
  assign O = I;
endmodule

module OBUFDS (
  input  I,
  (* iopad_external_pin *)
  output O,
  (* iopad_external_pin *)
  output OB
);

  parameter IOSTANDARD  = "DEFAULT";
  parameter SLEW        = "SLOW";
  parameter PULLTYPE    = "NONE";
  parameter IO_LOC_PAIRS = ""; // Used by read_xdc.
  parameter HAS_OSERDES = 0;

  assign O  =  I;
  assign OB = ~I;

endmodule

module OBUFTDS (
  input  I,
  input  T,
  (* iopad_external_pin *)
  output O,
  (* iopad_external_pin *)
  output OB
);

  parameter IOSTANDARD  = "DEFAULT";
  parameter SLEW        = "SLOW";
  parameter PULLTYPE    = "NONE";
  parameter IO_LOC_PAIRS = ""; // Used by read_xdc.
  parameter HAS_OSERDES = 0;

  assign O  = (T == 1'b0) ?  I : 1'bz;
  assign OB = (T == 1'b0) ? ~I : 1'bz;

endmodule

module IOBUF (
  (* iopad_external_pin *)
  inout IO,
  output O,
  input I,
  input T
);

  parameter IOSTANDARD   = "default";
  parameter DRIVE        = 12;
  parameter SLEW         = "SLOW";
  parameter IBUF_LOW_PWR = 0;
  parameter IN_TERM = "NONE";  // Not supported by Vivado ?
  parameter IO_LOC_PAIRS = ""; // Used by read_xdc.

  assign IO = T ? 1'bz : I;
  assign O = IO;
  specify
    (I => IO) = 0;
    (IO => O) = 0;
  endspecify

endmodule

module OBUFT (
    (* iopad_external_pin *)
    output O,
    input I,
    input T
);
    parameter CAPACITANCE = "DONT_CARE";
    parameter DRIVE = 12;
    parameter IOSTANDARD = "DEFAULT";
    parameter SLEW = "SLOW";
    parameter IO_LOC_PAIRS = ""; // Used by read_xdc.
    assign O = T ? 1'bz : I;
    specify
        (I => O) = 0;
    endspecify
endmodule

module IOBUFDS (
  input  I,
  input  T,
  output O,
    (* iopad_external_pin *)
  inout  IO,
    (* iopad_external_pin *)
  inout  IOB
);
  parameter IOSTANDARD = "DIFF_SSTL135";  // TODO: Is this the default ?
  parameter SLEW = "SLOW";
  parameter IN_TERM = "NONE";  // Not supported by Vivado ?
  parameter PULLTYPE = "NONE"; // Not supported by Vivado ?
  parameter IO_LOC_PAIRS = ""; // Used by read_xdc.
endmodule

module IBUFDS_GTE2 (
  output O,
  output ODIV2,
  input CEB,
    (* iopad_external_pin *)
  input I,
    (* iopad_external_pin *)
  input IB
  );
  parameter IO_LOC_PAIRS = ""; // Used by read_xdc.
endmodule

module GTPE2_CHANNEL (
    (* iopad_external_pin *)
    output GTPTXN,
    (* iopad_external_pin *)
    output GTPTXP,
    (* iopad_external_pin *)
    input GTPRXN,
    (* iopad_external_pin *)
    input GTPRXP,
    output DRPRDY,
    output EYESCANDATAERROR,
    output PHYSTATUS,
    output PMARSVDOUT0,
    output PMARSVDOUT1,
    output RXBYTEISALIGNED,
    output RXBYTEREALIGN,
    output RXCDRLOCK,
    output RXCHANBONDSEQ,
    output RXCHANISALIGNED,
    output RXCHANREALIGN,
    output RXCOMINITDET,
    output RXCOMMADET,
    output RXCOMSASDET,
    output RXCOMWAKEDET,
    output RXDLYSRESETDONE,
    output RXELECIDLE,
    output RXHEADERVALID,
    output RXOSINTDONE,
    output RXOSINTSTARTED,
    output RXOSINTSTROBEDONE,
    output RXOSINTSTROBESTARTED,
    output RXOUTCLK,
    output RXOUTCLKFABRIC,
    output RXOUTCLKPCS,
    output RXPHALIGNDONE,
    output RXPMARESETDONE,
    output RXPRBSERR,
    output RXRATEDONE,
    output RXRESETDONE,
    output RXSYNCDONE,
    output RXSYNCOUT,
    output RXVALID,
    output TXCOMFINISH,
    output TXDLYSRESETDONE,
    output TXGEARBOXREADY,
    output TXOUTCLK,
    output TXOUTCLKFABRIC,
    output TXOUTCLKPCS,
    output TXPHALIGNDONE,
    output TXPHINITDONE,
    output TXPMARESETDONE,
    output TXRATEDONE,
    output TXRESETDONE,
    output TXSYNCDONE,
    output TXSYNCOUT,
    output [14:0] DMONITOROUT,
    output [15:0] DRPDO,
    output [15:0] PCSRSVDOUT,
    output [1:0] RXCLKCORCNT,
    output [1:0] RXDATAVALID,
    output [1:0] RXSTARTOFSEQ,
    output [1:0] TXBUFSTATUS,
    output [2:0] RXBUFSTATUS,
    output [2:0] RXHEADER,
    output [2:0] RXSTATUS,
    output [31:0] RXDATA,
    output [3:0] RXCHARISCOMMA,
    output [3:0] RXCHARISK,
    output [3:0] RXCHBONDO,
    output [3:0] RXDISPERR,
    output [3:0] RXNOTINTABLE,
    output [4:0] RXPHMONITOR,
    output [4:0] RXPHSLIPMONITOR,
    input CFGRESET,
    (* invertible_pin = "IS_CLKRSVD0_INVERTED" *)
    input CLKRSVD0,
    (* invertible_pin = "IS_CLKRSVD1_INVERTED" *)
    input CLKRSVD1,
    input DMONFIFORESET,
    (* invertible_pin = "IS_DMONITORCLK_INVERTED" *)
    input DMONITORCLK,
    (* invertible_pin = "IS_DRPCLK_INVERTED" *)
    input DRPCLK,
    input DRPEN,
    input DRPWE,
    input EYESCANMODE,
    input EYESCANRESET,
    input EYESCANTRIGGER,
    input GTRESETSEL,
    input GTRXRESET,
    input GTTXRESET,
    input PLL0CLK,
    input PLL0REFCLK,
    input PLL1CLK,
    input PLL1REFCLK,
    input PMARSVDIN0,
    input PMARSVDIN1,
    input PMARSVDIN2,
    input PMARSVDIN3,
    input PMARSVDIN4,
    input RESETOVRD,
    input RX8B10BEN,
    input RXBUFRESET,
    input RXCDRFREQRESET,
    input RXCDRHOLD,
    input RXCDROVRDEN,
    input RXCDRRESET,
    input RXCDRRESETRSV,
    input RXCHBONDEN,
    input RXCHBONDMASTER,
    input RXCHBONDSLAVE,
    input RXCOMMADETEN,
    input RXDDIEN,
    input RXDFEXYDEN,
    input RXDLYBYPASS,
    input RXDLYEN,
    input RXDLYOVRDEN,
    input RXDLYSRESET,
    input RXGEARBOXSLIP,
    input RXLPMHFHOLD,
    input RXLPMHFOVRDEN,
    input RXLPMLFHOLD,
    input RXLPMLFOVRDEN,
    input RXLPMOSINTNTRLEN,
    input RXLPMRESET,
    input RXMCOMMAALIGNEN,
    input RXOOBRESET,
    input RXOSCALRESET,
    input RXOSHOLD,
    input RXOSINTEN,
    input RXOSINTHOLD,
    input RXOSINTNTRLEN,
    input RXOSINTOVRDEN,
    input RXOSINTPD,
    input RXOSINTSTROBE,
    input RXOSINTTESTOVRDEN,
    input RXOSOVRDEN,
    input RXPCOMMAALIGNEN,
    input RXPCSRESET,
    input RXPHALIGN,
    input RXPHALIGNEN,
    input RXPHDLYPD,
    input RXPHDLYRESET,
    input RXPHOVRDEN,
    input RXPMARESET,
    input RXPOLARITY,
    input RXPRBSCNTRESET,
    input RXRATEMODE,
    input RXSLIDE,
    input RXSYNCALLIN,
    input RXSYNCIN,
    input RXSYNCMODE,
    input RXUSERRDY,
    (* invertible_pin = "IS_RXUSRCLK2_INVERTED" *)
    input RXUSRCLK2,
    (* invertible_pin = "IS_RXUSRCLK_INVERTED" *)
    input RXUSRCLK,
    input SETERRSTATUS,
    (* invertible_pin = "IS_SIGVALIDCLK_INVERTED" *)
    input SIGVALIDCLK,
    input TX8B10BEN,
    input TXCOMINIT,
    input TXCOMSAS,
    input TXCOMWAKE,
    input TXDEEMPH,
    input TXDETECTRX,
    input TXDIFFPD,
    input TXDLYBYPASS,
    input TXDLYEN,
    input TXDLYHOLD,
    input TXDLYOVRDEN,
    input TXDLYSRESET,
    input TXDLYUPDOWN,
    input TXELECIDLE,
    input TXINHIBIT,
    input TXPCSRESET,
    input TXPDELECIDLEMODE,
    input TXPHALIGN,
    input TXPHALIGNEN,
    input TXPHDLYPD,
    input TXPHDLYRESET,
    (* invertible_pin = "IS_TXPHDLYTSTCLK_INVERTED" *)
    input TXPHDLYTSTCLK,
    input TXPHINIT,
    input TXPHOVRDEN,
    input TXPIPPMEN,
    input TXPIPPMOVRDEN,
    input TXPIPPMPD,
    input TXPIPPMSEL,
    input TXPISOPD,
    input TXPMARESET,
    input TXPOLARITY,
    input TXPOSTCURSORINV,
    input TXPRBSFORCEERR,
    input TXPRECURSORINV,
    input TXRATEMODE,
    input TXSTARTSEQ,
    input TXSWING,
    input TXSYNCALLIN,
    input TXSYNCIN,
    input TXSYNCMODE,
    input TXUSERRDY,
    (* invertible_pin = "IS_TXUSRCLK2_INVERTED" *)
    input TXUSRCLK2,
    (* invertible_pin = "IS_TXUSRCLK_INVERTED" *)
    input TXUSRCLK,
    input [13:0] RXADAPTSELTEST,
    input [15:0] DRPDI,
    input [15:0] GTRSVD,
    input [15:0] PCSRSVDIN,
    input [19:0] TSTIN,
    input [1:0] RXELECIDLEMODE,
    input [1:0] RXPD,
    input [1:0] RXSYSCLKSEL,
    input [1:0] TXPD,
    input [1:0] TXSYSCLKSEL,
    input [2:0] LOOPBACK,
    input [2:0] RXCHBONDLEVEL,
    input [2:0] RXOUTCLKSEL,
    input [2:0] RXPRBSSEL,
    input [2:0] RXRATE,
    input [2:0] TXBUFDIFFCTRL,
    input [2:0] TXHEADER,
    input [2:0] TXMARGIN,
    input [2:0] TXOUTCLKSEL,
    input [2:0] TXPRBSSEL,
    input [2:0] TXRATE,
    input [31:0] TXDATA,
    input [3:0] RXCHBONDI,
    input [3:0] RXOSINTCFG,
    input [3:0] RXOSINTID0,
    input [3:0] TX8B10BBYPASS,
    input [3:0] TXCHARDISPMODE,
    input [3:0] TXCHARDISPVAL,
    input [3:0] TXCHARISK,
    input [3:0] TXDIFFCTRL,
    input [4:0] TXPIPPMSTEPSIZE,
    input [4:0] TXPOSTCURSOR,
    input [4:0] TXPRECURSOR,
    input [6:0] TXMAINCURSOR,
    input [6:0] TXSEQUENCE,
    input [8:0] DRPADDR
);

    parameter [0:0] ACJTAG_DEBUG_MODE = 1'b0;
    parameter [0:0] ACJTAG_MODE = 1'b0;
    parameter [0:0] ACJTAG_RESET = 1'b0;
    parameter [19:0] ADAPT_CFG0 = 20'b00000000000000000000;
    parameter ALIGN_COMMA_DOUBLE = "FALSE";
    parameter [9:0] ALIGN_COMMA_ENABLE = 10'b0001111111;
    parameter integer ALIGN_COMMA_WORD = 1;
    parameter ALIGN_MCOMMA_DET = "TRUE";
    parameter [9:0] ALIGN_MCOMMA_VALUE = 10'b1010000011;
    parameter ALIGN_PCOMMA_DET = "TRUE";
    parameter [9:0] ALIGN_PCOMMA_VALUE = 10'b0101111100;
    parameter CBCC_DATA_SOURCE_SEL = "DECODED";
    parameter [42:0] CFOK_CFG = 43'b1001001000000000000000001000000111010000000;
    parameter [6:0] CFOK_CFG2 = 7'b0100000;
    parameter [6:0] CFOK_CFG3 = 7'b0100000;
    parameter [0:0] CFOK_CFG4 = 1'b0;
    parameter [1:0] CFOK_CFG5 = 2'b00;
    parameter [3:0] CFOK_CFG6 = 4'b0000;
    parameter CHAN_BOND_KEEP_ALIGN = "FALSE";
    parameter integer CHAN_BOND_MAX_SKEW = 7;
    parameter [9:0] CHAN_BOND_SEQ_1_1 = 10'b0101111100;
    parameter [9:0] CHAN_BOND_SEQ_1_2 = 10'b0000000000;
    parameter [9:0] CHAN_BOND_SEQ_1_3 = 10'b0000000000;
    parameter [9:0] CHAN_BOND_SEQ_1_4 = 10'b0000000000;
    parameter [3:0] CHAN_BOND_SEQ_1_ENABLE = 4'b1111;
    parameter [9:0] CHAN_BOND_SEQ_2_1 = 10'b0100000000;
    parameter [9:0] CHAN_BOND_SEQ_2_2 = 10'b0100000000;
    parameter [9:0] CHAN_BOND_SEQ_2_3 = 10'b0100000000;
    parameter [9:0] CHAN_BOND_SEQ_2_4 = 10'b0100000000;
    parameter [3:0] CHAN_BOND_SEQ_2_ENABLE = 4'b1111;
    parameter CHAN_BOND_SEQ_2_USE = "FALSE";
    parameter integer CHAN_BOND_SEQ_LEN = 1;
    parameter [0:0] CLK_COMMON_SWING = 1'b0;
    parameter CLK_CORRECT_USE = "TRUE";
    parameter CLK_COR_KEEP_IDLE = "FALSE";
    parameter integer CLK_COR_MAX_LAT = 20;
    parameter integer CLK_COR_MIN_LAT = 18;
    parameter CLK_COR_PRECEDENCE = "TRUE";
    parameter integer CLK_COR_REPEAT_WAIT = 0;
    parameter [9:0] CLK_COR_SEQ_1_1 = 10'b0100011100;
    parameter [9:0] CLK_COR_SEQ_1_2 = 10'b0000000000;
    parameter [9:0] CLK_COR_SEQ_1_3 = 10'b0000000000;
    parameter [9:0] CLK_COR_SEQ_1_4 = 10'b0000000000;
    parameter [3:0] CLK_COR_SEQ_1_ENABLE = 4'b1111;
    parameter [9:0] CLK_COR_SEQ_2_1 = 10'b0100000000;
    parameter [9:0] CLK_COR_SEQ_2_2 = 10'b0100000000;
    parameter [9:0] CLK_COR_SEQ_2_3 = 10'b0100000000;
    parameter [9:0] CLK_COR_SEQ_2_4 = 10'b0100000000;
    parameter [3:0] CLK_COR_SEQ_2_ENABLE = 4'b1111;
    parameter CLK_COR_SEQ_2_USE = "FALSE";
    parameter integer CLK_COR_SEQ_LEN = 1;
    parameter DEC_MCOMMA_DETECT = "TRUE";
    parameter DEC_PCOMMA_DETECT = "TRUE";
    parameter DEC_VALID_COMMA_ONLY = "TRUE";
    parameter [23:0] DMONITOR_CFG = 24'h000A00;
    parameter [0:0] ES_CLK_PHASE_SEL = 1'b0;
    parameter [5:0] ES_CONTROL = 6'b000000;
    parameter ES_ERRDET_EN = "FALSE";
    parameter ES_EYE_SCAN_EN = "FALSE";
    parameter [11:0] ES_HORZ_OFFSET = 12'h010;
    parameter [9:0] ES_PMA_CFG = 10'b0000000000;
    parameter [4:0] ES_PRESCALE = 5'b00000;
    parameter [79:0] ES_QUALIFIER = 80'h00000000000000000000;
    parameter [79:0] ES_QUAL_MASK = 80'h00000000000000000000;
    parameter [79:0] ES_SDATA_MASK = 80'h00000000000000000000;
    parameter [8:0] ES_VERT_OFFSET = 9'b000000000;
    parameter [3:0] FTS_DESKEW_SEQ_ENABLE = 4'b1111;
    parameter [3:0] FTS_LANE_DESKEW_CFG = 4'b1111;
    parameter FTS_LANE_DESKEW_EN = "FALSE";
    parameter [2:0] GEARBOX_MODE = 3'b000;
    parameter [0:0] IS_CLKRSVD0_INVERTED = 1'b0;
    parameter [0:0] IS_CLKRSVD1_INVERTED = 1'b0;
    parameter [0:0] IS_DMONITORCLK_INVERTED = 1'b0;
    parameter [0:0] IS_DRPCLK_INVERTED = 1'b0;
    parameter [0:0] IS_RXUSRCLK2_INVERTED = 1'b0;
    parameter [0:0] IS_RXUSRCLK_INVERTED = 1'b0;
    parameter [0:0] IS_SIGVALIDCLK_INVERTED = 1'b0;
    parameter [0:0] IS_TXPHDLYTSTCLK_INVERTED = 1'b0;
    parameter [0:0] IS_TXUSRCLK2_INVERTED = 1'b0;
    parameter [0:0] IS_TXUSRCLK_INVERTED = 1'b0;
    parameter [0:0] LOOPBACK_CFG = 1'b0;
    parameter [1:0] OUTREFCLK_SEL_INV = 2'b11;
    parameter PCS_PCIE_EN = "FALSE";
    parameter [47:0] PCS_RSVD_ATTR = 48'h000000000000;
    parameter [11:0] PD_TRANS_TIME_FROM_P2 = 12'h03C;
    parameter [7:0] PD_TRANS_TIME_NONE_P2 = 8'h19;
    parameter [7:0] PD_TRANS_TIME_TO_P2 = 8'h64;
    parameter [0:0] PMA_LOOPBACK_CFG = 1'b0;
    parameter [31:0] PMA_RSV = 32'h00000333;
    parameter [31:0] PMA_RSV2 = 32'h00002050;
    parameter [1:0] PMA_RSV3 = 2'b00;
    parameter [3:0] PMA_RSV4 = 4'b0000;
    parameter [0:0] PMA_RSV5 = 1'b0;
    parameter [0:0] PMA_RSV6 = 1'b0;
    parameter [0:0] PMA_RSV7 = 1'b0;
    parameter [4:0] RXBUFRESET_TIME = 5'b00001;
    parameter RXBUF_ADDR_MODE = "FULL";
    parameter [3:0] RXBUF_EIDLE_HI_CNT = 4'b1000;
    parameter [3:0] RXBUF_EIDLE_LO_CNT = 4'b0000;
    parameter RXBUF_EN = "TRUE";
    parameter RXBUF_RESET_ON_CB_CHANGE = "TRUE";
    parameter RXBUF_RESET_ON_COMMAALIGN = "FALSE";
    parameter RXBUF_RESET_ON_EIDLE = "FALSE";
    parameter RXBUF_RESET_ON_RATE_CHANGE = "TRUE";
    parameter integer RXBUF_THRESH_OVFLW = 61;
    parameter RXBUF_THRESH_OVRD = "FALSE";
    parameter integer RXBUF_THRESH_UNDFLW = 4;
    parameter [4:0] RXCDRFREQRESET_TIME = 5'b00001;
    parameter [4:0] RXCDRPHRESET_TIME = 5'b00001;
    parameter [82:0] RXCDR_CFG = 83'h0000107FE406001041010;
    parameter [0:0] RXCDR_FR_RESET_ON_EIDLE = 1'b0;
    parameter [0:0] RXCDR_HOLD_DURING_EIDLE = 1'b0;
    parameter [5:0] RXCDR_LOCK_CFG = 6'b001001;
    parameter [0:0] RXCDR_PH_RESET_ON_EIDLE = 1'b0;
    parameter [15:0] RXDLY_CFG = 16'h0010;
    parameter [8:0] RXDLY_LCFG = 9'h020;
    parameter [15:0] RXDLY_TAP_CFG = 16'h0000;
    parameter RXGEARBOX_EN = "FALSE";
    parameter [4:0] RXISCANRESET_TIME = 5'b00001;
    parameter [6:0] RXLPMRESET_TIME = 7'b0001111;
    parameter [0:0] RXLPM_BIAS_STARTUP_DISABLE = 1'b0;
    parameter [3:0] RXLPM_CFG = 4'b0110;
    parameter [0:0] RXLPM_CFG1 = 1'b0;
    parameter [0:0] RXLPM_CM_CFG = 1'b0;
    parameter [8:0] RXLPM_GC_CFG = 9'b111100010;
    parameter [2:0] RXLPM_GC_CFG2 = 3'b001;
    parameter [13:0] RXLPM_HF_CFG = 14'b00001111110000;
    parameter [4:0] RXLPM_HF_CFG2 = 5'b01010;
    parameter [3:0] RXLPM_HF_CFG3 = 4'b0000;
    parameter [0:0] RXLPM_HOLD_DURING_EIDLE = 1'b0;
    parameter [0:0] RXLPM_INCM_CFG = 1'b0;
    parameter [0:0] RXLPM_IPCM_CFG = 1'b0;
    parameter [17:0] RXLPM_LF_CFG = 18'b000000001111110000;
    parameter [4:0] RXLPM_LF_CFG2 = 5'b01010;
    parameter [2:0] RXLPM_OSINT_CFG = 3'b100;
    parameter [6:0] RXOOB_CFG = 7'b0000110;
    parameter RXOOB_CLK_CFG = "PMA";
    parameter [4:0] RXOSCALRESET_TIME = 5'b00011;
    parameter [4:0] RXOSCALRESET_TIMEOUT = 5'b00000;
    parameter integer RXOUT_DIV = 2;
    parameter [4:0] RXPCSRESET_TIME = 5'b00001;
    parameter [23:0] RXPHDLY_CFG = 24'h084000;
    parameter [23:0] RXPH_CFG = 24'hC00002;
    parameter [4:0] RXPH_MONITOR_SEL = 5'b00000;
    parameter [2:0] RXPI_CFG0 = 3'b000;
    parameter [0:0] RXPI_CFG1 = 1'b0;
    parameter [0:0] RXPI_CFG2 = 1'b0;
    parameter [4:0] RXPMARESET_TIME = 5'b00011;
    parameter [0:0] RXPRBS_ERR_LOOPBACK = 1'b0;
    parameter integer RXSLIDE_AUTO_WAIT = 7;
    parameter RXSLIDE_MODE = "OFF";
    parameter [0:0] RXSYNC_MULTILANE = 1'b0;
    parameter [0:0] RXSYNC_OVRD = 1'b0;
    parameter [0:0] RXSYNC_SKIP_DA = 1'b0;
    parameter [15:0] RX_BIAS_CFG = 16'b0000111100110011;
    parameter [5:0] RX_BUFFER_CFG = 6'b000000;
    parameter integer RX_CLK25_DIV = 7;
    parameter [0:0] RX_CLKMUX_EN = 1'b1;
    parameter [1:0] RX_CM_SEL = 2'b11;
    parameter [3:0] RX_CM_TRIM = 4'b0100;
    parameter integer RX_DATA_WIDTH = 20;
    parameter [5:0] RX_DDI_SEL = 6'b000000;
    parameter [13:0] RX_DEBUG_CFG = 14'b00000000000000;
    parameter RX_DEFER_RESET_BUF_EN = "TRUE";
    parameter RX_DISPERR_SEQ_MATCH = "TRUE";
    parameter [12:0] RX_OS_CFG = 13'b0001111110000;
    parameter integer RX_SIG_VALID_DLY = 10;
    parameter RX_XCLK_SEL = "RXREC";
    parameter integer SAS_MAX_COM = 64;
    parameter integer SAS_MIN_COM = 36;
    parameter [3:0] SATA_BURST_SEQ_LEN = 4'b1111;
    parameter [2:0] SATA_BURST_VAL = 3'b100;
    parameter [2:0] SATA_EIDLE_VAL = 3'b100;
    parameter integer SATA_MAX_BURST = 8;
    parameter integer SATA_MAX_INIT = 21;
    parameter integer SATA_MAX_WAKE = 7;
    parameter integer SATA_MIN_BURST = 4;
    parameter integer SATA_MIN_INIT = 12;
    parameter integer SATA_MIN_WAKE = 4;
    parameter SATA_PLL_CFG = "VCO_3000MHZ";
    parameter SHOW_REALIGN_COMMA = "TRUE";
    parameter SIM_RECEIVER_DETECT_PASS = "TRUE";
    parameter SIM_RESET_SPEEDUP = "TRUE";
    parameter SIM_TX_EIDLE_DRIVE_LEVEL = "X";
    parameter SIM_VERSION = "1.0";
    parameter [14:0] TERM_RCAL_CFG = 15'b100001000010000;
    parameter [2:0] TERM_RCAL_OVRD = 3'b000;
    parameter [7:0] TRANS_TIME_RATE = 8'h0E;
    parameter [31:0] TST_RSV = 32'h00000000;
    parameter TXBUF_EN = "TRUE";
    parameter TXBUF_RESET_ON_RATE_CHANGE = "FALSE";
    parameter [15:0] TXDLY_CFG = 16'h0010;
    parameter [8:0] TXDLY_LCFG = 9'h020;
    parameter [15:0] TXDLY_TAP_CFG = 16'h0000;
    parameter TXGEARBOX_EN = "FALSE";
    parameter [0:0] TXOOB_CFG = 1'b0;
    parameter integer TXOUT_DIV = 2;
    parameter [4:0] TXPCSRESET_TIME = 5'b00001;
    parameter [23:0] TXPHDLY_CFG = 24'h084000;
    parameter [15:0] TXPH_CFG = 16'h0400;
    parameter [4:0] TXPH_MONITOR_SEL = 5'b00000;
    parameter [1:0] TXPI_CFG0 = 2'b00;
    parameter [1:0] TXPI_CFG1 = 2'b00;
    parameter [1:0] TXPI_CFG2 = 2'b00;
    parameter [0:0] TXPI_CFG3 = 1'b0;
    parameter [0:0] TXPI_CFG4 = 1'b0;
    parameter [2:0] TXPI_CFG5 = 3'b000;
    parameter [0:0] TXPI_GREY_SEL = 1'b0;
    parameter [0:0] TXPI_INVSTROBE_SEL = 1'b0;
    parameter TXPI_PPMCLK_SEL = "TXUSRCLK2";
    parameter [7:0] TXPI_PPM_CFG = 8'b00000000;
    parameter [2:0] TXPI_SYNFREQ_PPM = 3'b000;
    parameter [4:0] TXPMARESET_TIME = 5'b00001;
    parameter [0:0] TXSYNC_MULTILANE = 1'b0;
    parameter [0:0] TXSYNC_OVRD = 1'b0;
    parameter [0:0] TXSYNC_SKIP_DA = 1'b0;
    parameter integer TX_CLK25_DIV = 7;
    parameter [0:0] TX_CLKMUX_EN = 1'b1;
    parameter integer TX_DATA_WIDTH = 20;
    parameter [5:0] TX_DEEMPH0 = 6'b000000;
    parameter [5:0] TX_DEEMPH1 = 6'b000000;
    parameter TX_DRIVE_MODE = "DIRECT";
    parameter [2:0] TX_EIDLE_ASSERT_DELAY = 3'b110;
    parameter [2:0] TX_EIDLE_DEASSERT_DELAY = 3'b100;
    parameter TX_LOOPBACK_DRIVE_HIZ = "FALSE";
    parameter [0:0] TX_MAINCURSOR_SEL = 1'b0;
    parameter [6:0] TX_MARGIN_FULL_0 = 7'b1001110;
    parameter [6:0] TX_MARGIN_FULL_1 = 7'b1001001;
    parameter [6:0] TX_MARGIN_FULL_2 = 7'b1000101;
    parameter [6:0] TX_MARGIN_FULL_3 = 7'b1000010;
    parameter [6:0] TX_MARGIN_FULL_4 = 7'b1000000;
    parameter [6:0] TX_MARGIN_LOW_0 = 7'b1000110;
    parameter [6:0] TX_MARGIN_LOW_1 = 7'b1000100;
    parameter [6:0] TX_MARGIN_LOW_2 = 7'b1000010;
    parameter [6:0] TX_MARGIN_LOW_3 = 7'b1000000;
    parameter [6:0] TX_MARGIN_LOW_4 = 7'b1000000;
    parameter [0:0] TX_PREDRIVER_MODE = 1'b0;
    parameter [13:0] TX_RXDETECT_CFG = 14'h1832;
    parameter [2:0] TX_RXDETECT_REF = 3'b100;
    parameter TX_XCLK_SEL = "TXUSR";
    parameter [0:0] UCODEER_CLR = 1'b0;
    parameter [0:0] USE_PCS_CLK_PHASE_SEL = 1'b0;
    parameter IO_LOC_PAIRS = ""; // Used by read_xdc
endmodule
