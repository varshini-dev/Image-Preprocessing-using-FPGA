// Free-running synthetic test frame: dark-blue background, bright rectangle.
// One pixel per clock, IN_W x IN_H, repeats forever.
module pattern_gen #(
    parameter IN_W = 64,
    parameter IN_H = 48
)(
    input  wire       clk,
    input  wire       rst_n,
    output reg        valid,
    output reg  [7:0] r, g, b
);
    reg [11:0] x, y;
    wire inside = (x >= 16) && (x <= 47) && (y >= 12) && (y <= 35);
    always @(posedge clk) begin
        if (!rst_n) begin x <= 0; y <= 0; valid <= 0; r <= 0; g <= 0; b <= 0; end
        else begin
            valid <= 1'b1;
            r <= inside ? 8'd200 : 8'd20;
            g <= inside ? 8'd180 : 8'd20;
            b <= inside ? 8'd160 : 8'd60;
            if (x == IN_W-1) begin x <= 0; y <= (y == IN_H-1) ? 12'd0 : y + 12'd1; end
            else x <= x + 12'd1;
        end
    end
endmodule
