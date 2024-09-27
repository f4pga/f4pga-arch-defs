task tbassert(input a, input reg [512:0] s);
begin
    if (a==0) begin
        $display("**********************************************************");
        $display("* ASSERT FAILURE (@%d): %-s", $time, s);
        $display("**********************************************************");
        $dumpflush;
        $finish_and_return(-1);
    end
end
endtask
