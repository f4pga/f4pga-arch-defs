module top(input count, count_sw, thresh_sw,
    output gtu, gts, ltu, lts, geu, ges, leu, les, zero, max,
    output gtu_n, gts_n, ltu_n, lts_n, geu_n, ges_n, leu_n, les_n, zero_n, max_n
);
    reg [31:0] threshold = 32'b0;
    reg [31:0] threshold_down = 32'b0;
    reg [31:0] counter = 32'b0;
    reg [31:0] counter_down = 32'b0;

    wire clk;
    BUFG bufg(.I(count), .O(clk));

    always @(posedge clk) begin
        if (count_sw) begin
            counter <= counter + 1;
            counter_down <= counter_down - 1;
        end

        if (thresh_sw) begin
            threshold <= counter - 32'd31;
            threshold_down <= counter_down + 32'd31;
        end else begin
            threshold <= threshold + 1;
            threshold_down <= threshold_down - 1;
        end
    end

    assign zero = counter == 32'b0;
    assign max = counter == 32'hFFFFFFFF;
    assign gtu = counter > threshold;
    assign gts = $signed(counter) > $signed(threshold);
    assign ltu = counter < threshold;
    assign lts = $signed(counter) < $signed(threshold);
    assign geu = counter >= threshold;
    assign ges = $signed(counter) >= $signed(threshold);
    assign leu = counter <= threshold;
    assign les = $signed(counter) <= $signed(threshold);

    assign zero_n = counter_down == 32'b0;
    assign max_n = counter_down == 32'hFFFFFFFF;
    assign gtu_n = counter_down > threshold_down;
    assign gts_n = $signed(counter_down) > $signed(threshold_down);
    assign ltu_n = counter_down < threshold_down;
    assign lts_n = $signed(counter_down) < $signed(threshold_down);
    assign geu_n = counter_down >= threshold_down;
    assign ges_n = $signed(counter_down) >= $signed(threshold_down);
    assign leu_n = counter_down <= threshold_down;
    assign les_n = $signed(counter_down) <= $signed(threshold_down);
endmodule
