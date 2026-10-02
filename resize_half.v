// Image down-scaler by 2 in X and Y (nearest-neighbour decimation).
// Keeps the pixel only when x and y are both even  ->  IN_W x IN_H  becomes (IN_W/2) x (IN_H/2).
// Counters follow the incoming valid pixels and wrap at the frame end.
module resize_half #(
    parameter IN_W = 64,
    parameter IN_H = 48
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       in_valid,
    input  wire [7:0] in_pix,
    output reg        out_valid,
    output reg  [7:0] out_pix
);
    reg [11:0] x, y;
    always @(posedge clk) begin
        if (!rst_n) begin
            x <= 12'd0; y <= 12'd0; out_valid <= 1'b0; out_pix <= 8'd0;
        end else begin
            out_valid <= in_valid & ~x[0] & ~y[0];
            if (in_valid) begin
                out_pix <= in_pix;
                if (x == IN_W-1) begin
                    x <= 12'd0;
                    y <= (y == IN_H-1) ? 12'd0 : y + 12'd1;
                end else
                    x <= x + 12'd1;
            end
        end
    end
endmodule
