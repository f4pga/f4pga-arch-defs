`timescale 1ns/1ps

module i2c_scan (
    // Clock and reset
    input  wire         clk,
    input  wire         rst,

    // I2C control signals for 3-state IO buffers
    input  wire         scl_i,
    output wire         scl_o,
    output wire         scl_t,
    input  wire         sda_i,
    output wire         sda_o,
    output wire         sda_t,

    // UART
    input  wire         rx,
    output wire         tx,

    // Scan control
    input  wire         i_trg,
    output reg          i_bsy
);

// ============================================================================

parameter        UART_PRESCALER    = 868;   // UART prescaler
parameter [15:0] I2C_PRESCALER     = 999;   // I2C prescaler
parameter [6 :0] I2C_BEG_ADDR      = 7'b0000_100;
parameter [6 :0] I2C_END_ADDR      = 7'b1111_000;

// UART transfer interval
localparam TX_INTERVAL = UART_PRESCALER * 11; // Wait for 10-bits + 1 extra

// ============================================================================
// I2C probing module
reg         probe_i_stb;
reg  [6:0]  probe_i_adr;
wire        probe_i_bsy;

wire        probe_o_stb;
wire        probe_o_ack;

i2c_probe #
(
.I2C_PRESCALER (I2C_PRESCALER)
)
i2c_probe
(
.clk        (clk),
.rst        (rst),

.scl_i      (scl_i),
.scl_o      (scl_o),
.scl_t      (scl_t),
.sda_i      (sda_i),
.sda_o      (sda_o),
.sda_t      (sda_t),

.i_stb      (probe_i_stb),
.i_adr      (probe_i_adr),
.i_bsy      (probe_i_bsy),

.o_stb      (probe_o_stb),
.o_ack      (probe_o_ack)
);

// ============================================================================
// Control FSM
localparam FSM_IDLE         = 'h00;
localparam FSM_INIT         = 'h20;
localparam FSM_PROBE_REQ    = 'h30;
localparam FSM_PROBE_WAIT   = 'h40;
localparam FSM_PROBE_DONE   = 'h50;
localparam FSM_TX_1         = 'h60;
localparam FSM_TX_2         = 'h61;
localparam FSM_TX_3         = 'h62;
localparam FSM_TX_4         = 'h63;
localparam FSM_TX_5         = 'h64;
localparam FSM_TX_6         = 'h65;
localparam FSM_NEXT         = 'h70;

integer fsm;
initial fsm <= FSM_IDLE;

always @(posedge clk)
    if (rst) fsm <= FSM_IDLE;
    else case(fsm)
    
    FSM_IDLE:       if (i_trg)  fsm <= FSM_INIT;
                    else fsm <= fsm;

    FSM_INIT:       fsm <= FSM_PROBE_REQ;

    FSM_PROBE_REQ:  fsm <= FSM_PROBE_WAIT;
    FSM_PROBE_WAIT: if (probe_o_stb) fsm <= FSM_PROBE_DONE;
                    else fsm <= fsm;

    FSM_PROBE_DONE: fsm <= FSM_TX_1;

    FSM_TX_1:       if (wait_s) fsm <= FSM_TX_2;
                    else fsm <= fsm;
    FSM_TX_2:       if (wait_s) fsm <= FSM_TX_3;
                    else fsm <= fsm;
    FSM_TX_3:       if (wait_s) fsm <= FSM_TX_4;
                    else fsm <= fsm;
    FSM_TX_4:       if (wait_s) fsm <= FSM_TX_5;
                    else fsm <= fsm;
    FSM_TX_5:       if (wait_s) fsm <= FSM_TX_6;
                    else fsm <= fsm;
    FSM_TX_6:       if (wait_s) fsm <= FSM_NEXT;
                    else fsm <= fsm;

    FSM_NEXT:       if (probe_i_adr == I2C_END_ADDR) fsm <= FSM_IDLE;
                    else fsm <= FSM_PROBE_REQ;

    default:        fsm <= fsm;
    endcase

// ============================================================================
// Busy signal
always @(posedge clk)
    if (rst)                i_bsy <= 1'd0;
    else case (fsm)

    FSM_IDLE:   if(i_trg)   i_bsy <= 1'b1;
                else        i_bsy <= 1'b0;

    default:                i_bsy <= i_bsy;
    endcase
    
// ============================================================================
// Wait counter
reg [32:0] wait_cnt;
wire wait_s;

always @(posedge clk)
    if (rst)                wait_cnt <= 0;
    else case (fsm)

    FSM_TX_1:   if (wait_s) wait_cnt <= TX_INTERVAL;
                else        wait_cnt <= wait_cnt - 1;
    FSM_TX_2:   if (wait_s) wait_cnt <= TX_INTERVAL;
                else        wait_cnt <= wait_cnt - 1;
    FSM_TX_3:   if (wait_s) wait_cnt <= TX_INTERVAL;
                else        wait_cnt <= wait_cnt - 1;
    FSM_TX_4:   if (wait_s) wait_cnt <= TX_INTERVAL;
                else        wait_cnt <= wait_cnt - 1;
    FSM_TX_5:   if (wait_s) wait_cnt <= TX_INTERVAL;
                else        wait_cnt <= wait_cnt - 1;
    FSM_TX_6:   if (wait_s) wait_cnt <= TX_INTERVAL;
                else        wait_cnt <= wait_cnt - 1;

    default:    if (wait_s) wait_cnt <= wait_cnt;
                else        wait_cnt <= wait_cnt - 1;
    endcase

assign wait_s = wait_cnt[32];

// ============================================================================
// I2C probe control
reg probe_o_ack_r;

always @(posedge clk)
    if (probe_o_stb)
        probe_o_ack_r <= probe_o_ack;
    else
        probe_o_ack_r <= probe_o_ack_r;            

always @(posedge clk)
    if (rst)        probe_i_stb <= 1'd0;
    else case (fsm)

    FSM_PROBE_REQ:  probe_i_stb <= 1'd1;
    default:        probe_i_stb <= 1'd0;

    endcase

always @(posedge clk)
    case (fsm)

    FSM_INIT:       probe_i_adr <= I2C_BEG_ADDR;
    FSM_NEXT:       probe_i_adr <= probe_i_adr + 1;
    default:        probe_i_adr <= probe_i_adr;

    endcase

// ============================================================================
// Output data formatter
reg        uart_i_stb;
reg  [4:0] uart_i_dat;

always @(posedge clk)
    if (rst) uart_i_stb <= 1'b0;
    else case(fsm)

    FSM_TX_1:   uart_i_stb <= wait_s;
    FSM_TX_2:   uart_i_stb <= wait_s;
    FSM_TX_3:   uart_i_stb <= wait_s;
    FSM_TX_4:   uart_i_stb <= wait_s;
    FSM_TX_5:   uart_i_stb <= wait_s;
    FSM_TX_6:   uart_i_stb <= wait_s;
    default:    uart_i_stb <= 1'b0;

    endcase

always @(posedge clk)
    case(fsm)

    FSM_TX_1:   uart_i_dat <= {2'b0, probe_i_adr[6:4]};
    FSM_TX_2:   uart_i_dat <= {1'b0, probe_i_adr[3:0]};
    FSM_TX_3:   uart_i_dat <= 5'h1F;
    FSM_TX_4:   uart_i_dat <= probe_o_ack_r;
    FSM_TX_5:   uart_i_dat <= 5'h10;
    FSM_TX_6:   uart_i_dat <= 5'h11;

    endcase

// ============================================================================
// UART character mapper
reg         uart_x_stb;
reg  [7:0]  uart_x_dat;

always @(posedge clk)
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

    5'h10:   uart_x_dat <= "\r";
    5'h11:   uart_x_dat <= "\n";

    default: uart_x_dat <= " ";

    endcase

always @(posedge clk or posedge rst)
    if (rst)    uart_x_stb <= 1'd0;
    else        uart_x_stb <= uart_i_stb;

// ============================================================================
// UART

// Baudrate prescaler initializer
reg  [7:0]  reg_div_we_sr;
wire        reg_div_we;

always @(posedge clk or posedge rst)
    if (rst)    reg_div_we_sr <= 8'h01;
    else        reg_div_we_sr <= {reg_div_we_sr[6:0], 1'd0};

assign reg_div_we = reg_div_we_sr[7];

// The UART
simpleuart uart
(
.clk            (clk),
.resetn         (!rst),

.ser_rx         (rx),
.ser_tx         (tx),

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
always @(posedge clk)
    if (uart_x_stb)
        $display("[%02Xh] %c", uart_x_dat, uart_x_dat);

endmodule
