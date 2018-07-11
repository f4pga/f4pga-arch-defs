//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_SR_PP_ (S, R, Q)
//-
//- A set-reset latch with positive polarity SET and RESET.
//-
//- Truth table:    S R | Q
//-                -----+---
//-                 1 1 | x
//-                 1 0 | 1
//-                 0 1 | 0
//-                 0 0 | y
//-
module \$_SR_PP_ (S, R, Q);
input S, R;
output reg Q;
always @(posedge S, posedge R) begin
	if (R == 1)
		Q <= 0;
	else if (S == 1)
		Q <= 1;
end
endmodule
