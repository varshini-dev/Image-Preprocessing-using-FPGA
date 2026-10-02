`timescale 1ns/1ps
// Self-checking testbench: compares DUT against a behavioural golden model, 2 frames
// (frame 1: back-to-back pixels, frame 2: random gaps in in_valid).  Writes edge_out.txt.
module tb_preproc;
    localparam IN_W = 64, IN_H = 48, OW = IN_W/2, OH = IN_H/2;
    localparam NOUT = (OW-2)*(OH-2);
    reg clk = 0, rst_n = 0;
    always #5 clk = ~clk;                       // 100 MHz

    reg        in_valid = 0;
    reg  [7:0] r = 0, g = 0, b = 0;
    reg  [7:0] thresh = 8'd64;
    wire       gv, ev; wire [7:0] gp, ep;

    preproc_top #(.IN_W(IN_W), .IN_H(IN_H)) dut (.clk(clk), .rst_n(rst_n), .thresh(thresh),
        .in_valid(in_valid), .r(r), .g(g), .b(b),
        .gray_valid(gv), .gray_pix(gp), .edge_valid(ev), .edge_pix(ep));

    // ---------- image + golden model ----------
    reg [7:0] R [0:IN_W*IN_H-1], G [0:IN_W*IN_H-1], B [0:IN_W*IN_H-1];
    reg [7:0] sm [0:OW*OH-1];
    reg [7:0] gold  [0:NOUT-1];
    integer x, y, k, gxv, gyv, m, n_edge_gold;

    function [7:0] gray_f(input [7:0] rr, gg, bb);
        reg [15:0] s;
        begin s = rr*77 + gg*150 + bb*29; gray_f = s[15:8]; end
    endfunction

    task build_golden;
        begin
            for (y = 0; y < IN_H; y = y + 1)
                for (x = 0; x < IN_W; x = x + 1) begin
                    if (x>=16 && x<=47 && y>=12 && y<=35) begin R[y*IN_W+x]=200; G[y*IN_W+x]=180; B[y*IN_W+x]=160; end
                    else begin R[y*IN_W+x]=20; G[y*IN_W+x]=20; B[y*IN_W+x]=60; end
                end
            for (y = 0; y < OH; y = y + 1)
                for (x = 0; x < OW; x = x + 1)
                    sm[y*OW+x] = gray_f(R[(2*y)*IN_W+2*x], G[(2*y)*IN_W+2*x], B[(2*y)*IN_W+2*x]);
            k = 0; n_edge_gold = 0;
            for (y = 2; y < OH; y = y + 1)
                for (x = 2; x < OW; x = x + 1) begin
                    gxv = (sm[(y-2)*OW+x]   + 2*sm[(y-1)*OW+x]   + sm[y*OW+x])
                        - (sm[(y-2)*OW+x-2] + 2*sm[(y-1)*OW+x-2] + sm[y*OW+x-2]);
                    gyv = (sm[y*OW+x-2] + 2*sm[y*OW+x-1] + sm[y*OW+x])
                        - (sm[(y-2)*OW+x-2] + 2*sm[(y-2)*OW+x-1] + sm[(y-2)*OW+x]);
                    m = ((gxv<0)?-gxv:gxv) + ((gyv<0)?-gyv:gyv);
                    gold[k] = (m > thresh) ? 8'hFF : 8'h00;
                    if (gold[k] != 0) n_edge_gold = n_edge_gold + 1;
                    k = k + 1;
                end
        end
    endtask

    task send_frame(input gaps);
        integer p;
        begin
            for (p = 0; p < IN_W*IN_H; p = p + 1) begin
                if (gaps) while (($random & 3) == 0) begin @(posedge clk); in_valid <= 0; end
                @(posedge clk);
                in_valid <= 1; r <= R[p]; g <= G[p]; b <= B[p];
            end
            @(posedge clk); in_valid <= 0;
        end
    endtask

    // ---------- novelty: bounding-box block ----------
    wire [7:0] xmin, xmax, ymin, ymax; wire found, fdone;
    edge_bbox #(.W_OUT(OW-2), .H_OUT(OH-2)) u_bbox (.clk(clk), .rst_n(rst_n), .edge_valid(ev), .edge_pix(ep),
        .xmin(xmin), .xmax(xmax), .ymin(ymin), .ymax(ymax), .found(found), .frame_done(fdone));
    integer gx0, gx1, gy0, gy1, kk, bb_err = 0;
    task golden_bbox;
        begin
            gx0 = 999; gx1 = -1; gy0 = 999; gy1 = -1;
            for (kk = 0; kk < NOUT; kk = kk + 1)
                if (gold[kk] != 0) begin
                    if ((kk % (OW-2)) < gx0) gx0 = kk % (OW-2);
                    if ((kk % (OW-2)) > gx1) gx1 = kk % (OW-2);
                    if ((kk / (OW-2)) < gy0) gy0 = kk / (OW-2);
                    if ((kk / (OW-2)) > gy1) gy1 = kk / (OW-2);
                end
            $display("Golden bbox: x %0d..%0d  y %0d..%0d", gx0, gx1, gy0, gy1);
        end
    endtask
    task check_bbox(input integer frame);
        begin
            $display("Frame %0d DUT bbox: x %0d..%0d  y %0d..%0d found=%b", frame, xmin, xmax, ymin, ymax, found);
            if (xmin !== gx0 || xmax !== gx1 || ymin !== gy0 || ymax !== gy1 || !found) begin
                bb_err = bb_err + 1; $display("BBOX MISMATCH on frame %0d", frame);
            end
        end
    endtask

    // ---------- monitor ----------
    integer out_idx = 0, errors = 0, fd;
    always @(posedge clk) if (ev) begin
        if (ep !== gold[out_idx % NOUT]) begin
            errors = errors + 1;
            if (errors < 10) $display("MISMATCH idx %0d : dut=%h gold=%h", out_idx, ep, gold[out_idx % NOUT]);
        end
        $fwrite(fd, "%0d%s", (ep != 0), ((out_idx % (OW-2)) == OW-3) ? "\n" : " ");
        if ((out_idx % NOUT) == NOUT-1) $fwrite(fd, "\n");
        out_idx = out_idx + 1;
    end

    initial begin
        fd = $fopen("edge_out.txt", "w");
        build_golden;
        golden_bbox;
        $display("Golden edge pixels per frame = %0d of %0d", n_edge_gold, NOUT);
        repeat (5) @(posedge clk); rst_n <= 1; repeat (3) @(posedge clk);
        send_frame(0);
        repeat (50) @(posedge clk);
        check_bbox(1);
        send_frame(1);
        repeat (200) @(posedge clk);
        check_bbox(2);
        $fclose(fd);
        if (out_idx == 2*NOUT && errors == 0 && bb_err == 0) $display("PASS: %0d output pixels and the bounding box matched the golden model", out_idx);
        else $display("FAIL: outputs=%0d (expected %0d), errors=%0d bbox_errors=%0d", out_idx, 2*NOUT, errors, bb_err);
        $finish;
    end
endmodule
