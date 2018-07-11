//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFFE_PP_ (D, C, E, Q)
//-
//- A positive edge D-type flip-flop with positive polarity enable.
//-
//- Truth table:    D C E | Q
//-                -------+---
//-                 d / 1 | d
//-                 - - - | q
//-
module \$_DFFE_PP_ (D, C, E, Q);
input D, C, E;
output reg Q;
always @(posedge C) begin
	if (E) Q <= D;
end
endmodule
