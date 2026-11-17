`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/08/2026 06:36:11 PM
// Design Name: 
// Module Name: subtractor
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


module subtractor
(
        // Inputs of one 1-bit stage. In the top module these connect to
        // i_A[n], i_B[n], and the borrow from the previous bit.
        input i_A,
        input i_B,
        input i_Bin,
        // Outputs become o_Diff[n] and the borrow link to the next stage.
        output o_Diff,
        output o_Bout
);

// SOP form of the full-subtractor truth-table rows where Diff=1.
// These stage outputs combine into o_Diff[3:0] in the parent waveform.
assign o_Diff = (!i_A && !i_B & i_Bin) || (!i_A && i_B && !i_Bin) || (i_A && !i_B && !i_Bin) || (i_A && i_B && i_Bin);

// SOP form of the truth-table rows where a borrow is required.
// In the parent design, this drives the next bit's borrow-in.
assign o_Bout = (!i_A && !i_B & i_Bin) || (!i_A && i_B && !i_Bin) || (!i_A && i_B && i_Bin) || (i_A && i_B && i_Bin);

endmodule
