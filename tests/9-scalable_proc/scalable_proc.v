module scalable_proc #
(
parameter NUM_PROCESSING_UNITS  = 2,    // Number of processing units
parameter UART_PRESCALER        = 868   // UART prescaler
)
(
// Closk & reset
input  wire CLK,
input  wire RST,

// UART
input  wire UART_RX,
output wire UART_TX
);

// ============================================================================
// ROM
wire         rom_i_stb;
reg  [31:0]  rom_i_adr; // Fixed to 32-bit. The ROM size must be a power of 2 less than 32
wire         rom_o_stb;
wire [31:0]  rom_o_dat;

rom rom
(
.CLK    (CLK),
.RST    (RST),

.I_STB  (rom_i_stb),
.I_ADR  (rom_i_adr),
.O_STB  (rom_o_stb),
.O_DAT  (rom_o_dat)
);

// UART transmitt interval
localparam UART_TX_INTERVAL = UART_PRESCALER * 11; // Wait for 10-bits + 1 extra

// ============================================================================
// Input shift register
localparam SREG_BITS = 32 * NUM_PROCESSING_UNITS;

reg  [SREG_BITS-1:0] inp_sreg;

wire        inp_sreg_i_stb = rom_o_stb;
wire [31:0] inp_sreg_i_dat = rom_o_dat;
reg         inp_sreg_o_stb;

always @(posedge CLK)
    if (inp_sreg_i_stb) inp_sreg <= {inp_sreg[SREG_BITS-32-1:0], inp_sreg_i_dat};
    else                inp_sreg <=  inp_sreg;

always @(posedge CLK or posedge RST)
    if (RST)    inp_sreg_o_stb <= 1'd0;
    else        inp_sreg_o_stb <= inp_sreg_i_stb;

// ============================================================================
// Processing units
reg                             proc_i_stb;
wire [NUM_PROCESSING_UNITS-1:0] proc_o_stb;
wire [SREG_BITS-1:0]            proc_o_dat;

genvar i;
generate for(i=0; i<NUM_PROCESSING_UNITS; i=i+1) begin
    processing_unit unit
    (
    .CLK    (CLK),
    .RST    (RST),
    .I_STB  (proc_i_stb),
    .I_DAT  (inp_sreg[(i+1)*32-1 : i*32]),
    .O_STB  (proc_o_stb[i]),
    .O_DAT  (proc_o_dat[(i+1)*32-1 : i*32])
    );
end endgenerate

// ============================================================================
// Output shift register
reg  [SREG_BITS-1:0] out_sreg;

wire                 out_sreg_i_ld  = proc_o_stb[0];
wire [SREG_BITS-1:0] out_sreg_i_dat = proc_o_dat;
wire                 out_sreg_i_sh;
reg                  out_sreg_o_stb;
wire [3:0]           out_sreg_o_dat;

always @(posedge CLK)
    if      (out_sreg_i_ld) out_sreg <= out_sreg_i_dat;
    else if (out_sreg_i_sh) out_sreg <= out_sreg << 4;
    else                    out_sreg <= out_sreg;

assign out_sreg_o_dat = out_sreg[SREG_BITS-1:SREG_BITS-4];

