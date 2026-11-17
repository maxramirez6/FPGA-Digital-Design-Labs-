`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/08/2026 06:43:10 PM
// Design Name: 
// Module Name: subtractor_4
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module subtractor_4
(
        // These buses appear as i_A[3:0] and i_B[3:0] in the waveform.
        // Bus values may be shown in hex: 9=1001, c=1100, f=1111.
        input [3:0] i_A,
        input [3:0] i_B,
        // Borrow entering bit 0; this is the i_Bin waveform row.
        input i_Bin,
        // These are the difference and final-borrow waveform rows.
        output [3:0] o_Diff,
        output o_Bout
);

// Internal per-bit results. Add these to the waveform to see the difference
// bits and borrow chain stage-by-stage; the top-level buses are more compact.
wire w_sub1_diff;
wire w_sub1_bout;

wire w_sub2_diff;
wire w_sub2_bout;

wire w_sub3_diff;
wire w_sub3_bout;

wire w_sub4_diff;
wire w_sub4_bout;

// sub_1 is bit 0: its difference becomes o_Diff[0], and its borrow
// (w_sub1_bout) is the input borrow for bit 1.
subtractor sub_1
(
        .i_A(i_A[0]),
        .i_B(i_B[0]),
        .i_Bin(i_Bin),
        .o_Diff(w_sub1_diff),
        .o_Bout(w_sub1_bout)
);

// sub_2 is bit 1; it consumes the bit-0 borrow and creates the bit-2 borrow.
subtractor sub_2
(
        .i_A(i_A[1]),
        .i_B(i_B[1]),
        .i_Bin(w_sub1_bout),
        .o_Diff(w_sub2_diff),
        .o_Bout(w_sub2_bout)
);

// sub_3 is bit 2; it consumes the bit-1 borrow and creates the bit-3 borrow.
subtractor sub_3
(
        .i_A(i_A[2]),
        .i_B(i_B[2]),
        .i_Bin(w_sub2_bout),
        .o_Diff(w_sub3_diff),
        .o_Bout(w_sub3_bout)
);

// sub_4 is bit 3, the most significant bit. Its difference becomes o_Diff[3].
// Its borrow is w_sub4_bout, which should be the top-level final borrow.
subtractor sub_4
(
        .i_A(i_A[3]),
        .i_B(i_B[3]),
        .i_Bin(w_sub3_bout),
        .o_Diff(w_sub4_diff),
        .o_Bout(w_sub4_bout)
);


// Concatenate individual stage outputs into the waveform bus o_Diff[3:0].
// Leftmost expression maps to bit 3, rightmost to bit 0.
assign o_Diff = {w_sub4_diff, w_sub3_diff, w_sub2_diff, w_sub1_diff};

// In the current code, o_Bout is undriven, so the waveform can show Z here.
// The final stage has a valid borrow on w_sub4_bout, but it is not connected.
// To make the top-level o_Bout waveform show that result, add:
// assign o_Bout = w_sub4_bout;

endmodule
