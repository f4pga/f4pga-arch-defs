`timescale 1ns/1ps

// ============================================================================

module i2c_probe (
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

    // Probe control
    input  wire         i_stb,
    input  wire [6:0]   i_adr,
    output reg          i_bsy,

    // Probe result
    output reg          o_stb,
    output reg          o_ack
);

// ============================================================================

// I2C prescaler
parameter [15:0] I2C_PRESCALER = 1;

// ============================================================================
// The I2C master controller
reg  [6:0]  i2c_cmd_address;
reg         i2c_cmd_write;
reg         i2c_cmd_start;
reg         i2c_cmd_stop;
reg         i2c_cmd_valid;
wire        i2c_cmd_ready;

wire        i2c_dat_in_valid;
wire        i2c_dat_in_ready;

wire        i2c_missed_ack;

i2c_master i2c_master (
.clk                (clk),
.rst                (rst),

.scl_i              (scl_i),
.scl_o              (scl_o),
.scl_t              (scl_t),
.sda_i              (sda_i),
.sda_o              (sda_o),
.sda_t              (sda_t),

.cmd_address        (i2c_cmd_address),
.cmd_start          (i2c_cmd_start),
.cmd_read           (1'b0),
.cmd_write          (i2c_cmd_write),
.cmd_write_multiple (1'b0),
.cmd_stop           (i2c_cmd_stop),
.cmd_valid          (i2c_cmd_valid),
.cmd_ready          (i2c_cmd_ready),

.data_in            (8'hFF),
.data_in_valid      (i2c_dat_in_valid),
.data_in_ready      (i2c_dat_in_ready),
.data_in_last       (1'b1),

.data_out           (),
.data_out_valid     (),
.data_out_ready     (1'b1),
.data_out_last      (),

.missed_ack         (i2c_missed_ack),

.prescale           (I2C_PRESCALER),
.stop_on_idle       (1'b0)
);

assign i2c_dat_in_valid = i2c_dat_in_ready;

// ============================================================================
// The control FSM
localparam SCAN_IDLE    = 'h00;
localparam SCAN_WAIT    = 'h10;
localparam SCAN_I2C_WR  = 'h20;
localparam SCAN_I2C_WRn = 'h21;
localparam SCAN_I2C_SP  = 'h30;
localparam SCAN_I2C_SPn = 'h31;
localparam SCAN_OUT     = 'h40;

integer fsm;
initial fsm <= 'd0;

always @(posedge clk)
    if (rst) fsm <= SCAN_IDLE;
    else case (fsm)

    SCAN_IDLE:    if (i_stb) fsm <= SCAN_WAIT;
                  else fsm <= fsm;

    SCAN_WAIT:    if ( i2c_cmd_ready) fsm <= SCAN_I2C_WR;
                  else fsm <= fsm;

    SCAN_I2C_WR:  if ( i2c_cmd_ready) fsm <= SCAN_I2C_WRn;
                  else fsm <= fsm;

    SCAN_I2C_WRn: if (!i2c_cmd_ready) fsm <= SCAN_I2C_SP;
                  else fsm <= fsm;

    SCAN_I2C_SP:  if ( i2c_cmd_ready) fsm <= SCAN_I2C_SPn;
                  else fsm <= fsm;

    SCAN_I2C_SPn: if (!i2c_cmd_ready) fsm <= SCAN_OUT;
                  else fsm <= fsm;

    SCAN_OUT:     fsm <= SCAN_IDLE;

    default: fsm <= fsm;

    endcase

// ============================================================================
// I2C module control


always @(posedge clk)
    if (rst)    i2c_cmd_valid <= 1'b0;
    else case (fsm)

    SCAN_I2C_WR:  i2c_cmd_valid <= i2c_cmd_ready;
    SCAN_I2C_WRn: i2c_cmd_valid <= i2c_cmd_ready;
    SCAN_I2C_SP:  i2c_cmd_valid <= i2c_cmd_ready;
    SCAN_I2C_SPn: i2c_cmd_valid <= i2c_cmd_ready;
    default:      i2c_cmd_valid <= 1'b0;

    endcase

always @(posedge clk)
    if (rst)      i2c_cmd_write <= 1'b0;
    else case (fsm)

    SCAN_I2C_WR:  i2c_cmd_write <= i2c_cmd_ready;
    SCAN_I2C_WRn: i2c_cmd_write <= i2c_cmd_ready;
    default:      i2c_cmd_write <= 1'b0;

    endcase

always @(posedge clk)
    if (rst)      i2c_cmd_stop <= 1'b0;
    else case (fsm)

    SCAN_I2C_SP:  i2c_cmd_stop <= i2c_cmd_ready;
    SCAN_I2C_SPn: i2c_cmd_stop <= i2c_cmd_ready;
    default:      i2c_cmd_stop <= 1'b0;

    endcase

// ============================================================================
// ACK/NAK reception
reg did_ack;

always @(posedge clk)
    if (rst)                  did_ack <= 1'b0;
    else if(i2c_dat_in_ready) did_ack <= !i2c_missed_ack;
    else                      did_ack <= did_ack;

// ============================================================================
// Input

always @(posedge clk)
    case (fsm)

    SCAN_IDLE:  if(i_stb) i2c_cmd_address <= i_adr;
                else      i2c_cmd_address <= i2c_cmd_address;
    default:    i2c_cmd_address <= i2c_cmd_address;

    endcase

always @(posedge clk)
    if (rst)    i_bsy <= 1'b0;
    else case (fsm)

    SCAN_IDLE:  i_bsy <= i_stb;
    SCAN_OUT:   i_bsy <= 1'b0;
    default:    i_bsy <= i_bsy;

    endcase

// ============================================================================
// Output

always @(posedge clk)
    if (rst)    o_stb <= 1'b0;
    else case (fsm)

    SCAN_OUT:   o_stb <= 1'b1;
    default:    o_stb <= 1'b0;

    endcase

always @(posedge clk)
    case (fsm)

    SCAN_OUT:   o_ack <= did_ack;
    default:    o_ack <= o_ack;

    endcase

endmodule
