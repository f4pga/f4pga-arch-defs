module axiLiteSlave(input clk, input reset,
    input [4:0] io_s0_awaddr,
    input  io_s0_awvalid,
    output io_s0_awready,
    input [31:0] io_s0_wdata,
    input [3:0] io_s0_wstrb,
    input  io_s0_wvalid,
    output io_s0_wready,
    output[1:0] io_s0_bresp,
    output io_s0_bvalid,
    input  io_s0_bready,
    input [4:0] io_s0_araddr,
    output io_s0_arready,
    input  io_s0_arvalid,
    output[31:0] io_s0_rdata,
    output[1:0] io_s0_rresp,
    output io_s0_rvalid,
    input  io_s0_rready,
    output[31:0] io_outRegs_7,
    output[31:0] io_outRegs_6,
    output[31:0] io_outRegs_5,
    output[31:0] io_outRegs_4,
    output[31:0] io_outRegs_3,
    output[31:0] io_outRegs_2,
    output[31:0] io_outRegs_1,
    output[31:0] io_outRegs_0,
    input [31:0] io_inRegs_7,
    input [31:0] io_inRegs_6,
    input [31:0] io_inRegs_5,
    input [31:0] io_inRegs_4,
    input [31:0] io_inRegs_3,
    input [31:0] io_inRegs_2,
    input [31:0] io_inRegs_1,
    input [31:0] io_inRegs_0
);

  reg [31:0] outRegs_0;
  wire[31:0] T87;
  wire[31:0] T0;
  reg [31:0] writeValue;
  wire[31:0] T88;
  wire[31:0] T1;
  wire T2;
  wire T3;
  wire T4;
  wire T5;
  reg  writeAddressReady;
  wire T89;
  wire T6;
  wire T7;
  wire T8;
  wire T9;
  wire T10;
  wire T11;
  wire[7:0] T12;
  wire[2:0] T13;
  wire[2:0] T90;
  reg [7:0] writeRegNumber;
  wire[7:0] T91;
  wire[7:0] T14;
  wire[7:0] T92;
  wire[2:0] T15;
  wire T16;
  wire T17;
  reg  writeResponse;
  wire T93;
  wire T18;
  wire T19;
  wire T20;
  wire T21;
  wire T22;
  wire T23;
  wire T24;
  wire T25;
  wire T26;
  wire T27;
  wire T28;
  wire T29;
  reg [31:0] outRegs_1;
  wire[31:0] T94;
  wire[31:0] T30;
  wire T31;
  wire T32;
  reg [31:0] outRegs_2;
  wire[31:0] T95;
  wire[31:0] T33;
  wire T34;
  wire T35;
  reg [31:0] outRegs_3;
  wire[31:0] T96;
  wire[31:0] T36;
  wire T37;
  wire T38;
  reg [31:0] outRegs_4;
  wire[31:0] T97;
  wire[31:0] T39;
  wire T40;
  wire T41;
  reg [31:0] outRegs_5;
  wire[31:0] T98;
  wire[31:0] T42;
  wire T43;
  wire T44;
  reg [31:0] outRegs_6;
  wire[31:0] T99;
  wire[31:0] T45;
  wire T46;
  wire T47;
  reg [31:0] outRegs_7;
  wire[31:0] T100;
  wire[31:0] T48;
  wire T49;
  wire T50;
  reg  readReady;
  wire T101;
  wire T51;
  wire T52;
  wire T53;
  wire T54;
  wire T55;
  wire T56;
  wire T57;
  reg  readAddressReady;
  wire T102;
  wire T58;
  wire T59;
  wire T60;
  wire T61;
  wire T62;
  wire T63;
  wire T64;
  wire T65;
  wire T66;
  wire T67;
  wire T68;
  reg [31:0] readValue;
  wire[31:0] T103;
  wire[31:0] T69;
  wire[31:0] T70;
  wire[31:0] T71;
  wire[31:0] T72;
  reg [31:0] inRegs_0;
  wire[31:0] T104;
  reg [31:0] inRegs_1;
  wire[31:0] T105;
  wire T73;
  wire[2:0] T74;
  wire[2:0] T106;
  reg [7:0] readRegNumber;
  wire[7:0] T107;
  wire[7:0] T75;
  wire[7:0] T108;
  wire[2:0] T76;
  wire[31:0] T77;
  reg [31:0] inRegs_2;
  wire[31:0] T109;
  reg [31:0] inRegs_3;
  wire[31:0] T110;
  wire T78;
  wire T79;
  wire[31:0] T80;
  wire[31:0] T81;
  reg [31:0] inRegs_4;
  wire[31:0] T111;
  reg [31:0] inRegs_5;
  wire[31:0] T112;
  wire T82;
  wire[31:0] T83;
  reg [31:0] inRegs_6;
  wire[31:0] T113;
  reg [31:0] inRegs_7;
  wire[31:0] T114;
  wire T84;
  wire T85;
  wire T86;

