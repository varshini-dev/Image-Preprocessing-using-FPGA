// Counts edge pixels in each output frame and latches the result (shown on LEDs).
module edge_counter #(
    parameter N_PIX = 660        // pixels per edge frame = (IN_W/2-2)*(IN_H/2-2)
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        edge_valid,
    input  wire [7:0]  edge_pix,
    output reg  [15:0] frame_count   // edge pixels in the last complete frame
);
    reg [15:0] cnt;
    reg [15:0] n;
    always @(posedge clk) begin
        if (!rst_n) begin cnt <= 0; n <= 0; frame_count <= 0; end
        else if (edge_valid) begin
            if (n == N_PIX-1) begin
                frame_count <= cnt + (edge_pix != 0);
                cnt <= 0; n <= 0;
            end else begin
                n <= n + 1;
                if (edge_pix != 0) cnt <= cnt + 1;
            end
        end
    end
endmodule
