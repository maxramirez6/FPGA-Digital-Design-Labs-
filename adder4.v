`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/08/2026 07:11:16 PM
// Design Name: 
// Module Name: adder4
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


module adder4
(
        // These buses appear as A[3:0] and B[3:0] in the waveform.
        // Vivado may show their values in hex: 8 means 1000 and f means 1111.
        input [3:0] A,
        input [3:0] B,
        // Cin is the carry input for bit 0 and appears as its own waveform row.
        input Cin,
        // These output rows show the 4-bit result and carry beyond bit 3.
        output [3:0] Sum,
        output Cout

);

// Internal carry links. If added to the waveform, they show the carry rippling
// from bit 0 to bit 3; the top-level Cout is the carry leaving bit 3.
wire adder_1_cout;
wire adder_2_cout;
wire adder_3_cout;

// Stage adder1 handles bit 0: its ports connect to A[0], B[0], Cin, and Sum[0].
// Its Cout is adder_1_cout, which becomes the next stage's Cin.
adder_1 adder1
(
        .A(A[0]),
        .B(B[0]),
        .Cin(Cin),
        .Sum(Sum[0]),
        .Cout(adder_1_cout)
);

// Stage adder2 handles bit 1. Its carry output feeds bit 2.
adder_1 adder2
(
        .A(A[1]),
        .B(B[1]),
        .Cin(adder_1_cout),
        .Sum(Sum[1]),
        .Cout(adder_2_cout)
);

// Stage adder3 handles bit 2. Its carry output feeds bit 3.
adder_1 adder3
(
        .A(A[2]),
        .B(B[2]),
        .Cin(adder_2_cout),
        .Sum(Sum[2]),
        .Cout(adder_3_cout)
);

// Stage adder4 handles bit 3. Its sum is Sum[3], and its carry is waveform Cout.
adder_1 adder4
(
        .A(A[3]),
        .B(B[3]),
        .Cin(adder_3_cout),
        .Sum(Sum[3]),
        .Cout(Cout)
);

endmodule
