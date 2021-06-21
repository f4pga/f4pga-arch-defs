// This program is written in order to test the FSM capabilty 
// of the system.


// This is a test program based on the lemmings game.
// Lemmings can walk, fall, and dig, Lemmings aren't invulnerable. 
// If a Lemming falls for too long then hits the ground, it can splatter.
// In particular, if a Lemming falls for more than 20 clock cycles then hits the ground,
// it will splatter and cease walking, falling, or digging (all 4 outputs become 0),
// forever (Or until the FSM gets reset). There is no upper limit on how far a Lemming 
// can fall before hitting the ground. Lemmings only splatter when hitting the ground; they do not splatter in mid-air.
module top_module(
    input wire clk,
    input wire [4:0] sw,    // Freshly brainwashed Lemmings walk left.
    output wire [3:0] led); 
    wire areset, bump_left, bump_right, ground, dig;
    wire walk_left, walk_right, falling, digging;
    assign areset = sw[0];
    assign bump_left = sw[1];
    assign bump_right = sw[2];
    assign ground = sw[3];
    assign dig = sw[4];
    assign led[0] = walk_left;
    assign led[1] = walk_right;
    assign led[2] = falling;
    assign led[3] = digging;
    parameter L = 0, R = 1, FL = 2, FR = 3, DL = 4, DR = 5, SP = 6;
    int count = 0;
    reg [2:0] state, next_state;
    // state flip flop
    always @ (posedge clk, posedge areset) begin
        if (areset) 
            state <= 0;
        else 
            state <= next_state;
    end
    // state transition
    always @ (*)  begin
        case (state)
            L : next_state = (ground == 0) ? FL : (dig ? DL : (bump_left ? R : L));
            R : next_state = (ground == 0) ? FR : (dig ? DR : (bump_right ? L : R));
            FL : next_state = (ground) ? ((count > 19) ? SP : L) : FL;
            FR : next_state = (ground) ? ((count > 19) ? SP : R) : FR;
            DL : next_state = (ground == 0) ? FL : DL;
            DR : next_state = (ground == 0) ? FR : DR;
            SP : next_state = SP;
        endcase
    end
    
    always @ (posedge clk) begin
        if (state == FL || state == FR)
            count = count + 1;
        else 
            count = 0;
    end
    // output
    assign walk_left = (state == L);
    assign walk_right = (state == R);
    assign falling = (state == FL) | (state == FR) ;
    assign digging = (state == DL) | (state == DR);

endmodule