//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_SR_NP_ (S, R, Q)
//-
//- A set-reset latch with negative polarity SET and positive polarioty RESET.
//-
//- Truth table:    S R | Q
//-                -----+---
//-                 0 1 | x
//-                 0 0 | 1
//-                 1 1 | 0
//-                 1 0 | y
//-
module \$_SR_NP_ (S, R, Q);
input S, R;
output reg Q;
always @(negedge S, posedge R) begin
	if (R == 1)
		Q <= 0;
	else if (S == 0)
		Q <= 1;
end
endmodule
