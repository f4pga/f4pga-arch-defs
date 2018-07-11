//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DLATCH_P_ (E, D, Q)
//-
//- A positive enable D-type latch.
//-
//- Truth table:    E D | Q
//-                -----+---
//-                 1 d | d
//-                 - - | q
//-
module \$_DLATCH_P_ (E, D, Q);
input E, D;
output reg Q;
always @* begin
	if (E == 1)
		Q <= D;
end
endmodule
