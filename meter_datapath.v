`timescale 1ns/1ps
module meter_datapath #(parameter integer USE_CLA = 0)(
    input wire clk100Mhz, rst,
    input wire [1:0] command,
    input wire [9:0] credit,
    output reg [9:0] seconds,
    output wire next_zero,
    output reg overflow
);
    // Commands: hold=0, load15=1, add=2, decrement=3.
    // Extend both operands so the full total can be compared with 999 before
    // it is narrowed to the 10-bit time register.
    wire [15:0] sum;
    // Both variants calculate the same sum. USE_CLA selects the hand-written
    // carry-lookahead adder or the adder inferred from the + operator.
    generate if (USE_CLA) begin: manual_adder
        wire unused_carry;
        cla16 u_add(rst, {6'b0,seconds}, {6'b0,credit}, sum, unused_carry);
    end else begin: inferred_adder
        assign sum = {6'b0,seconds} + {6'b0,credit};
    end endgenerate
    reg [9:0] next_seconds;
    // This block is combinational: changing next_seconds does not change seconds.
    always @(*) begin
        next_seconds = seconds;
        case(command)
            2'd1: next_seconds = 10'd15;
            // Clamp an attempted total above 999. A total of exactly 999 is allowed.
            2'd2: next_seconds = (sum > 16'd999) ? 10'd999 : sum[9:0];
            // Guard zero to prevent unsigned wraparound.
            2'd3: if(seconds != 0) next_seconds = seconds - 1'b1;
            default: next_seconds = seconds;
        endcase
    end
    // Feed the computed zero result back to the controller before the clock edge.
    assign next_zero = (next_seconds == 0);
    always @(posedge clk100Mhz) begin
        if (rst) begin seconds <= 0; overflow <= 0; end
        else begin
            // Nonblocking assignment: capture the pre-edge computed next value.
            seconds <= next_seconds;
            // Visible overflow indication: latch until reset, load15, or next coin.
            if(command == 2'd1) overflow <= 0;
            else if(command == 2'd2) overflow <= (sum > 16'd999);
        end
    end
endmodule