`ifndef SYNTHESIS
// synthesis translate_off
  integer initvar;
  initial begin
    #0.002;
    outRegs_0 = {1{$random}};
    writeValue = {1{$random}};
    writeAddressReady = {1{$random}};
    writeRegNumber = {1{$random}};
    writeResponse = {1{$random}};
    outRegs_1 = {1{$random}};
    outRegs_2 = {1{$random}};
    outRegs_3 = {1{$random}};
    outRegs_4 = {1{$random}};
    outRegs_5 = {1{$random}};
    outRegs_6 = {1{$random}};
    outRegs_7 = {1{$random}};
    readReady = {1{$random}};
    readAddressReady = {1{$random}};
    readValue = {1{$random}};
    inRegs_0 = {1{$random}};
    inRegs_1 = {1{$random}};
    readRegNumber = {1{$random}};
    inRegs_2 = {1{$random}};
    inRegs_3 = {1{$random}};
    inRegs_4 = {1{$random}};
    inRegs_5 = {1{$random}};
    inRegs_6 = {1{$random}};
    inRegs_7 = {1{$random}};
  end
// synthesis translate_on
`endif

  assign io_outRegs_0 = outRegs_0;
  assign T87 = reset ? 32'h0 : T0;
  assign T0 = T10 ? writeValue : outRegs_0;
  assign T88 = reset ? 32'h0 : T1;
  assign T1 = T2 ? io_s0_wdata : writeValue;
  assign T2 = T4 & T3;
  assign T3 = io_s0_wvalid == 1'h1;
  assign T4 = T9 & T5;
  assign T5 = writeAddressReady == 1'h0;
  assign T89 = reset ? 1'h0 : T6;
  assign T6 = T8 ? 1'h0 : T7;
  assign T7 = T2 ? 1'h1 : writeAddressReady;
  assign T8 = T2 ^ 1'h1;
  assign T9 = io_s0_awvalid == 1'h1;
  assign T10 = T16 & T11;
  assign T11 = T12[0];
  assign T12 = 1'h1 << T13;
  assign T13 = T90;
  assign T90 = writeRegNumber[2:0];
  assign T91 = reset ? 8'h0 : T14;
  assign T14 = T2 ? T92 : writeRegNumber;
  assign T92 = {5'h0, T15};
  assign T15 = io_s0_awaddr >> 2'h2;
  assign T16 = T25 & T17;
  assign T17 = writeResponse == 1'h0;
  assign T93 = reset ? 1'h0 : T18;
  assign T18 = T20 ? 1'h0 : T19;
  assign T19 = T16 ? 1'h1 : writeResponse;
  assign T20 = T24 & T21;
  assign T21 = T23 & T22;
  assign T22 = writeResponse == 1'h1;
  assign T23 = io_s0_bready == 1'h1;
  assign T24 = T16 ^ 1'h1;
  assign T25 = T27 & T26;
  assign T26 = io_s0_wvalid == 1'h1;
  assign T27 = T29 & T28;
  assign T28 = io_s0_awvalid == 1'h1;
  assign T29 = writeAddressReady == 1'h1;
  assign io_outRegs_1 = outRegs_1;
  assign T94 = reset ? 32'h0 : T30;
  assign T30 = T31 ? writeValue : outRegs_1;
  assign T31 = T16 & T32;
  assign T32 = T12[1];
  assign io_outRegs_2 = outRegs_2;
  assign T95 = reset ? 32'h0 : T33;
  assign T33 = T34 ? writeValue : outRegs_2;
  assign T34 = T16 & T35;
  assign T35 = T12[2];
  assign io_outRegs_3 = outRegs_3;
  assign T96 = reset ? 32'h0 : T36;
  assign T36 = T37 ? writeValue : outRegs_3;
  assign T37 = T16 & T38;
  assign T38 = T12[3];
  assign io_outRegs_4 = outRegs_4;
  assign T97 = reset ? 32'h0 : T39;
  assign T39 = T40 ? writeValue : outRegs_4;
  assign T40 = T16 & T41;
  assign T41 = T12[4];
  assign io_outRegs_5 = outRegs_5;
  assign T98 = reset ? 32'h0 : T42;
  assign T42 = T43 ? writeValue : outRegs_5;
  assign T43 = T16 & T44;
  assign T44 = T12[5];
  assign io_outRegs_6 = outRegs_6;
  assign T99 = reset ? 32'h0 : T45;
  assign T45 = T46 ? writeValue : outRegs_6;
  assign T46 = T16 & T47;
  assign T47 = T12[6];
  assign io_outRegs_7 = outRegs_7;
  assign T100 = reset ? 32'h0 : T48;
  assign T48 = T49 ? writeValue : outRegs_7;
  assign T49 = T16 & T50;
  assign T50 = T12[7];
  assign io_s0_rvalid = readReady;
  assign T101 = reset ? 1'h0 : T51;
  assign T51 = T64 ? 1'h0 : T52;
  assign T52 = T53 ? 1'h1 : readReady;
  assign T53 = T55 & T54;
  assign T54 = readReady == 1'h0;
  assign T55 = T57 & T56;
  assign T56 = io_s0_arvalid == 1'h1;
  assign T57 = readAddressReady == 1'h1;
  assign T102 = reset ? 1'h0 : T58;
  assign T58 = T63 ? 1'h0 : T59;
  assign T59 = T60 ? 1'h1 : readAddressReady;
  assign T60 = T62 & T61;
  assign T61 = readAddressReady == 1'h0;
  assign T62 = io_s0_arvalid == 1'h1;
  assign T63 = T60 ^ 1'h1;
  assign T64 = T68 & T65;
  assign T65 = T67 & T66;
  assign T66 = io_s0_rready == 1'h1;
  assign T67 = readReady == 1'h1;
  assign T68 = T53 ^ 1'h1;
  assign io_s0_rresp = 2'h0;
  assign io_s0_rdata = readValue;
  assign T103 = reset ? 32'h0 : T69;
  assign T69 = T53 ? T70 : readValue;
  assign T70 = T86 ? T80 : T71;
  assign T71 = T79 ? T77 : T72;
  assign T72 = T73 ? inRegs_1 : inRegs_0;
  assign T104 = reset ? 32'h0 : io_inRegs_0;
  assign T105 = reset ? 32'h0 : io_inRegs_1;
  assign T73 = T74[0];
  assign T74 = T106;
  assign T106 = readRegNumber[2:0];
  assign T107 = reset ? 8'h0 : T75;
  assign T75 = T60 ? T108 : readRegNumber;
  assign T108 = {5'h0, T76};
  assign T76 = io_s0_araddr >> 2'h2;
  assign T77 = T78 ? inRegs_3 : inRegs_2;
  assign T109 = reset ? 32'h0 : io_inRegs_2;
  assign T110 = reset ? 32'h0 : io_inRegs_3;
  assign T78 = T74[0];
  assign T79 = T74[1];
  assign T80 = T85 ? T83 : T81;
  assign T81 = T82 ? inRegs_5 : inRegs_4;
  assign T111 = reset ? 32'h0 : io_inRegs_4;
  assign T112 = reset ? 32'h0 : io_inRegs_5;
  assign T82 = T74[0];
  assign T83 = T84 ? inRegs_7 : inRegs_6;
  assign T113 = reset ? 32'h0 : io_inRegs_6;
  assign T114 = reset ? 32'h0 : io_inRegs_7;
  assign T84 = T74[0];
  assign T85 = T74[1];
  assign T86 = T74[2];
  assign io_s0_arready = readAddressReady;
  assign io_s0_bvalid = writeResponse;
  assign io_s0_bresp = 2'h0;
  assign io_s0_wready = writeAddressReady;
  assign io_s0_awready = writeAddressReady;

  always @(posedge clk) begin
    if(reset) begin
      outRegs_0 <= 32'h0;
    end else if(T10) begin
      outRegs_0 <= writeValue;
    end
    if(reset) begin
      writeValue <= 32'h0;
    end else if(T2) begin
      writeValue <= io_s0_wdata;
    end
    if(reset) begin
      writeAddressReady <= 1'h0;
    end else if(T8) begin
      writeAddressReady <= 1'h0;
    end else if(T2) begin
      writeAddressReady <= 1'h1;
    end
    if(reset) begin
      writeRegNumber <= 8'h0;
    end else if(T2) begin
      writeRegNumber <= T92;
    end
    if(reset) begin
      writeResponse <= 1'h0;
    end else if(T20) begin
      writeResponse <= 1'h0;
    end else if(T16) begin
      writeResponse <= 1'h1;
    end
    if(reset) begin
      outRegs_1 <= 32'h0;
    end else if(T31) begin
      outRegs_1 <= writeValue;
    end
    if(reset) begin
      outRegs_2 <= 32'h0;
    end else if(T34) begin
      outRegs_2 <= writeValue;
    end
    if(reset) begin
      outRegs_3 <= 32'h0;
    end else if(T37) begin
      outRegs_3 <= writeValue;
    end
    if(reset) begin
      outRegs_4 <= 32'h0;
    end else if(T40) begin
      outRegs_4 <= writeValue;
    end
    if(reset) begin
      outRegs_5 <= 32'h0;
    end else if(T43) begin
      outRegs_5 <= writeValue;
    end
    if(reset) begin
      outRegs_6 <= 32'h0;
    end else if(T46) begin
      outRegs_6 <= writeValue;
    end
    if(reset) begin
      outRegs_7 <= 32'h0;
    end else if(T49) begin
      outRegs_7 <= writeValue;
    end
    if(reset) begin
      readReady <= 1'h0;
    end else if(T64) begin
      readReady <= 1'h0;
    end else if(T53) begin
      readReady <= 1'h1;
    end
    if(reset) begin
      readAddressReady <= 1'h0;
    end else if(T63) begin
      readAddressReady <= 1'h0;
    end else if(T60) begin
      readAddressReady <= 1'h1;
    end
    if(reset) begin
      readValue <= 32'h0;
    end else if(T53) begin
      readValue <= T70;
    end
    if(reset) begin
      inRegs_0 <= 32'h0;
    end else begin
      inRegs_0 <= io_inRegs_0;
    end
    if(reset) begin
      inRegs_1 <= 32'h0;
    end else begin
      inRegs_1 <= io_inRegs_1;
    end
    if(reset) begin
      readRegNumber <= 8'h0;
    end else if(T60) begin
      readRegNumber <= T108;
    end
    if(reset) begin
      inRegs_2 <= 32'h0;
    end else begin
      inRegs_2 <= io_inRegs_2;
    end
    if(reset) begin
      inRegs_3 <= 32'h0;
    end else begin
      inRegs_3 <= io_inRegs_3;
    end
    if(reset) begin
      inRegs_4 <= 32'h0;
    end else begin
      inRegs_4 <= io_inRegs_4;
    end
    if(reset) begin
      inRegs_5 <= 32'h0;
    end else begin
      inRegs_5 <= io_inRegs_5;
    end
    if(reset) begin
      inRegs_6 <= 32'h0;
    end else begin
      inRegs_6 <= io_inRegs_6;
    end
    if(reset) begin
      inRegs_7 <= 32'h0;
    end else begin
      inRegs_7 <= io_inRegs_7;
    end
  end
endmodule

module AxiPeriph(input clk, input reset,
    input [4:0] io_s0_awaddr,
    input  io_s0_awvalid,
    output io_s0_awready,
    input [31:0] io_s0_wdata,
    input [3:0] io_s0_wstrb,
    input  io_s0_wvalid,
    output io_s0_wready,
    output[1:0] io_s0_bresp,
    output io_s0_bvalid,
    input  io_s0_bready,
    input [4:0] io_s0_araddr,
    output io_s0_arready,
    input  io_s0_arvalid,
    output[31:0] io_s0_rdata,
    output[1:0] io_s0_rresp,
    output io_s0_rvalid,
    input  io_s0_rready
);

  reg [31:0] regs_0;
  wire[31:0] T0;
  reg [31:0] regs_1;
  wire[31:0] T1;
  reg [31:0] regs_2;
  wire[31:0] T2;
  reg [31:0] regs_3;
  wire[31:0] T3;
  reg [31:0] regs_4;
  wire[31:0] T4;
  reg [31:0] regs_5;
  wire[31:0] T5;
  reg [31:0] regs_6;
  wire[31:0] T6;
  reg [31:0] regs_7;
  wire[31:0] T7;
  wire slaveInterface_io_s0_awready;
  wire slaveInterface_io_s0_wready;
  wire[1:0] slaveInterface_io_s0_bresp;
  wire slaveInterface_io_s0_bvalid;
  wire slaveInterface_io_s0_arready;
  wire[31:0] slaveInterface_io_s0_rdata;
  wire[1:0] slaveInterface_io_s0_rresp;
  wire slaveInterface_io_s0_rvalid;
  wire[31:0] slaveInterface_io_outRegs_7;
  wire[31:0] slaveInterface_io_outRegs_6;
  wire[31:0] slaveInterface_io_outRegs_5;
  wire[31:0] slaveInterface_io_outRegs_4;
  wire[31:0] slaveInterface_io_outRegs_3;
  wire[31:0] slaveInterface_io_outRegs_2;
  wire[31:0] slaveInterface_io_outRegs_1;
  wire[31:0] slaveInterface_io_outRegs_0;

`ifndef SYNTHESIS
// synthesis translate_off
  integer initvar;
  initial begin
    #0.002;
    regs_0 = {1{$random}};
    regs_1 = {1{$random}};
    regs_2 = {1{$random}};
    regs_3 = {1{$random}};
    regs_4 = {1{$random}};
    regs_5 = {1{$random}};
    regs_6 = {1{$random}};
    regs_7 = {1{$random}};
  end
// synthesis translate_on
`endif

  assign T0 = reset ? 32'h0 : slaveInterface_io_outRegs_0;
  assign T1 = reset ? 32'h0 : slaveInterface_io_outRegs_1;
  assign T2 = reset ? 32'h0 : slaveInterface_io_outRegs_2;
  assign T3 = reset ? 32'h0 : slaveInterface_io_outRegs_3;
  assign T4 = reset ? 32'h0 : slaveInterface_io_outRegs_4;
  assign T5 = reset ? 32'h0 : slaveInterface_io_outRegs_5;
  assign T6 = reset ? 32'h0 : slaveInterface_io_outRegs_6;
  assign T7 = reset ? 32'h0 : slaveInterface_io_outRegs_7;
  assign io_s0_rvalid = slaveInterface_io_s0_rvalid;
  assign io_s0_rresp = slaveInterface_io_s0_rresp;
  assign io_s0_rdata = slaveInterface_io_s0_rdata;
  assign io_s0_arready = slaveInterface_io_s0_arready;
  assign io_s0_bvalid = slaveInterface_io_s0_bvalid;
  assign io_s0_bresp = slaveInterface_io_s0_bresp;
  assign io_s0_wready = slaveInterface_io_s0_wready;
  assign io_s0_awready = slaveInterface_io_s0_awready;
  axiLiteSlave slaveInterface(.clk(clk), .reset(reset),
       .io_s0_awaddr( io_s0_awaddr ),
       .io_s0_awvalid( io_s0_awvalid ),
       .io_s0_awready( slaveInterface_io_s0_awready ),
       .io_s0_wdata( io_s0_wdata ),
       .io_s0_wstrb( io_s0_wstrb ),
       .io_s0_wvalid( io_s0_wvalid ),
       .io_s0_wready( slaveInterface_io_s0_wready ),
       .io_s0_bresp( slaveInterface_io_s0_bresp ),
       .io_s0_bvalid( slaveInterface_io_s0_bvalid ),
       .io_s0_bready( io_s0_bready ),
       .io_s0_araddr( io_s0_araddr ),
       .io_s0_arready( slaveInterface_io_s0_arready ),
       .io_s0_arvalid( io_s0_arvalid ),
       .io_s0_rdata( slaveInterface_io_s0_rdata ),
       .io_s0_rresp( slaveInterface_io_s0_rresp ),
       .io_s0_rvalid( slaveInterface_io_s0_rvalid ),
       .io_s0_rready( io_s0_rready ),
       .io_outRegs_7( slaveInterface_io_outRegs_7 ),
       .io_outRegs_6( slaveInterface_io_outRegs_6 ),
       .io_outRegs_5( slaveInterface_io_outRegs_5 ),
       .io_outRegs_4( slaveInterface_io_outRegs_4 ),
       .io_outRegs_3( slaveInterface_io_outRegs_3 ),
       .io_outRegs_2( slaveInterface_io_outRegs_2 ),
       .io_outRegs_1( slaveInterface_io_outRegs_1 ),
       .io_outRegs_0( slaveInterface_io_outRegs_0 ),
       .io_inRegs_7( regs_7 ),
       .io_inRegs_6( regs_6 ),
       .io_inRegs_5( regs_5 ),
       .io_inRegs_4( regs_4 ),
       .io_inRegs_3( regs_3 ),
       .io_inRegs_2( regs_2 ),
       .io_inRegs_1( regs_1 ),
       .io_inRegs_0( regs_0 )
  );

  always @(posedge clk) begin
    if(reset) begin
      regs_0 <= 32'h0;
    end else begin
      regs_0 <= slaveInterface_io_outRegs_0;
    end
    if(reset) begin
      regs_1 <= 32'h0;
    end else begin
      regs_1 <= slaveInterface_io_outRegs_1;
    end
    if(reset) begin
      regs_2 <= 32'h0;
    end else begin
      regs_2 <= slaveInterface_io_outRegs_2;
    end
    if(reset) begin
      regs_3 <= 32'h0;
    end else begin
      regs_3 <= slaveInterface_io_outRegs_3;
    end
    if(reset) begin
      regs_4 <= 32'h0;
    end else begin
      regs_4 <= slaveInterface_io_outRegs_4;
    end
    if(reset) begin
      regs_5 <= 32'h0;
    end else begin
      regs_5 <= slaveInterface_io_outRegs_5;
    end
    if(reset) begin
      regs_6 <= 32'h0;
    end else begin
      regs_6 <= slaveInterface_io_outRegs_6;
    end
    if(reset) begin
      regs_7 <= 32'h0;
    end else begin
      regs_7 <= slaveInterface_io_outRegs_7;
    end
  end
endmodule

