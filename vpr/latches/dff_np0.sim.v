//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFF_NP0_ (D, C, R, Q)
//-
//- A negative edge D-type flip-flop with positive polarity reset.
//-
//- Truth table:    D C R | Q
//-                -------+---
//-                 - - 1 | 0
//-                 d \ - | d
//-                 - - - | q
//-
module \$_DFF_NP0_ (D, C, R, Q);
input D, C, R;
output reg Q;
always @(negedge C or posedge R) begin
	if (R == 1)
		Q <= 0;
	else
		Q <= D;
end
endmodule
