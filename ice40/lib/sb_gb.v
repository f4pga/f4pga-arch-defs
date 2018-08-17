SB_GB My_Global_Buffer_i ( //Required for a user’s internally generated
//FPGA signal that is heavily loaded and
//requires global buffering. For example, a
//user’s logic-generated clock.
.USER_SIGNAL_TO_GLOBAL_BUFFER (Users_internal_Clk),
.GLOBAL_BUFFER_OUTPUT ( Global_Buffered_User_Signal)
);

module SB_GB (
	input  USER_SIGNAL_TO_GLOBAL_BUFFER,
	output GLOBAL_BUFFER_OUTPUT
);
	assign GLOBAL_BUFFER_OUTPUT = USER_SIGNAL_TO_GLOBAL_BUFFER;
endmodule
