module top(input count, count_sw, thresh_sw, output gtu, gts, ltu, lts, geu, ges, leu, les);
    reg [7:0] threshold = 8'b0;
    reg [7:0] counter = 8'b0;

    wire clk;
    BUFG bufg(.I(count), .O(clk));

    always @(posedge clk) begin
        if (count_sw) begin
            counter <= counter - 1;
        end else begin
            counter <= counter + 1;
        end

        if (thresh_sw) begin
            threshold <= threshold + 1;
        end
    end

    assign gtu = counter > threshold;
    assign gts = $signed(counter) > $signed(threshold);
    assign ltu = counter < threshold;
    assign lts = $signed(counter) < $signed(threshold);
    assign geu = counter >= threshold;
    assign ges = $signed(counter) >= $signed(threshold);
    assign leu = counter <= threshold;
    assign les = $signed(counter) <= $signed(threshold);
endmodule
