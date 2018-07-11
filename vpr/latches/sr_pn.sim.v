//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_SR_PN_ (S, R, Q)
//-
//- A set-reset latch with positive polarity SET and negative polarioty RESET.
//-
//- Truth table:    S R | Q
//-                -----+---
//-                 1 0 | x
//-                 1 1 | 1
//-                 0 0 | 0
//-                 0 1 | y
//-
module \$_SR_PN_ (S, R, Q);
input S, R;
output reg Q;
always @(posedge S, negedge R) begin
	if (R == 0)
		Q <= 0;
	else if (S == 1)
		Q <= 1;
end
endmodule
