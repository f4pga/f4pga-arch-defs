`include "./logic_0_cell.sim.v"

(* keep_hierarchy *)
module LOGIC_0 (
    output wire a
);

    LOGIC_0_CELL gnd (.a(a));

endmodule
