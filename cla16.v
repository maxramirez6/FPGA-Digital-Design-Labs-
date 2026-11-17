`timescale 1ns/1ps
// Four-bit group lookahead plus lookahead between all four groups.
// No arithmetic '+' operator in the adder datapath.
module cla16(input wire rst, input wire [15:0] a, b,
             output wire [15:0] sum, output wire cout);
    // A bit propagates carry when exactly one input is 1 and generates carry
    // when both are 1.
    wire [15:0] p = a ^ b;
    wire [15:0] g = a & b;
    wire [3:0] P, G;
    wire [4:0] C;
    assign C[0] = 1'b0;
    genvar k;
    // Build four groups of four bits. Each group summarizes its carry behavior.
    generate for(k=0;k<4;k=k+1) begin: group
        wire [3:0] pp = p[4*k +: 4];
        wire [3:0] gg = g[4*k +: 4];
        wire [3:0] c;
        assign P[k] = &pp;
        assign G[k] = gg[3] | pp[3]&gg[2] | pp[3]&pp[2]&gg[1]
                    | pp[3]&pp[2]&pp[1]&gg[0];
        assign c[0] = C[k];
        assign c[1] = gg[0] | pp[0]&C[k];
        assign c[2] = gg[1] | pp[1]&gg[0] | pp[1]&pp[0]&C[k];
        assign c[3] = gg[2] | pp[2]&gg[1] | pp[2]&pp[1]&gg[0]
                    | pp[2]&pp[1]&pp[0]&C[k];
        assign sum[4*k +: 4] = rst ? 4'b0 : pp ^ c;
    end endgenerate
    // Use group propagate and generate terms to compute the carry into each group.
    assign C[1] = G[0] | P[0]&C[0];
    assign C[2] = G[1] | P[1]&G[0] | P[1]&P[0]&C[0];
    assign C[3] = G[2] | P[2]&G[1] | P[2]&P[1]&G[0]
                | P[2]&P[1]&P[0]&C[0];
    assign C[4] = G[3] | P[3]&G[2] | P[3]&P[2]&G[1]
                | P[3]&P[2]&P[1]&G[0] | P[3]&P[2]&P[1]&P[0]&C[0];
    assign cout = !rst && C[4];
endmodule
