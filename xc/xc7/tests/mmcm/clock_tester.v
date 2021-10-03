module clock_tester #(
parameter COUNT = 25000000
)
(
    input  wire clk,        // board oscillator
    output reg  led    // pixel clock
    );

    reg [31:0] clk_count = 0; 

    always @(posedge clk) begin
        if (clk_count == COUNT)begin
            clk_count <= 0;
            
            if(led == 0) begin
                led <= 1;
            end
            else begin
                led <= 0;
            end
        end
        else begin
            clk_count <= clk_count + 1;
        end
    end
endmodule
