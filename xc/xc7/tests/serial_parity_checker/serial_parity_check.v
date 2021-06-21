// This test checks the parity checker of the dsp

// We want to add parity checking to the serial receiver. 
// Parity checking adds one extra bit after each data byte. 
// We will use odd parity, where the number of 1s in the 9 bits received must be odd.
// For example, 101001011 satisfies odd parity (there are 5 1s), but 001001011 does not.

// FSM and datapath are to perform odd parity checking. 
// Asserting the done signal only if a byte is correctly received and its parity check passes.
// Like the serial receiver FSM, this FSM needs to identify the start bit, wait for all 9 (data and parity) bits, 
// then verify that the stop bit was correct. If the stop bit does not appear when expected,
// the FSM must wait until it finds a stop bit before attempting to receive the next byte.

// The following module that can be used to calculate the parity of the input stream (It's a TFF with reset). 
// The intended use is that it should be given the input bit stream, and reset at appropriate
// times so it counts the number of 1 bits in each byte.


// Note that the serial protocol sends the least significant bit first, and the parity bit after the 8 data bits.

module top_module(
    input clk,
    input [1:0] sw,
    output [8:0] led
); //
    wire in, reset;
    wire [7:0] out_byte;
    wire done;
    assign reset = sw[1]; // Synchronous reset
    assign in = sw[0];
    assign led = (done,out_byte}; 
        
    parameter idle = 4'd0, start = 4'd1, trans0 = 4'd2,trans1 = 4'd3, trans2 = 4'd4, trans3 = 4'd5;
    parameter trans4 = 4'd6, trans5 = 4'd7, trans6 = 4'd8, trans7 = 4'd9, stop = 4'd10, err = 4'd11, pari = 4'd12;
    reg [3:0] state, next_state;
    reg [7:0] data;
    wire odd, reset_p;
    reg done_reg;

    always @(*) begin
        case (state)
            idle:   next_state <= in ? idle : start;
            start:  next_state <= trans0;
            trans0: next_state <= trans1;
            trans1: next_state <= trans2;
            trans2: next_state <= trans3;
            trans3: next_state <= trans4;
            trans4: next_state <= trans5;
            trans5: next_state <= trans6;
            trans6: next_state <= trans7;
            trans7: next_state <= pari;
            pari:   next_state <= in ? idle : err;
            err:    next_state <= in ? idle : err;
        endcase
    end

    always @(posedge clk) begin
        if (reset) begin
            state <= idle;
        end
        else begin
            state <= next_state;
        end
    end

    // New: Add parity checking.
    always @(posedge clk) begin
        if (reset) begin
            data <= 8'd0;
            reset_p <= 1'b1;
            done_reg <= 1'b0;
        end
        else begin
            if (next_state == trans0 || next_state == trans1 || next_state == trans2 || next_state == trans3 || next_state == trans4 || next_state == trans5 || next_state == trans6 || next_state == trans7) begin
                data <= {in, data[7:1]};
            end
            else if (next_state == start) begin
                data <= 8'd0;
                reset_p <= 1'b0;
                done_reg <= 1'b0;
            end
            else if (next_state == idle) begin
                done_reg <= odd;
            end
            else if (next_state == pari) begin
                reset_p <= 1'b1;
            end
        end
    end

    assign done = done_reg;
    assign out_byte = done ? data : 8'd0;
    parity par_mod(clk, reset | reset_p, in, odd);

endmodule


module parity (
    input clk,
    input reset,
    input in,
    output reg odd);

    always @(posedge clk)
        if (reset) odd <= 0;
        else if (in) odd <= ~odd;

endmodule
