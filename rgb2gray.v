// RGB888 -> 8-bit grayscale.  Y = (77R + 150G + 29B) >> 8   (77+150+29 = 256)
// Latency: 2 clocks.  Streaming interface: in_valid / out_valid.
module rgb2gray (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       in_valid,
    input  wire [7:0] r,
    input  wire [7:0] g,
    input  wire [7:0] b,
    output reg        out_valid,
    output reg  [7:0] gray
);
    reg [15:0] sum;
    reg        v1;
    always @(posedge clk) begin
        if (!rst_n) begin
            sum <= 16'd0; v1 <= 1'b0; gray <= 8'd0; out_valid <= 1'b0;
        end else begin
            sum       <= r * 8'd77 + g * 8'd150 + b * 8'd29;   // stage 1 (DSP / LUT multipliers)
            v1        <= in_valid;
            gray      <= sum[15:8];                            // stage 2
            out_valid <= v1;
        end
    end
endmodule
