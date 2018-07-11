//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_SR_NN_ (S, R, Q)
//-
//- A set-reset latch with negative polarity SET and RESET.
//-
//- Truth table:    S R | Q
//-                -----+---
//-                 0 0 | x
//-                 0 1 | 1
//-                 1 0 | 0
//-                 1 1 | y
//-
module \$_SR_NN_ (S, R, Q);
input S, R;
output reg Q;
always @(negedge S, negedge R) begin
	if (R == 0)
		Q <= 0;
	else if (S == 0)
		Q <= 1;
end
endmodule
