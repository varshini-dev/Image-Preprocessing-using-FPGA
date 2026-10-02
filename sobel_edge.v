// 3x3 Sobel edge detector on an 8-bit grayscale raster stream (W pixels per line).
//   Two line buffers + 3x3 sliding window, |Gx|+|Gy| compared with a threshold.
//   Output pixel is 8'hFF (edge) or 8'h00.  Only pixels with a full 3x3 window are
//   output, so the output frame is (W-2) x (H-2).
// Latency: 4 clocks after the window is filled.
module sobel_edge #(
    parameter W = 32,
    parameter H = 24
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] thresh,
    input  wire       in_valid,
    input  wire [7:0] in_pix,
    output reg        out_valid,
    output reg  [7:0] out_pix
);
    // ---------------- line buffers (infer distributed RAM) ----------------
    reg [7:0] lb1 [0:W-1];          // previous line
    reg [7:0] lb2 [0:W-1];          // line before previous
    integer i;
    initial for (i = 0; i < W; i = i + 1) begin lb1[i] = 8'd0; lb2[i] = 8'd0; end

    reg [11:0] x, y;
    wire [7:0] p1 = lb1[x];         // pixel one row above
    wire [7:0] p2 = lb2[x];         // pixel two rows above

    // ---------------- 3x3 window ----------------
    reg [7:0] w00, w01, w02, w10, w11, w12, w20, w21, w22;
    reg       v1, v2, v3;

    // Sobel sums
    wire [9:0] pa = w02 + {w12,1'b0} + w22;     // right column
    wire [9:0] pb = w00 + {w10,1'b0} + w20;     // left column
    wire [9:0] pc = w20 + {w21,1'b0} + w22;     // bottom row
    wire [9:0] pd = w00 + {w01,1'b0} + w02;     // top row

    reg signed [11:0] gx, gy;
    reg        [12:0] mag;

    wire signed [11:0] gx_n = $signed({2'b00,pa}) - $signed({2'b00,pb});
    wire signed [11:0] gy_n = $signed({2'b00,pc}) - $signed({2'b00,pd});
    wire [11:0] ax = gx[11] ? -gx : gx;
    wire [11:0] ay = gy[11] ? -gy : gy;

    always @(posedge clk) begin
        if (!rst_n) begin
            x <= 0; y <= 0;
            w00<=0; w01<=0; w02<=0; w10<=0; w11<=0; w12<=0; w20<=0; w21<=0; w22<=0;
            v1<=0; v2<=0; v3<=0; gx<=0; gy<=0; mag<=0; out_valid<=0; out_pix<=0;
        end else begin
            // stage 1 : shift window, update line buffers
            if (in_valid) begin
                w00<=w01; w01<=w02; w02<=p2;
                w10<=w11; w11<=w12; w12<=p1;
                w20<=w21; w21<=w22; w22<=in_pix;
                lb2[x] <= p1;
                lb1[x] <= in_pix;
                if (x == W-1) begin x <= 0; y <= (y == H-1) ? 12'd0 : y + 12'd1; end
                else x <= x + 12'd1;
            end
            v1 <= in_valid && (y >= 2) && (x >= 2);
            // stage 2 : gradients
            gx <= gx_n;  gy <= gy_n;  v2 <= v1;
            // stage 3 : magnitude
            mag <= ax + ay;  v3 <= v2;
            // stage 4 : threshold
            out_pix   <= (mag > {5'd0, thresh}) ? 8'hFF : 8'h00;
            out_valid <= v3;
        end
    end
endmodule
