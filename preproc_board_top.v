// Board-level top (RTL flow).  sw[7:0] = edge threshold, sw[9:8] = LED view:
//   00 : edge pixel count          (expected 0x0070 for the built-in test image, thresh 64)
//   01 : {xmax, xmin}  bounding box (expected 0x1706)
//   10 : {ymax, ymin}  bounding box (expected 0x1104)
//   11 : {15'b0, found}
module preproc_board_top (
    input  wire        clk100,
    input  wire        btnC,          // reset (active high)
    input  wire [9:0]  sw,
    output reg  [15:0] led
);
    reg [2:0] rs = 3'b000;
    always @(posedge clk100) rs <= {rs[1:0], ~btnC};
    wire rst_n = rs[2];

    wire v; wire [7:0] r, g, b;
    wire gv, ev; wire [7:0] gp, ep;
    wire [15:0] cnt;
    wire [7:0] xmin, xmax, ymin, ymax; wire found, fdone;

    pattern_gen   #(.IN_W(64), .IN_H(48)) u_gen (.clk(clk100), .rst_n(rst_n), .valid(v), .r(r), .g(g), .b(b));
    preproc_top   #(.IN_W(64), .IN_H(48)) u_pre (.clk(clk100), .rst_n(rst_n), .thresh(sw[7:0]),
                    .in_valid(v), .r(r), .g(g), .b(b),
                    .gray_valid(gv), .gray_pix(gp), .edge_valid(ev), .edge_pix(ep));
    edge_counter  #(.N_PIX(30*22)) u_cnt (.clk(clk100), .rst_n(rst_n), .edge_valid(ev), .edge_pix(ep), .frame_count(cnt));
    edge_bbox     #(.W_OUT(30), .H_OUT(22)) u_bbox (.clk(clk100), .rst_n(rst_n), .edge_valid(ev), .edge_pix(ep),
                    .xmin(xmin), .xmax(xmax), .ymin(ymin), .ymax(ymax), .found(found), .frame_done(fdone));

    always @(*) case (sw[9:8])
        2'b00:   led = cnt;
        2'b01:   led = {xmax, xmin};
        2'b10:   led = {ymax, ymin};
        default: led = {15'b0, found};
    endcase
endmodule
