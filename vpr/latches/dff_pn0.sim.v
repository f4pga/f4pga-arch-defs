//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFF_PN0_ (D, C, R, Q)
//-
//- A positive edge D-type flip-flop with negative polarity reset.
//-
//- Truth table:    D C R | Q
//-                -------+---
//-                 - - 0 | 0
//-                 d / - | d
//-                 - - - | q
//-
module \$_DFF_PN0_ (D, C, R, Q);
input D, C, R;
output reg Q;
always @(posedge C or negedge R) begin
	if (R == 0)
		Q <= 0;
	else
		Q <= D;
end
endmodule
