module srl_shift_tester #
(
parameter [511:0] ROM_CONTENT = 512'h0833D855BF064C540DFD9FFFB51E402AC1839A048A68620BD94EB15E67C8FE9DDA32A47EA170107BB10665E6A59D3CE2359205CDFD5E598E490BBA776C334DB9,
parameter         SRL_LENGTH  = 32,
parameter         FIXED_DELAY = 0
)
(
input  wire clk,
input  wire rst,
input  wire ce,

output reg  srl_sh,
output wire [$clog2(SRL_LENGTH)-1:0] srl_a,
output wire srl_d,
input  wire srl_q,

output reg  error
);

// ============================================================================
// ROM
wire [8:0] rom_adr;
wire       rom_dat;

ROM #(.CONTENT(ROM_CONTENT)) rom
(
.clk    (clk),
.adr    (rom_adr),
.dat    (rom_dat)
);

// ============================================================================
// Control

reg [$clog2(SRL_LENGTH)-1:0] delay;
reg [1:0] phase;

initial phase <= 0;
always @(posedge clk)
    if (rst)
        phase <= 2'b11;
    else if (ce)
        phase <= 2'd0;
    else if (!phase[1])
        phase <= phase + 1;

// Data fetch
reg rom_dat_1;
reg rom_dat_2;

assign rom_adr = (phase == 2'd0) ? rom_adr_1 : rom_adr_2;

always @(posedge clk)
    if (phase == 2'd0)
        rom_dat_1 <= rom_dat;

always @(posedge clk)
    if (phase == 2'd1)
        rom_dat_2 <= rom_dat;

// Address counter
reg [8:0] rom_adr_1 = 0;
reg [8:0] rom_adr_2 = 0;

always @(posedge clk)
    if (rst)
        rom_adr_1 <= 0;
    else if (phase == 2'd1)
        rom_adr_1 <= rom_adr_1 + 1;

always @(posedge clk)
    rom_adr_2 <= rom_adr_1 + delay;

// SRL control
always @(posedge clk)
    if (!srl_sh) srl_sh <= (phase == 2'd0);
    else         srl_sh <= 0;

assign srl_a = delay;
assign srl_d = rom_dat_1;

// Delay change
wire delay_chg = (FIXED_DELAY == 0) && (phase == 2'd1 && rom_adr_1 == 9'h1FF);

initial delay <= FIXED_DELAY - 1;
always @(posedge clk)
    if (rst)
        delay <= FIXED_DELAY - 1;
    else if (delay_chg)
        delay <= (delay == (SRL_LENGTH - 1)) ? 0 : (delay + 1);

// ============================================================================
// Error check

// Check inhibit (after delay change)
reg [8:0] inh_cnt = -1;
wire check_inh = ~inh_cnt[8];

always @(posedge clk)
    if (rst)
        inh_cnt <= SRL_LENGTH - 1;
    else if (phase == 1) begin
        if (delay_chg)
            inh_cnt <= SRL_LENGTH - 1;
        else if(check_inh)
            inh_cnt <= inh_cnt - 1;
    end

// Error check
always @(posedge clk)
    error <= !check_inh && (srl_q ^ rom_dat_2);

endmodule

