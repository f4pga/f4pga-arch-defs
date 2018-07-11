//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFFE_NP_ (D, C, E, Q)
//-
//- A negative edge D-type flip-flop with positive polarity enable.
//-
//- Truth table:    D C E | Q
//-                -------+---
//-                 d \ 1 | d
//-                 - - - | q
//-
module \$_DFFE_NP_ (D, C, E, Q);
input D, C, E;
output reg Q;
always @(negedge C) begin
	if (E) Q <= D;
end
endmodule
