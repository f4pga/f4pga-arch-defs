//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFF_P_ (D, C, Q)
//-
//- A positive edge D-type flip-flop.
//-
//- Truth table:    D C | Q
//-                -----+---
//-                 d / | d
//-                 - - | q
//-
module \$_DFF_P_ (D, C, Q);
input D, C;
output reg Q;
always @(posedge C) begin
	Q <= D;
end
endmodule
