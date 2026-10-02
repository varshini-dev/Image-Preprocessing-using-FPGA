// Board-level top (RTL flow).  If you use IP Integrator, build this same structure in a block design instead.
module preproc_board_top (
    input  wire        clk100,
    input  wire        btnC,          // reset (active high)
    input  wire [7:0]  sw,            // edge threshold
    output wire [15:0] led            // edge-pixel count of last frame
);
    reg [2:0] rs = 3'b000;
    always @(posedge clk100) rs <= {rs[1:0], ~btnC};
    wire rst_n = rs[2];

    wire v; wire [7:0] r, g, b;
    wire gv, ev; wire [7:0] gp, ep;

    pattern_gen   #(.IN_W(64), .IN_H(48)) u_gen (.clk(clk100), .rst_n(rst_n), .valid(v), .r(r), .g(g), .b(b));
    preproc_top   #(.IN_W(64), .IN_H(48)) u_pre (.clk(clk100), .rst_n(rst_n), .thresh(sw),
                    .in_valid(v), .r(r), .g(g), .b(b),
                    .gray_valid(gv), .gray_pix(gp), .edge_valid(ev), .edge_pix(ep));
    edge_counter  #(.N_PIX(30*22)) u_cnt (.clk(clk100), .rst_n(rst_n), .edge_valid(ev), .edge_pix(ep), .frame_count(led));
endmodule
