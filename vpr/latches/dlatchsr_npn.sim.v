//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DLATCHSR_NPN_ (E, S, R, D, Q)
//-
//- A negative enable D-type latch with positive polarity set and negative polarity
//- reset.
//-
//- Truth table:    E S R D | Q
//-                ---------+---
//-                 - - 0 - | 0
//-                 - 1 - - | 1
//-                 0 - - d | d
//-                 - - - - | q
//-
module \$_DLATCHSR_NPN_ (E, S, R, D, Q);
input E, S, R, D;
output reg Q;
always @* begin
	if (R == 0)
		Q <= 0;
	else if (S == 1)
		Q <= 1;
	else if (E == 0)
		Q <= D;
end
endmodule
