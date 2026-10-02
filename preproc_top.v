// Real-time object-detection pre-processing pipeline:
//   RGB888 -> grayscale -> resize (/2) -> Sobel edge map
module preproc_top #(
    parameter IN_W = 64,
    parameter IN_H = 48
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] thresh,
    input  wire       in_valid,
    input  wire [7:0] r, g, b,
    output wire       gray_valid,
    output wire [7:0] gray_pix,
    output wire       edge_valid,
    output wire [7:0] edge_pix
);
    wire       rs_valid;  wire [7:0] rs_pix;

    rgb2gray u_gray (.clk(clk), .rst_n(rst_n), .in_valid(in_valid),
                     .r(r), .g(g), .b(b), .out_valid(gray_valid), .gray(gray_pix));

    resize_half #(.IN_W(IN_W), .IN_H(IN_H)) u_resize (
                     .clk(clk), .rst_n(rst_n), .in_valid(gray_valid), .in_pix(gray_pix),
                     .out_valid(rs_valid), .out_pix(rs_pix));

    sobel_edge #(.W(IN_W/2), .H(IN_H/2)) u_sobel (
                     .clk(clk), .rst_n(rst_n), .thresh(thresh),
                     .in_valid(rs_valid), .in_pix(rs_pix),
                     .out_valid(edge_valid), .out_pix(edge_pix));
endmodule
