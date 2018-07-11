//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFF_N_ (D, C, Q)
//-
//- A negative edge D-type flip-flop.
//-
//- Truth table:    D C | Q
//-                -----+---
//-                 d \ | d
//-                 - - | q
//-
module \$_DFF_N_ (D, C, Q);
input D, C;
output reg Q;
always @(negedge C) begin
	Q <= D;
end
endmodule
