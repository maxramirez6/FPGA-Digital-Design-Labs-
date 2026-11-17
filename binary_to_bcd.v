`timescale 1ns/1ps
// Unrolled double dabble. No division or remainder operators.
// Combinational module: rst clears its output; it has no storage to reset.
module binary_to_bcd(input wire rst, input wire [9:0] binary,
                     output reg [11:0] bcd);
    integer i;
    reg [11:0] work;
    always @(*) begin
        work = 0;
        // Read the binary time from its most significant bit down. Before each shift,
        // add 3 to each decimal digit of 5 or greater to keep the result in BCD.
        for(i=9;i>=0;i=i-1) begin
            if(work[3:0] >= 5) work[3:0] = work[3:0] + 4'd3;
            if(work[7:4] >= 5) work[7:4] = work[7:4] + 4'd3;
            if(work[11:8] >= 5) work[11:8] = work[11:8] + 4'd3;
            work = {work[10:0],binary[i]};
        end
        // The result has separate four-bit hundreds, tens, and ones digits.
        bcd = rst ? 12'b0 : work;
    end
endmodule
