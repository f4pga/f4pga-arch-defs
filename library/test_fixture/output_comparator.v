module OUTPUT_COMPARATOR(
    input [N_OUTPUTS-1:0] expected_output,
    input [N_OUTPUTS-1:0] actual_output,
    output error
);

parameter N_OUTPUTS = 1;

assign error = expected_output == actual_output;

endmodule
