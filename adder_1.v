`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/08/2026 07:08:40 PM
// Design Name: 
// Module Name: adder_1
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


module adder_1
(
        // In a waveform, these are the inputs of each 1-bit full-adder stage.
        // At the top stage they come from A[n], B[n], and the preceding carry.
        input A,
        input B,
        input Cin,
        // These are the outputs visible as Sum[n] and the next carry wire.
        output Sum,
        output Cout
);

// This Boolean SOP equation implements the truth-table rows where the sum bit is 1.
// It is the signal that appears as Sum[n] in the 4-bit adder waveform.
assign Sum = (!A && !B && Cin) || (!A && B && !Cin) || (A && !B & !Cin) || (A && B && Cin);

// Carry is 1 when at least two inputs are 1. In the parent module this drives
// an intermediate carry waveform, or the top-level Cout at the final stage.
assign Cout = (!A && B && Cin) || (A && !B && Cin) || (A && B && !Cin) || (A && B && Cin);

endmodule
