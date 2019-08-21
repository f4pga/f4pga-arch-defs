module srl_init_tester #
(
parameter [255:0] PATTERN = 256'hFE1AB3FE7610D3D205D9A526C103C40F6477E986F53C53FA663A9CE45E851D30,
parameter         SRL_LENGTH  = 32
)
(
input  wire clk,
input  wire rst,
input  wire ce,

output reg  srl_sh,
output wire [SRL_BITS-1:0] srl_a,
output wire srl_d,
input  wire srl_q,

output reg  error
);

// ============================================================================
// ROM
wire [7:0] rom_adr;
wire       rom_dat;

ROM #(.CONTENT(PATTERN)) rom
(
.clk    (clk),
.adr    (rom_adr),
.dat    (rom_dat)
);

// ============================================================================
// Control
localparam SRL_BITS = $clog2(SRL_LENGTH);

// Bit counter
reg[SRL_BITS-1:0] bit_cnt;

always @(posedge clk)
    if (rst)
        bit_cnt <= SRL_LENGTH - 1;
    else if (ce)
        bit_cnt <= bit_cnt - 1;

// Data readout
assign rom_adr = bit_cnt;

// SRL32 control
assign srl_a  = SRL_LENGTH - 1;
assign srl_d  = srl_q;

always @(posedge clk)
    srl_sh <= ce & !rst;

// Error check
always @(posedge clk)
    if (rst)
        error <= 1'b0;
    else if(ce)
        error <= rom_dat ^ srl_q;

endmodule

