module RESET_CONTROLLER(
    input clk,
    input rx_data_ready,
    input [7:0] rx_data,
    input do_reset,
    output rst
);

reg rst_register = 1;

assign rst = rst_register;

always @(posedge clk) begin
    if(!do_reset && !rx_data_ready) begin
        rst_register <= 0;
    end else if(do_reset) begin
        rst_register <= 1;
    end else if(rx_data_ready && rx_data == 114) begin
        // Upon receipt of 'r', do a reset
        rst_register <= 1;
    end
end

endmodule
