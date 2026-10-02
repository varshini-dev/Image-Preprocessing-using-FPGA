// NOVELTY (T3): edge-based object localisation.
// Tracks the bounding box of all edge pixels in each (W_OUT x H_OUT) edge frame and latches
// xmin/xmax/ymin/ymax at the end of the frame.  Coordinates are in edge-map pixels;
// original-image coordinates are  x_img = 2*(x+1),  y_img = 2*(y+1)  (resize x2, 3x3 window centre).
// Hardware cost: 4 registers + comparators, no frame buffer, 1 pixel/clock.
module edge_bbox #(
    parameter W_OUT = 30,        // IN_W/2 - 2
    parameter H_OUT = 22         // IN_H/2 - 2
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       edge_valid,
    input  wire [7:0] edge_pix,
    output reg  [7:0] xmin, xmax, ymin, ymax,
    output reg        found,        // 1 = at least one edge pixel in the last frame
    output reg        frame_done    // 1-clock pulse when the bbox registers are updated
);
    reg [7:0] cx, cy;
    reg [7:0] rxmin, rxmax, rymin, rymax;
    reg       rfound;

    wire upd  = edge_valid & (edge_pix != 8'd0);
    wire last = edge_valid & (cx == W_OUT-1) & (cy == H_OUT-1);

    wire [7:0] nxmin = upd ? ((!rfound || cx < rxmin) ? cx : rxmin) : rxmin;
    wire [7:0] nxmax = upd ? ((!rfound || cx > rxmax) ? cx : rxmax) : rxmax;
    wire [7:0] nymin = upd ? ((!rfound) ? cy : rymin) : rymin;      // raster order: first hit = min y
    wire [7:0] nymax = upd ? cy : rymax;                            // last hit  = max y
    wire       nfound = rfound | upd;

    always @(posedge clk) begin
        if (!rst_n) begin
            cx <= 0; cy <= 0; rxmin <= 0; rxmax <= 0; rymin <= 0; rymax <= 0; rfound <= 0;
            xmin <= 0; xmax <= 0; ymin <= 0; ymax <= 0; found <= 0; frame_done <= 0;
        end else begin
            frame_done <= 1'b0;
            if (edge_valid) begin
                if (cx == W_OUT-1) begin cx <= 0; cy <= (cy == H_OUT-1) ? 8'd0 : cy + 8'd1; end
                else cx <= cx + 8'd1;
            end
            if (last) begin
                xmin <= nxmin; xmax <= nxmax; ymin <= nymin; ymax <= nymax; found <= nfound;
                frame_done <= 1'b1;
                rfound <= 1'b0; rxmin <= 0; rxmax <= 0; rymin <= 0; rymax <= 0;
            end else begin
                rxmin <= nxmin; rxmax <= nxmax; rymin <= nymin; rymax <= nymax; rfound <= nfound;
            end
        end
    end
endmodule