// DEBUG
always @(posedge CLK)
    if (proc_o_stb) $display("%X", {4'dx, proc_o_dat});

// ============================================================================
// Control FSM
localparam STATE_INIT       = 0;

localparam STATE_LOAD_START = 10;
localparam STATE_LOAD_SHIFT = 11;

localparam STATE_PROC_START = 20;
localparam STATE_PROC_WAIT  = 21;

localparam STATE_SEND_START = 30;
localparam STATE_SEND_WAIT  = 31;
localparam STATE_SEND_DELIM = 32;

integer     fsm;
reg [32:0]  fsm_cnt;

wire        fsm_pulse;
reg [32:0]  fsm_pulse_cnt;

// fsm
always @(posedge CLK or posedge RST)
    if (RST) fsm <= STATE_INIT;
    else case(fsm)

    STATE_INIT:         fsm <= STATE_LOAD_START;

    STATE_LOAD_START:   fsm <= STATE_LOAD_SHIFT;
    STATE_LOAD_SHIFT:   fsm <= (fsm_cnt[32])   ? STATE_PROC_START : fsm;

    STATE_PROC_START:   fsm <= STATE_PROC_WAIT;
    STATE_PROC_WAIT:    fsm <= (proc_o_stb[0]) ? STATE_SEND_START : fsm;

    STATE_SEND_START:   fsm <= STATE_SEND_WAIT;
    STATE_SEND_WAIT:    if (fsm_pulse) fsm <= (fsm_cnt[32]) ? STATE_SEND_DELIM : fsm;
    STATE_SEND_DELIM:   if (fsm_pulse) fsm <= STATE_INIT;

    endcase

// fsm_cnt
always @(posedge CLK)
    case (fsm)

    STATE_LOAD_START:   fsm_cnt <= NUM_PROCESSING_UNITS - 2; // 32-bits per shift

    STATE_SEND_START:   fsm_cnt <= NUM_PROCESSING_UNITS * (32 / 4) - 2; // 4-bits per shift
    STATE_SEND_WAIT:    if (fsm_pulse) fsm_cnt <= (fsm_cnt[32]) ? fsm_cnt : (fsm_cnt - 1);

    default:            fsm_cnt <= (fsm_cnt[32]) ? fsm_cnt : (fsm_cnt - 1);

    endcase

// fsm_pulse_cnt
always @(posedge CLK or posedge RST)
    if (RST) fsm_pulse_cnt <=                       UART_TX_INTERVAL - 2;
    else     fsm_pulse_cnt <= (fsm_pulse_cnt[31]) ? UART_TX_INTERVAL - 2 : fsm_pulse_cnt - 1;

assign fsm_pulse = fsm_pulse_cnt[31];

// ============================================================================
// Control signals
wire        uart_i_stb;
wire [4:0]  uart_i_dat;

assign rom_i_stb = (fsm == STATE_LOAD_SHIFT);

always @(posedge CLK or posedge RST)
    if (RST)          rom_i_adr <= 0;
    else case(fsm)
    STATE_LOAD_SHIFT: rom_i_adr <= rom_i_adr + 1;
    default:          rom_i_adr <= rom_i_adr;
    endcase

always @(posedge CLK or posedge RST)
    if (RST) proc_i_stb <= 0;
    else     proc_i_stb <= (fsm == STATE_PROC_START);

assign out_sreg_i_sh = (fsm == STATE_SEND_WAIT) && fsm_pulse;

assign uart_i_stb    = fsm_pulse && ((fsm == STATE_SEND_WAIT) || 
                                     (fsm == STATE_SEND_DELIM));

assign uart_i_dat    = (fsm == STATE_SEND_WAIT)  ? {1'd0, out_sreg_o_dat} :
                       (fsm == STATE_SEND_DELIM) ? {1'd1, 4'd0} : 
                                                   {1'd1, 4'd0};

// ============================================================================
// UART string generator
reg         uart_x_stb;
reg  [7:0]  uart_x_dat;

always @(posedge CLK)
    case (uart_i_dat)

    5'h00:   uart_x_dat <= "0";
    5'h01:   uart_x_dat <= "1";
    5'h02:   uart_x_dat <= "2";
    5'h03:   uart_x_dat <= "3";
    5'h04:   uart_x_dat <= "4";
    5'h05:   uart_x_dat <= "5";
    5'h06:   uart_x_dat <= "6";
    5'h07:   uart_x_dat <= "7";
    5'h08:   uart_x_dat <= "8";
    5'h09:   uart_x_dat <= "9";
    5'h0A:   uart_x_dat <= "A";
    5'h0B:   uart_x_dat <= "B";
    5'h0C:   uart_x_dat <= "C";
    5'h0D:   uart_x_dat <= "D";
    5'h0E:   uart_x_dat <= "E";
    5'h0F:   uart_x_dat <= "F";

    5'h10:   uart_x_dat <= "\n";

    default: uart_x_dat <= " ";

    endcase

always @(posedge CLK or posedge RST)
    if (RST)    uart_x_stb <= 1'd0;
    else        uart_x_stb <= uart_i_stb;

// ============================================================================
// UART

// Baudrate prescaler initializer
reg  [7:0]  reg_div_we_sr;
wire        reg_div_we;

always @(posedge CLK or posedge RST)
    if (RST)    reg_div_we_sr <= 8'h01;
    else        reg_div_we_sr <= {reg_div_we_sr[6:0], 1'd0};

assign reg_div_we = reg_div_we_sr[7];

// The UART
simpleuart uart
(
.clk            (CLK),
.resetn         (!RST),

.ser_rx         (UART_RX),
.ser_tx         (UART_TX),

.reg_div_we     ({reg_div_we, reg_div_we, reg_div_we, reg_div_we}),
.reg_div_di     (UART_PRESCALER),
.reg_div_do     (),

.reg_dat_we     (uart_x_stb),
.reg_dat_re     (1'd0),
.reg_dat_di     ({24'd0, uart_x_dat}),
.reg_dat_do     (),
.reg_dat_wait   ()
);

// Debug
always @(posedge CLK)
    if (uart_x_stb)
        $display("%c", uart_x_dat);

endmodule

