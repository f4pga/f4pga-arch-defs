//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFF_NN0_ (D, C, R, Q)
//-
//- A negative edge D-type flip-flop with negative polarity reset.
//-
//- Truth table:    D C R | Q
//-                -------+---
//-                 - - 0 | 0
//-                 d \ - | d
//-                 - - - | q
//-
module \$_DFF_NN0_ (D, C, R, Q);
input D, C, R;
output reg Q;
always @(negedge C or negedge R) begin
	if (R == 0)
		Q <= 0;
	else
		Q <= D;
end
endmodule
