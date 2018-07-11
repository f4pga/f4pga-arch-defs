//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFF_NP1_ (D, C, R, Q)
//-
//- A negative edge D-type flip-flop with positive polarity set.
//-
//- Truth table:    D C R | Q
//-                -------+---
//-                 - - 1 | 1
//-                 d \ - | d
//-                 - - - | q
//-
module \$_DFF_NP1_ (D, C, R, Q);
input D, C, R;
output reg Q;
always @(negedge C or posedge R) begin
	if (R == 1)
		Q <= 1;
	else
		Q <= D;
end
endmodule
