//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DLATCH_N_ (E, D, Q)
//-
//- A negative enable D-type latch.
//-
//- Truth table:    E D | Q
//-                -----+---
//-                 0 d | d
//-                 - - | q
//-
module \$_DLATCH_N_ (E, D, Q);
input E, D;
output reg Q;
always @* begin
	if (E == 0)
		Q <= D;
end
endmodule
