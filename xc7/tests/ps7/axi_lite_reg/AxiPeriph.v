module AXI4LiteCSR( // @[:@3.2]
  input         clock, // @[:@4.4]
  input         reset, // @[:@5.4]
  input  [4:0]  io_ctl_aw_awaddr, // @[:@6.4]
  input         io_ctl_aw_awvalid, // @[:@6.4]
  output        io_ctl_aw_awready, // @[:@6.4]
  input  [11:0] io_ctl_aw_awid, // @[:@6.4]
  input  [31:0] io_ctl_w_wdata, // @[:@6.4]
  input         io_ctl_w_wvalid, // @[:@6.4]
  output        io_ctl_w_wready, // @[:@6.4]
  output        io_ctl_b_bvalid, // @[:@6.4]
  input         io_ctl_b_bready, // @[:@6.4]
  output [11:0] io_ctl_b_bid, // @[:@6.4]
  input  [4:0]  io_ctl_ar_araddr, // @[:@6.4]
  input         io_ctl_ar_arvalid, // @[:@6.4]
  output        io_ctl_ar_arready, // @[:@6.4]
  input  [11:0] io_ctl_ar_arid, // @[:@6.4]
  output [31:0] io_ctl_r_rdata, // @[:@6.4]
  output        io_ctl_r_rvalid, // @[:@6.4]
  input         io_ctl_r_rready, // @[:@6.4]
  output [11:0] io_ctl_r_rid, // @[:@6.4]
  output [4:0]  io_bus_addr, // @[:@6.4]
  output [31:0] io_bus_dataOut, // @[:@6.4]
  input  [31:0] io_bus_dataIn, // @[:@6.4]
  output        io_bus_write // @[:@6.4]
);
  reg [2:0] state; // @[AXI4LiteCSR.scala 36:22:@8.4]
  reg [31:0] _RAND_0;
  reg  awready; // @[AXI4LiteCSR.scala 38:24:@9.4]
  reg [31:0] _RAND_1;
  reg  wready; // @[AXI4LiteCSR.scala 39:23:@10.4]
  reg [31:0] _RAND_2;
  reg  bvalid; // @[AXI4LiteCSR.scala 40:23:@11.4]
  reg [31:0] _RAND_3;
  reg  arready; // @[AXI4LiteCSR.scala 43:24:@14.4]
  reg [31:0] _RAND_4;
  reg  rvalid; // @[AXI4LiteCSR.scala 44:23:@15.4]
  reg [31:0] _RAND_5;
  reg [4:0] addr; // @[AXI4LiteCSR.scala 47:21:@18.4]
  reg [31:0] _RAND_6;
  reg  write; // @[AXI4LiteCSR.scala 50:22:@20.4]
  reg [31:0] _RAND_7;
  reg [31:0] dataOut; // @[AXI4LiteCSR.scala 51:24:@21.4]
  reg [31:0] _RAND_8;
  reg [11:0] transaction_id; // @[AXI4LiteCSR.scala 53:31:@22.4]
  reg [31:0] _RAND_9;
  wire  _T_138; // @[Conditional.scala 37:30:@37.4]
  wire [2:0] _GEN_0; // @[AXI4LiteCSR.scala 83:36:@49.8]
  wire [11:0] _GEN_1; // @[AXI4LiteCSR.scala 83:36:@49.8]
  wire [2:0] _GEN_2; // @[AXI4LiteCSR.scala 80:30:@44.6]
  wire [11:0] _GEN_3; // @[AXI4LiteCSR.scala 80:30:@44.6]
  wire  _T_144; // @[Conditional.scala 37:30:@55.6]
  wire  _T_146; // @[AXI4LiteCSR.scala 90:30:@58.8]
  wire [2:0] _T_147; // @[AXI4LiteCSR.scala 92:33:@61.10]
  wire [2:0] _GEN_4; // @[AXI4LiteCSR.scala 90:41:@59.8]
  wire [4:0] _GEN_5; // @[AXI4LiteCSR.scala 90:41:@59.8]
  wire  _GEN_7; // @[AXI4LiteCSR.scala 90:41:@59.8]
  wire  _T_150; // @[Conditional.scala 37:30:@68.8]
  wire  _T_152; // @[AXI4LiteCSR.scala 99:28:@71.10]
  wire [2:0] _GEN_8; // @[AXI4LiteCSR.scala 99:38:@72.10]
  wire  _GEN_9; // @[AXI4LiteCSR.scala 99:38:@72.10]
  wire  _T_154; // @[Conditional.scala 37:30:@78.10]
  wire  _T_156; // @[AXI4LiteCSR.scala 106:30:@81.12]
  wire [2:0] _T_157; // @[AXI4LiteCSR.scala 107:33:@83.14]
  wire [4:0] _GEN_10; // @[AXI4LiteCSR.scala 106:41:@82.12]
  wire [2:0] _GEN_11; // @[AXI4LiteCSR.scala 106:41:@82.12]
  wire  _GEN_12; // @[AXI4LiteCSR.scala 106:41:@82.12]
  wire  _T_159; // @[Conditional.scala 37:30:@90.12]
  wire  _T_161; // @[AXI4LiteCSR.scala 114:28:@93.14]
  wire [2:0] _GEN_13; // @[AXI4LiteCSR.scala 114:38:@94.14]
  wire [31:0] _GEN_14; // @[AXI4LiteCSR.scala 114:38:@94.14]
  wire  _GEN_15; // @[AXI4LiteCSR.scala 114:38:@94.14]
  wire  _GEN_16; // @[AXI4LiteCSR.scala 114:38:@94.14]
  wire  _T_164; // @[Conditional.scala 37:30:@102.14]
  wire  _T_167; // @[AXI4LiteCSR.scala 124:28:@106.16]
  wire [2:0] _GEN_17; // @[AXI4LiteCSR.scala 124:38:@107.16]
  wire  _GEN_18; // @[AXI4LiteCSR.scala 124:38:@107.16]
  wire  _GEN_19; // @[Conditional.scala 39:67:@103.14]
  wire  _GEN_20; // @[Conditional.scala 39:67:@103.14]
  wire [2:0] _GEN_21; // @[Conditional.scala 39:67:@103.14]
  wire  _GEN_22; // @[Conditional.scala 39:67:@91.12]
  wire [2:0] _GEN_23; // @[Conditional.scala 39:67:@91.12]
  wire [31:0] _GEN_24; // @[Conditional.scala 39:67:@91.12]
  wire  _GEN_25; // @[Conditional.scala 39:67:@91.12]
  wire  _GEN_26; // @[Conditional.scala 39:67:@91.12]
  wire  _GEN_27; // @[Conditional.scala 39:67:@79.10]
  wire [4:0] _GEN_28; // @[Conditional.scala 39:67:@79.10]
  wire [2:0] _GEN_29; // @[Conditional.scala 39:67:@79.10]
  wire  _GEN_30; // @[Conditional.scala 39:67:@79.10]
  wire [31:0] _GEN_31; // @[Conditional.scala 39:67:@79.10]
  wire  _GEN_32; // @[Conditional.scala 39:67:@79.10]
  wire  _GEN_33; // @[Conditional.scala 39:67:@79.10]
  wire  _GEN_34; // @[Conditional.scala 39:67:@69.8]
  wire [2:0] _GEN_35; // @[Conditional.scala 39:67:@69.8]
  wire  _GEN_36; // @[Conditional.scala 39:67:@69.8]
  wire [4:0] _GEN_37; // @[Conditional.scala 39:67:@69.8]
  wire  _GEN_38; // @[Conditional.scala 39:67:@69.8]
  wire [31:0] _GEN_39; // @[Conditional.scala 39:67:@69.8]
  wire  _GEN_40; // @[Conditional.scala 39:67:@69.8]
  wire  _GEN_41; // @[Conditional.scala 39:67:@69.8]
  wire  _GEN_42; // @[Conditional.scala 39:67:@56.6]
  wire [2:0] _GEN_43; // @[Conditional.scala 39:67:@56.6]
  wire [4:0] _GEN_44; // @[Conditional.scala 39:67:@56.6]
  wire  _GEN_46; // @[Conditional.scala 39:67:@56.6]
  wire  _GEN_47; // @[Conditional.scala 39:67:@56.6]
  wire  _GEN_48; // @[Conditional.scala 39:67:@56.6]
  wire [31:0] _GEN_49; // @[Conditional.scala 39:67:@56.6]
  wire  _GEN_50; // @[Conditional.scala 39:67:@56.6]
  wire  _GEN_51; // @[Conditional.scala 39:67:@56.6]
  wire  _GEN_52; // @[Conditional.scala 40:58:@38.4]
  wire  _GEN_53; // @[Conditional.scala 40:58:@38.4]
  wire  _GEN_55; // @[Conditional.scala 40:58:@38.4]
  wire [11:0] _GEN_56; // @[Conditional.scala 40:58:@38.4]
  wire [2:0] _GEN_57; // @[Conditional.scala 40:58:@38.4]
  wire  _GEN_58; // @[Conditional.scala 40:58:@38.4]
  wire [4:0] _GEN_59; // @[Conditional.scala 40:58:@38.4]
  wire  _GEN_60; // @[Conditional.scala 40:58:@38.4]
  wire  _GEN_61; // @[Conditional.scala 40:58:@38.4]
  wire [31:0] _GEN_62; // @[Conditional.scala 40:58:@38.4]
  assign _T_138 = 3'h0 == state; // @[Conditional.scala 37:30:@37.4]
  assign _GEN_0 = io_ctl_ar_arvalid ? 3'h1 : state; // @[AXI4LiteCSR.scala 83:36:@49.8]
  assign _GEN_1 = io_ctl_ar_arvalid ? io_ctl_ar_arid : 12'h0; // @[AXI4LiteCSR.scala 83:36:@49.8]
  assign _GEN_2 = io_ctl_aw_awvalid ? 3'h3 : _GEN_0; // @[AXI4LiteCSR.scala 80:30:@44.6]
  assign _GEN_3 = io_ctl_aw_awvalid ? io_ctl_aw_awid : _GEN_1; // @[AXI4LiteCSR.scala 80:30:@44.6]
  assign _T_144 = 3'h1 == state; // @[Conditional.scala 37:30:@55.6]
  assign _T_146 = io_ctl_ar_arvalid & arready; // @[AXI4LiteCSR.scala 90:30:@58.8]
  assign _T_147 = io_ctl_ar_araddr[4:2]; // @[AXI4LiteCSR.scala 92:33:@61.10]
  assign _GEN_4 = _T_146 ? 3'h2 : state; // @[AXI4LiteCSR.scala 90:41:@59.8]
  assign _GEN_5 = _T_146 ? {{2'd0}, _T_147} : addr; // @[AXI4LiteCSR.scala 90:41:@59.8]
  assign _GEN_7 = _T_146 ? 1'h0 : 1'h1; // @[AXI4LiteCSR.scala 90:41:@59.8]
  assign _T_150 = 3'h2 == state; // @[Conditional.scala 37:30:@68.8]
  assign _T_152 = io_ctl_r_rready & rvalid; // @[AXI4LiteCSR.scala 99:28:@71.10]
  assign _GEN_8 = _T_152 ? 3'h0 : state; // @[AXI4LiteCSR.scala 99:38:@72.10]
  assign _GEN_9 = _T_152 ? 1'h0 : 1'h1; // @[AXI4LiteCSR.scala 99:38:@72.10]
  assign _T_154 = 3'h3 == state; // @[Conditional.scala 37:30:@78.10]
  assign _T_156 = io_ctl_aw_awvalid & awready; // @[AXI4LiteCSR.scala 106:30:@81.12]
  assign _T_157 = io_ctl_aw_awaddr[4:2]; // @[AXI4LiteCSR.scala 107:33:@83.14]
  assign _GEN_10 = _T_156 ? {{2'd0}, _T_157} : addr; // @[AXI4LiteCSR.scala 106:41:@82.12]
  assign _GEN_11 = _T_156 ? 3'h4 : state; // @[AXI4LiteCSR.scala 106:41:@82.12]
  assign _GEN_12 = _T_156 ? 1'h0 : 1'h1; // @[AXI4LiteCSR.scala 106:41:@82.12]
  assign _T_159 = 3'h4 == state; // @[Conditional.scala 37:30:@90.12]
  assign _T_161 = io_ctl_w_wvalid & wready; // @[AXI4LiteCSR.scala 114:28:@93.14]
  assign _GEN_13 = _T_161 ? 3'h5 : state; // @[AXI4LiteCSR.scala 114:38:@94.14]
  assign _GEN_14 = _T_161 ? io_ctl_w_wdata : dataOut; // @[AXI4LiteCSR.scala 114:38:@94.14]
  assign _GEN_15 = _T_161 ? 1'h1 : write; // @[AXI4LiteCSR.scala 114:38:@94.14]
  assign _GEN_16 = _T_161 ? 1'h0 : 1'h1; // @[AXI4LiteCSR.scala 114:38:@94.14]
  assign _T_164 = 3'h5 == state; // @[Conditional.scala 37:30:@102.14]
  assign _T_167 = io_ctl_b_bready & bvalid; // @[AXI4LiteCSR.scala 124:28:@106.16]
  assign _GEN_17 = _T_167 ? 3'h0 : state; // @[AXI4LiteCSR.scala 124:38:@107.16]
  assign _GEN_18 = _T_167 ? 1'h0 : 1'h1; // @[AXI4LiteCSR.scala 124:38:@107.16]
  assign _GEN_19 = _T_164 ? 1'h0 : wready; // @[Conditional.scala 39:67:@103.14]
  assign _GEN_20 = _T_164 ? _GEN_18 : bvalid; // @[Conditional.scala 39:67:@103.14]
  assign _GEN_21 = _T_164 ? _GEN_17 : state; // @[Conditional.scala 39:67:@103.14]
  assign _GEN_22 = _T_159 ? _GEN_16 : _GEN_19; // @[Conditional.scala 39:67:@91.12]
  assign _GEN_23 = _T_159 ? _GEN_13 : _GEN_21; // @[Conditional.scala 39:67:@91.12]
  assign _GEN_24 = _T_159 ? _GEN_14 : dataOut; // @[Conditional.scala 39:67:@91.12]
  assign _GEN_25 = _T_159 ? _GEN_15 : write; // @[Conditional.scala 39:67:@91.12]
  assign _GEN_26 = _T_159 ? bvalid : _GEN_20; // @[Conditional.scala 39:67:@91.12]
  assign _GEN_27 = _T_154 ? _GEN_12 : awready; // @[Conditional.scala 39:67:@79.10]
  assign _GEN_28 = _T_154 ? _GEN_10 : addr; // @[Conditional.scala 39:67:@79.10]
  assign _GEN_29 = _T_154 ? _GEN_11 : _GEN_23; // @[Conditional.scala 39:67:@79.10]
  assign _GEN_30 = _T_154 ? wready : _GEN_22; // @[Conditional.scala 39:67:@79.10]
  assign _GEN_31 = _T_154 ? dataOut : _GEN_24; // @[Conditional.scala 39:67:@79.10]
  assign _GEN_32 = _T_154 ? write : _GEN_25; // @[Conditional.scala 39:67:@79.10]
  assign _GEN_33 = _T_154 ? bvalid : _GEN_26; // @[Conditional.scala 39:67:@79.10]
  assign _GEN_34 = _T_150 ? _GEN_9 : rvalid; // @[Conditional.scala 39:67:@69.8]
  assign _GEN_35 = _T_150 ? _GEN_8 : _GEN_29; // @[Conditional.scala 39:67:@69.8]
  assign _GEN_36 = _T_150 ? awready : _GEN_27; // @[Conditional.scala 39:67:@69.8]
  assign _GEN_37 = _T_150 ? addr : _GEN_28; // @[Conditional.scala 39:67:@69.8]
  assign _GEN_38 = _T_150 ? wready : _GEN_30; // @[Conditional.scala 39:67:@69.8]
  assign _GEN_39 = _T_150 ? dataOut : _GEN_31; // @[Conditional.scala 39:67:@69.8]
  assign _GEN_40 = _T_150 ? write : _GEN_32; // @[Conditional.scala 39:67:@69.8]
  assign _GEN_41 = _T_150 ? bvalid : _GEN_33; // @[Conditional.scala 39:67:@69.8]
  assign _GEN_42 = _T_144 ? _GEN_7 : arready; // @[Conditional.scala 39:67:@56.6]
  assign _GEN_43 = _T_144 ? _GEN_4 : _GEN_35; // @[Conditional.scala 39:67:@56.6]
  assign _GEN_44 = _T_144 ? _GEN_5 : _GEN_37; // @[Conditional.scala 39:67:@56.6]
  assign _GEN_46 = _T_144 ? rvalid : _GEN_34; // @[Conditional.scala 39:67:@56.6]
  assign _GEN_47 = _T_144 ? awready : _GEN_36; // @[Conditional.scala 39:67:@56.6]
  assign _GEN_48 = _T_144 ? wready : _GEN_38; // @[Conditional.scala 39:67:@56.6]
  assign _GEN_49 = _T_144 ? dataOut : _GEN_39; // @[Conditional.scala 39:67:@56.6]
  assign _GEN_50 = _T_144 ? write : _GEN_40; // @[Conditional.scala 39:67:@56.6]
  assign _GEN_51 = _T_144 ? bvalid : _GEN_41; // @[Conditional.scala 39:67:@56.6]
  assign _GEN_52 = _T_138 ? 1'h0 : _GEN_46; // @[Conditional.scala 40:58:@38.4]
  assign _GEN_53 = _T_138 ? 1'h0 : _GEN_51; // @[Conditional.scala 40:58:@38.4]
  assign _GEN_55 = _T_138 ? 1'h0 : _GEN_50; // @[Conditional.scala 40:58:@38.4]
  assign _GEN_56 = _T_138 ? _GEN_3 : transaction_id; // @[Conditional.scala 40:58:@38.4]
  assign _GEN_57 = _T_138 ? _GEN_2 : _GEN_43; // @[Conditional.scala 40:58:@38.4]
  assign _GEN_58 = _T_138 ? arready : _GEN_42; // @[Conditional.scala 40:58:@38.4]
  assign _GEN_59 = _T_138 ? addr : _GEN_44; // @[Conditional.scala 40:58:@38.4]
  assign _GEN_60 = _T_138 ? awready : _GEN_47; // @[Conditional.scala 40:58:@38.4]
  assign _GEN_61 = _T_138 ? wready : _GEN_48; // @[Conditional.scala 40:58:@38.4]
  assign _GEN_62 = _T_138 ? dataOut : _GEN_49; // @[Conditional.scala 40:58:@38.4]
  assign io_ctl_aw_awready = awready; // @[AXI4LiteCSR.scala 59:21:@26.4]
  assign io_ctl_w_wready = wready; // @[AXI4LiteCSR.scala 60:19:@27.4]
  assign io_ctl_b_bvalid = bvalid; // @[AXI4LiteCSR.scala 61:19:@28.4]
  assign io_ctl_b_bid = transaction_id; // @[AXI4LiteCSR.scala 63:16:@30.4]
  assign io_ctl_ar_arready = arready; // @[AXI4LiteCSR.scala 65:21:@31.4]
  assign io_ctl_r_rdata = io_bus_dataIn; // @[AXI4LiteCSR.scala 55:18:@23.4]
  assign io_ctl_r_rvalid = rvalid; // @[AXI4LiteCSR.scala 66:19:@32.4]
  assign io_ctl_r_rid = transaction_id; // @[AXI4LiteCSR.scala 56:16:@24.4]
  assign io_bus_addr = addr; // @[AXI4LiteCSR.scala 71:15:@36.4]
  assign io_bus_dataOut = dataOut; // @[AXI4LiteCSR.scala 57:18:@25.4]
  assign io_bus_write = write; // @[AXI4LiteCSR.scala 70:16:@35.4]
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE
  integer initvar;
  initial begin
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      #0.002 begin end
    `endif
  `ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  state = _RAND_0[2:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_1 = {1{`RANDOM}};
  awready = _RAND_1[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_2 = {1{`RANDOM}};
  wready = _RAND_2[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_3 = {1{`RANDOM}};
  bvalid = _RAND_3[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_4 = {1{`RANDOM}};
  arready = _RAND_4[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_5 = {1{`RANDOM}};
  rvalid = _RAND_5[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_6 = {1{`RANDOM}};
  addr = _RAND_6[4:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_7 = {1{`RANDOM}};
  write = _RAND_7[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_8 = {1{`RANDOM}};
  dataOut = _RAND_8[31:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_9 = {1{`RANDOM}};
  transaction_id = _RAND_9[11:0];
  `endif // RANDOMIZE_REG_INIT
  end
`endif // RANDOMIZE
  always @(posedge clock) begin
    if (reset) begin
      state <= 3'h0;
    end else begin
      if (_T_138) begin
        if (io_ctl_aw_awvalid) begin
          state <= 3'h3;
        end else begin
          if (io_ctl_ar_arvalid) begin
            state <= 3'h1;
          end
        end
      end else begin
        if (_T_144) begin
          if (_T_146) begin
            state <= 3'h2;
          end
        end else begin
          if (_T_150) begin
            if (_T_152) begin
              state <= 3'h0;
            end
          end else begin
            if (_T_154) begin
              if (_T_156) begin
                state <= 3'h4;
              end
            end else begin
              if (_T_159) begin
                if (_T_161) begin
                  state <= 3'h5;
                end
              end else begin
                if (_T_164) begin
                  if (_T_167) begin
                    state <= 3'h0;
                  end
                end
              end
            end
          end
        end
      end
    end
    if (reset) begin
      awready <= 1'h0;
    end else begin
      if (!(_T_138)) begin
        if (!(_T_144)) begin
          if (!(_T_150)) begin
            if (_T_154) begin
              if (_T_156) begin
                awready <= 1'h0;
              end else begin
                awready <= 1'h1;
              end
            end
          end
        end
      end
    end
    if (reset) begin
      wready <= 1'h0;
    end else begin
      if (!(_T_138)) begin
        if (!(_T_144)) begin
          if (!(_T_150)) begin
            if (!(_T_154)) begin
              if (_T_159) begin
                if (_T_161) begin
                  wready <= 1'h0;
                end else begin
                  wready <= 1'h1;
                end
              end else begin
                if (_T_164) begin
                  wready <= 1'h0;
                end
              end
            end
          end
        end
      end
    end
    if (reset) begin
      bvalid <= 1'h0;
    end else begin
      if (_T_138) begin
        bvalid <= 1'h0;
      end else begin
        if (!(_T_144)) begin
          if (!(_T_150)) begin
            if (!(_T_154)) begin
              if (!(_T_159)) begin
                if (_T_164) begin
                  if (_T_167) begin
                    bvalid <= 1'h0;
                  end else begin
                    bvalid <= 1'h1;
                  end
                end
              end
            end
          end
        end
      end
    end
    if (reset) begin
      arready <= 1'h0;
    end else begin
      if (!(_T_138)) begin
        if (_T_144) begin
          if (_T_146) begin
            arready <= 1'h0;
          end else begin
            arready <= 1'h1;
          end
        end
      end
    end
    if (reset) begin
      rvalid <= 1'h0;
    end else begin
      if (_T_138) begin
        rvalid <= 1'h0;
      end else begin
        if (!(_T_144)) begin
          if (_T_150) begin
            if (_T_152) begin
              rvalid <= 1'h0;
            end else begin
              rvalid <= 1'h1;
            end
          end
        end
      end
    end
    if (reset) begin
      addr <= 5'h0;
    end else begin
      if (!(_T_138)) begin
        if (_T_144) begin
          if (_T_146) begin
            addr <= {{2'd0}, _T_147};
          end
        end else begin
          if (!(_T_150)) begin
            if (_T_154) begin
              if (_T_156) begin
                addr <= {{2'd0}, _T_157};
              end
            end
          end
        end
      end
    end
    if (reset) begin
      write <= 1'h0;
    end else begin
      if (_T_138) begin
        write <= 1'h0;
      end else begin
        if (!(_T_144)) begin
          if (!(_T_150)) begin
            if (!(_T_154)) begin
              if (_T_159) begin
                if (_T_161) begin
                  write <= 1'h1;
                end
              end
            end
          end
        end
      end
    end
    if (reset) begin
      dataOut <= 32'h0;
    end else begin
      if (!(_T_138)) begin
        if (!(_T_144)) begin
          if (!(_T_150)) begin
            if (!(_T_154)) begin
              if (_T_159) begin
                if (_T_161) begin
                  dataOut <= io_ctl_w_wdata;
                end
              end
            end
          end
        end
      end
    end
    if (reset) begin
      transaction_id <= 12'h0;
    end else begin
      if (_T_138) begin
        if (io_ctl_aw_awvalid) begin
          transaction_id <= io_ctl_aw_awid;
        end else begin
          if (io_ctl_ar_arvalid) begin
            transaction_id <= io_ctl_ar_arid;
          end else begin
            transaction_id <= 12'h0;
          end
        end
      end
    end
  end
endmodule
module AxiPeriph( // @[:@113.2]
  input         clock, // @[:@114.4]
  input         reset, // @[:@115.4]
  input  [4:0]  io_axi_s0_aw_awaddr, // @[:@116.4]
  input  [2:0]  io_axi_s0_aw_awprot, // @[:@116.4]
  input         io_axi_s0_aw_awvalid, // @[:@116.4]
  output        io_axi_s0_aw_awready, // @[:@116.4]
  input  [11:0] io_axi_s0_aw_awid, // @[:@116.4]
  input  [31:0] io_axi_s0_w_wdata, // @[:@116.4]
  input  [3:0]  io_axi_s0_w_wstrb, // @[:@116.4]
  input         io_axi_s0_w_wvalid, // @[:@116.4]
  output        io_axi_s0_w_wready, // @[:@116.4]
  input  [11:0] io_axi_s0_w_wid, // @[:@116.4]
  output [1:0]  io_axi_s0_b_bresp, // @[:@116.4]
  output        io_axi_s0_b_bvalid, // @[:@116.4]
  input         io_axi_s0_b_bready, // @[:@116.4]
  output [11:0] io_axi_s0_b_bid, // @[:@116.4]
  input  [4:0]  io_axi_s0_ar_araddr, // @[:@116.4]
  input  [2:0]  io_axi_s0_ar_arprot, // @[:@116.4]
  input         io_axi_s0_ar_arvalid, // @[:@116.4]
  output        io_axi_s0_ar_arready, // @[:@116.4]
  input  [11:0] io_axi_s0_ar_arid, // @[:@116.4]
  output [31:0] io_axi_s0_r_rdata, // @[:@116.4]
  output [1:0]  io_axi_s0_r_rresp, // @[:@116.4]
  output        io_axi_s0_r_rvalid, // @[:@116.4]
  input         io_axi_s0_r_rready, // @[:@116.4]
  output [11:0] io_axi_s0_r_rid, // @[:@116.4]
  output [1:0]  io_leds, // @[:@116.4]
  output        io_irqOut // @[:@116.4]
);
  wire  slaveInterface_clock; // @[Axi.scala 37:32:@128.4]
  wire  slaveInterface_reset; // @[Axi.scala 37:32:@128.4]
  wire [4:0] slaveInterface_io_ctl_aw_awaddr; // @[Axi.scala 37:32:@128.4]
  wire  slaveInterface_io_ctl_aw_awvalid; // @[Axi.scala 37:32:@128.4]
  wire  slaveInterface_io_ctl_aw_awready; // @[Axi.scala 37:32:@128.4]
  wire [11:0] slaveInterface_io_ctl_aw_awid; // @[Axi.scala 37:32:@128.4]
  wire [31:0] slaveInterface_io_ctl_w_wdata; // @[Axi.scala 37:32:@128.4]
  wire  slaveInterface_io_ctl_w_wvalid; // @[Axi.scala 37:32:@128.4]
  wire  slaveInterface_io_ctl_w_wready; // @[Axi.scala 37:32:@128.4]
  wire  slaveInterface_io_ctl_b_bvalid; // @[Axi.scala 37:32:@128.4]
  wire  slaveInterface_io_ctl_b_bready; // @[Axi.scala 37:32:@128.4]
  wire [11:0] slaveInterface_io_ctl_b_bid; // @[Axi.scala 37:32:@128.4]
  wire [4:0] slaveInterface_io_ctl_ar_araddr; // @[Axi.scala 37:32:@128.4]
  wire  slaveInterface_io_ctl_ar_arvalid; // @[Axi.scala 37:32:@128.4]
  wire  slaveInterface_io_ctl_ar_arready; // @[Axi.scala 37:32:@128.4]
  wire [11:0] slaveInterface_io_ctl_ar_arid; // @[Axi.scala 37:32:@128.4]
  wire [31:0] slaveInterface_io_ctl_r_rdata; // @[Axi.scala 37:32:@128.4]
  wire  slaveInterface_io_ctl_r_rvalid; // @[Axi.scala 37:32:@128.4]
  wire  slaveInterface_io_ctl_r_rready; // @[Axi.scala 37:32:@128.4]
  wire [11:0] slaveInterface_io_ctl_r_rid; // @[Axi.scala 37:32:@128.4]
  wire [4:0] slaveInterface_io_bus_addr; // @[Axi.scala 37:32:@128.4]
  wire [31:0] slaveInterface_io_bus_dataOut; // @[Axi.scala 37:32:@128.4]
  wire [31:0] slaveInterface_io_bus_dataIn; // @[Axi.scala 37:32:@128.4]
  wire  slaveInterface_io_bus_write; // @[Axi.scala 37:32:@128.4]
  reg [31:0] regs_0; // @[Axi.scala 36:23:@127.4]
  reg [31:0] _RAND_0;
  reg [31:0] regs_1; // @[Axi.scala 36:23:@127.4]
  reg [31:0] _RAND_1;
  reg [31:0] regs_2; // @[Axi.scala 36:23:@127.4]
  reg [31:0] _RAND_2;
  reg [31:0] regs_3; // @[Axi.scala 36:23:@127.4]
  reg [31:0] _RAND_3;
  reg [31:0] regs_4; // @[Axi.scala 36:23:@127.4]
  reg [31:0] _RAND_4;
  reg [31:0] regs_5; // @[Axi.scala 36:23:@127.4]
  reg [31:0] _RAND_5;
  reg [31:0] regs_6; // @[Axi.scala 36:23:@127.4]
  reg [31:0] _RAND_6;
  reg [31:0] regs_7; // @[Axi.scala 36:23:@127.4]
  reg [31:0] _RAND_7;
  wire [2:0] _T_182; // @[:@160.6]
  wire [31:0] _regs_T_182; // @[Axi.scala 47:40:@161.6 Axi.scala 47:40:@161.6]
  wire [31:0] _GEN_0; // @[Axi.scala 47:40:@161.6]
  wire [31:0] _GEN_1; // @[Axi.scala 47:40:@161.6]
  wire [31:0] _GEN_2; // @[Axi.scala 47:40:@161.6]
  wire [31:0] _GEN_3; // @[Axi.scala 47:40:@161.6]
  wire [31:0] _GEN_4; // @[Axi.scala 47:40:@161.6]
  wire [31:0] _GEN_5; // @[Axi.scala 47:40:@161.6]
  wire [31:0] _GEN_6; // @[Axi.scala 47:40:@161.6]
  wire [31:0] _GEN_7; // @[Axi.scala 47:40:@161.6]
  wire [31:0] _GEN_8; // @[Axi.scala 46:39:@159.4]
  wire [31:0] _GEN_9; // @[Axi.scala 46:39:@159.4]
  wire [31:0] _GEN_10; // @[Axi.scala 46:39:@159.4]
  wire [31:0] _GEN_11; // @[Axi.scala 46:39:@159.4]
  wire [31:0] _GEN_12; // @[Axi.scala 46:39:@159.4]
  wire [31:0] _GEN_13; // @[Axi.scala 46:39:@159.4]
  wire [31:0] _GEN_14; // @[Axi.scala 46:39:@159.4]
  wire [31:0] _GEN_15; // @[Axi.scala 46:39:@159.4]
  wire [31:0] _GEN_17; // @[Axi.scala 50:34:@164.4]
  wire [31:0] _GEN_18; // @[Axi.scala 50:34:@164.4]
  wire [31:0] _GEN_19; // @[Axi.scala 50:34:@164.4]
  wire [31:0] _GEN_20; // @[Axi.scala 50:34:@164.4]
  wire [31:0] _GEN_21; // @[Axi.scala 50:34:@164.4]
  wire [31:0] _GEN_22; // @[Axi.scala 50:34:@164.4]
  AXI4LiteCSR slaveInterface ( // @[Axi.scala 37:32:@128.4]
    .clock(slaveInterface_clock),
    .reset(slaveInterface_reset),
    .io_ctl_aw_awaddr(slaveInterface_io_ctl_aw_awaddr),
    .io_ctl_aw_awvalid(slaveInterface_io_ctl_aw_awvalid),
    .io_ctl_aw_awready(slaveInterface_io_ctl_aw_awready),
    .io_ctl_aw_awid(slaveInterface_io_ctl_aw_awid),
    .io_ctl_w_wdata(slaveInterface_io_ctl_w_wdata),
    .io_ctl_w_wvalid(slaveInterface_io_ctl_w_wvalid),
    .io_ctl_w_wready(slaveInterface_io_ctl_w_wready),
    .io_ctl_b_bvalid(slaveInterface_io_ctl_b_bvalid),
    .io_ctl_b_bready(slaveInterface_io_ctl_b_bready),
    .io_ctl_b_bid(slaveInterface_io_ctl_b_bid),
    .io_ctl_ar_araddr(slaveInterface_io_ctl_ar_araddr),
    .io_ctl_ar_arvalid(slaveInterface_io_ctl_ar_arvalid),
    .io_ctl_ar_arready(slaveInterface_io_ctl_ar_arready),
    .io_ctl_ar_arid(slaveInterface_io_ctl_ar_arid),
    .io_ctl_r_rdata(slaveInterface_io_ctl_r_rdata),
    .io_ctl_r_rvalid(slaveInterface_io_ctl_r_rvalid),
    .io_ctl_r_rready(slaveInterface_io_ctl_r_rready),
    .io_ctl_r_rid(slaveInterface_io_ctl_r_rid),
    .io_bus_addr(slaveInterface_io_bus_addr),
    .io_bus_dataOut(slaveInterface_io_bus_dataOut),
    .io_bus_dataIn(slaveInterface_io_bus_dataIn),
    .io_bus_write(slaveInterface_io_bus_write)
  );
  assign _T_182 = slaveInterface_io_bus_addr[2:0]; // @[:@160.6]
  assign _regs_T_182 = slaveInterface_io_bus_dataOut; // @[Axi.scala 47:40:@161.6 Axi.scala 47:40:@161.6]
  assign _GEN_0 = 3'h0 == _T_182 ? _regs_T_182 : regs_0; // @[Axi.scala 47:40:@161.6]
  assign _GEN_1 = 3'h1 == _T_182 ? _regs_T_182 : regs_1; // @[Axi.scala 47:40:@161.6]
  assign _GEN_2 = 3'h2 == _T_182 ? _regs_T_182 : regs_2; // @[Axi.scala 47:40:@161.6]
  assign _GEN_3 = 3'h3 == _T_182 ? _regs_T_182 : regs_3; // @[Axi.scala 47:40:@161.6]
  assign _GEN_4 = 3'h4 == _T_182 ? _regs_T_182 : regs_4; // @[Axi.scala 47:40:@161.6]
  assign _GEN_5 = 3'h5 == _T_182 ? _regs_T_182 : regs_5; // @[Axi.scala 47:40:@161.6]
  assign _GEN_6 = 3'h6 == _T_182 ? _regs_T_182 : regs_6; // @[Axi.scala 47:40:@161.6]
  assign _GEN_7 = 3'h7 == _T_182 ? _regs_T_182 : regs_7; // @[Axi.scala 47:40:@161.6]
  assign _GEN_8 = slaveInterface_io_bus_write ? _GEN_0 : regs_0; // @[Axi.scala 46:39:@159.4]
  assign _GEN_9 = slaveInterface_io_bus_write ? _GEN_1 : regs_1; // @[Axi.scala 46:39:@159.4]
  assign _GEN_10 = slaveInterface_io_bus_write ? _GEN_2 : regs_2; // @[Axi.scala 46:39:@159.4]
  assign _GEN_11 = slaveInterface_io_bus_write ? _GEN_3 : regs_3; // @[Axi.scala 46:39:@159.4]
  assign _GEN_12 = slaveInterface_io_bus_write ? _GEN_4 : regs_4; // @[Axi.scala 46:39:@159.4]
  assign _GEN_13 = slaveInterface_io_bus_write ? _GEN_5 : regs_5; // @[Axi.scala 46:39:@159.4]
  assign _GEN_14 = slaveInterface_io_bus_write ? _GEN_6 : regs_6; // @[Axi.scala 46:39:@159.4]
  assign _GEN_15 = slaveInterface_io_bus_write ? _GEN_7 : regs_7; // @[Axi.scala 46:39:@159.4]
  assign _GEN_17 = 3'h1 == _T_182 ? regs_1 : regs_0; // @[Axi.scala 50:34:@164.4]
  assign _GEN_18 = 3'h2 == _T_182 ? regs_2 : _GEN_17; // @[Axi.scala 50:34:@164.4]
  assign _GEN_19 = 3'h3 == _T_182 ? regs_3 : _GEN_18; // @[Axi.scala 50:34:@164.4]
  assign _GEN_20 = 3'h4 == _T_182 ? regs_4 : _GEN_19; // @[Axi.scala 50:34:@164.4]
  assign _GEN_21 = 3'h5 == _T_182 ? regs_5 : _GEN_20; // @[Axi.scala 50:34:@164.4]
  assign _GEN_22 = 3'h6 == _T_182 ? regs_6 : _GEN_21; // @[Axi.scala 50:34:@164.4]
  assign io_axi_s0_aw_awready = slaveInterface_io_ctl_aw_awready; // @[Axi.scala 42:27:@153.4]
  assign io_axi_s0_w_wready = slaveInterface_io_ctl_w_wready; // @[Axi.scala 42:27:@148.4]
  assign io_axi_s0_b_bresp = 2'h0; // @[Axi.scala 42:27:@146.4]
  assign io_axi_s0_b_bvalid = slaveInterface_io_ctl_b_bvalid; // @[Axi.scala 42:27:@145.4]
  assign io_axi_s0_b_bid = slaveInterface_io_ctl_b_bid; // @[Axi.scala 42:27:@143.4]
  assign io_axi_s0_ar_arready = slaveInterface_io_ctl_ar_arready; // @[Axi.scala 42:27:@139.4]
  assign io_axi_s0_r_rdata = slaveInterface_io_ctl_r_rdata; // @[Axi.scala 42:27:@137.4]
  assign io_axi_s0_r_rresp = 2'h0; // @[Axi.scala 42:27:@136.4]
  assign io_axi_s0_r_rvalid = slaveInterface_io_ctl_r_rvalid; // @[Axi.scala 42:27:@135.4]
  assign io_axi_s0_r_rid = slaveInterface_io_ctl_r_rid; // @[Axi.scala 42:27:@133.4]
  assign io_leds = regs_0[1:0]; // @[Axi.scala 43:13:@158.4]
  assign io_irqOut = regs_0[4]; // @[Axi.scala 39:15:@132.4]
  assign slaveInterface_clock = clock; // @[:@129.4]
  assign slaveInterface_reset = reset; // @[:@130.4]
  assign slaveInterface_io_ctl_aw_awaddr = io_axi_s0_aw_awaddr; // @[Axi.scala 42:27:@156.4]
  assign slaveInterface_io_ctl_aw_awvalid = io_axi_s0_aw_awvalid; // @[Axi.scala 42:27:@154.4]
  assign slaveInterface_io_ctl_aw_awid = io_axi_s0_aw_awid; // @[Axi.scala 42:27:@152.4]
  assign slaveInterface_io_ctl_w_wdata = io_axi_s0_w_wdata; // @[Axi.scala 42:27:@151.4]
  assign slaveInterface_io_ctl_w_wvalid = io_axi_s0_w_wvalid; // @[Axi.scala 42:27:@149.4]
  assign slaveInterface_io_ctl_b_bready = io_axi_s0_b_bready; // @[Axi.scala 42:27:@144.4]
  assign slaveInterface_io_ctl_ar_araddr = io_axi_s0_ar_araddr; // @[Axi.scala 42:27:@142.4]
  assign slaveInterface_io_ctl_ar_arvalid = io_axi_s0_ar_arvalid; // @[Axi.scala 42:27:@140.4]
  assign slaveInterface_io_ctl_ar_arid = io_axi_s0_ar_arid; // @[Axi.scala 42:27:@138.4]
  assign slaveInterface_io_ctl_r_rready = io_axi_s0_r_rready; // @[Axi.scala 42:27:@134.4]
  assign slaveInterface_io_bus_dataIn = 3'h7 == _T_182 ? regs_7 : _GEN_22; // @[Axi.scala 50:34:@164.4]
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE
  integer initvar;
  initial begin
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      #0.002 begin end
    `endif
  `ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  regs_0 = _RAND_0[31:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_1 = {1{`RANDOM}};
  regs_1 = _RAND_1[31:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_2 = {1{`RANDOM}};
  regs_2 = _RAND_2[31:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_3 = {1{`RANDOM}};
  regs_3 = _RAND_3[31:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_4 = {1{`RANDOM}};
  regs_4 = _RAND_4[31:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_5 = {1{`RANDOM}};
  regs_5 = _RAND_5[31:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_6 = {1{`RANDOM}};
  regs_6 = _RAND_6[31:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_7 = {1{`RANDOM}};
  regs_7 = _RAND_7[31:0];
  `endif // RANDOMIZE_REG_INIT
  end
`endif // RANDOMIZE
  always @(posedge clock) begin
    if (reset) begin
      regs_0 <= 32'h0;
    end else begin
      if (slaveInterface_io_bus_write) begin
        if (3'h0 == _T_182) begin
          regs_0 <= _regs_T_182;
        end
      end
    end
    if (reset) begin
      regs_1 <= 32'h0;
    end else begin
      if (slaveInterface_io_bus_write) begin
        if (3'h1 == _T_182) begin
          regs_1 <= _regs_T_182;
        end
      end
    end
    if (reset) begin
      regs_2 <= 32'h0;
    end else begin
      if (slaveInterface_io_bus_write) begin
        if (3'h2 == _T_182) begin
          regs_2 <= _regs_T_182;
        end
      end
    end
    if (reset) begin
      regs_3 <= 32'h0;
    end else begin
      if (slaveInterface_io_bus_write) begin
        if (3'h3 == _T_182) begin
          regs_3 <= _regs_T_182;
        end
      end
    end
    if (reset) begin
      regs_4 <= 32'h0;
    end else begin
      if (slaveInterface_io_bus_write) begin
        if (3'h4 == _T_182) begin
          regs_4 <= _regs_T_182;
        end
      end
    end
    if (reset) begin
      regs_5 <= 32'h0;
    end else begin
      if (slaveInterface_io_bus_write) begin
        if (3'h5 == _T_182) begin
          regs_5 <= _regs_T_182;
        end
      end
    end
    if (reset) begin
      regs_6 <= 32'h0;
    end else begin
      if (slaveInterface_io_bus_write) begin
        if (3'h6 == _T_182) begin
          regs_6 <= _regs_T_182;
        end
      end
    end
    if (reset) begin
      regs_7 <= 32'h0;
    end else begin
      if (slaveInterface_io_bus_write) begin
        if (3'h7 == _T_182) begin
          regs_7 <= _regs_T_182;
        end
      end
    end
  end
endmodule
