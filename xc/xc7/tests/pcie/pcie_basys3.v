module top(
  input  wire clk,

  input  wire rx,
  output wire tx,

  input  wire [15:0] sw,
  output wire [15:0] led
);
    assign led[15:1] = sw[15:1];
    assign tx = rx;
    
    wire drp_rdy, sys_rst_n;
    assign sys_rst_n = sw[0];
    assign led[0] = drp_rdy;
    
    PCIE_2_1 #(
        .LINK_CAP_MAX_LINK_WIDTH(8)
    ) PCIE_INST (
        .DRPRDY(drp_rdy),
        .SYSRSTN(sys_rst_n)
    );

endmodule
