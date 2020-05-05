module ql_mux2_x2(
					input s ,
					input i0,
                    input i1,
                    output z 
					);

assign   z = s ? i1: i0;

endmodule 