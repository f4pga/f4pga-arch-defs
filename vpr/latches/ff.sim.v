`ifdef SIMCELLS_FF
//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_FF_ (D, Q)
//-
//- A D-type flip-flop that is clocked from the implicit global clock. (This cell
//- type is usually only used in netlists for formal verification.)
//-
module \$_FF_ (D, Q);
input D;
output reg Q;
always @($global_clock) begin
	Q <= D;
end
endmodule
`endif
