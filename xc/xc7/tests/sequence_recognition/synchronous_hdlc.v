// This test is inorder to check the FsM capability of the system


// Synchronous HDLC framing involves decoding a continuous bit stream of data to look for bit patterns
// that indicate the beginning and end of frames (packets). Seeing exactly 6 consecutive 1s (i.e., 01111110)
// is a "flag" that indicate frame boundaries. To avoid the data stream from accidentally containing "flags",
// the sender inserts a zero after every 5 consecutive 1s which the receiver must detect and discard.
// We also need to signal an error if there are 7 or more consecutive 1s.

// Creating a finite state machine to recognize these three sequences:

// 0111110: Signal a bit needs to be discarded (disc).
// 01111110: Flag the beginning/end of a frame (flag).
// 01111111...: Error (7 or more 1s) (err).
// When the FSM is reset, it should be in a state that behaves as though the previous input were 0.

module top_module(
    input clk,
    input [1:0] sw,
    output [2:0] led);
    wire reset, in, disc, flag, err;
    assign reset = sw[1];
    assign in = sw[0];
    assign led = {disc, flag, err};
    parameter no = 0, one = 1, two = 2, thr = 3, fou = 4, fiv = 5, six = 6, sev = 7, error = 8, dis = 9 , flg = 10;
    reg [3:0] state, next_state;
    // state transition
    always @ (*) begin
        case (state)
            no : next_state = in ? one : no;
            one : next_state = in ? two : no;
            two : next_state = in ? thr : no;
            thr : next_state = in ? fou : no;
            fou : next_state = in ? fiv : no;
            fiv : next_state = in ? six : dis;
            six : next_state = in ? error : flg;
            error : next_state = in ? error : no;
            dis : next_state = in ? one : no;
            flg : next_state = in ? one : no;
        endcase
    end
    // state flip flop
    always @ (posedge clk) begin
        if (reset)
            state <= no;
        else
            state <= next_state;
    end
    
    // output
    assign disc = (state == dis);
    assign flag = (state == flg);
    assign err = (state == error);

endmodule
