`include "logic_1_cell.sim.v"

(* keep_hierarchy *)
module LOGIC_1 (
    output wire a
);

    LOGIC_1_CELL logic_1 (.a(a));

endmodule
