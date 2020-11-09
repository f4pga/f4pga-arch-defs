module top (clk, ff_in_sel, fs_in , bb2_in, ba1_in, tb1_in, ta2_in, tsel_in, tabsel_in, bsel_in, babsel_in, tbsel_in, ff_out, f_out, t_out, c_out ) ;

    input clk ;
	input ff_in_sel; 
	input fs_in;
	input bb2_in;
	input ba1_in;
	input tb1_in;
	input ta2_in;
	input tsel_in;
	input tabsel_in;   
	input bsel_in;
	input babsel_in;
	input tbsel_in;
		
	output ff_out; 
	output f_out;
	output t_out;
	output c_out;
	
  wire GND;
  wire VCC;

  wire ff_out; 
  wire f_out;
  wire t_out;
  wire c_out;
  
  wire ff_in_sel; 
  wire fs_in;
  wire bb2_in;
  wire ba1_in;
  wire tb1_in;
  wire ta2_in;
  wire tsel_in;
  wire tabsel_in;   
  wire bsel_in;
  wire babsel_in;
  wire tbsel_in;

  assign GND = 1'b0;
  assign VCC = 1'b1;

  assign clk_int = clk;

   logic_cell_macro u_logic_cell_inst_1 (
    .QRT (GND),
    .QCK (clk_int),
    .QCKS (VCC),   
    .QEN (VCC),
    .QDI (GND),
    .QDS (ff_in_sel),
    .QST (GND),   
    .QZ (ff_out ),
    .F2 (GND),
    .F1 (VCC),
    .FS (fs_in ),
    .FZ (f_out),
    .BB2 (bb2_in ),
    .BB1 (VCC ),
    .BA2 (GND),
    .BA1 (ba1_in),
    .TB2 (VCC),
    .TB1 (tb1_in),
    .TA2 (ta2_in),
    .TA1 (GND),
    .TSL (tsel_in ),
    .TAB (tabsel_in),
    .TZ (t_out),
    .BSL (bsel_in ), 
    .BAB (babsel_in),
    .TBS (tbsel_in),
    .CZ (c_out),
    .BBS2 (GND),   
    .BBS1 (GND),
    .BAS2 (GND),
    .BAS1 (GND),
    .TBS2 (GND),   
    .TBS1 (GND),
    .TAS2 (GND),
    .TAS1 (GND)
  );

endmodule

