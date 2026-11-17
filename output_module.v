`timescale 1ns/1ps
module output_module #(
    parameter integer SCAN_CYCLES = 100000,
    parameter integer HALF_SECOND_CYCLES = 50000000
)(
    input wire clk100Mhz, rst,
    input wire [9:0] seconds,
    input wire expired,
    output reg [7:0] anode,
    output reg [6:0] cathode,
    output wire DP
);
    localparam integer SW=(SCAN_CYCLES<=1)?1:$clog2(SCAN_CYCLES);
    localparam integer FW=(HALF_SECOND_CYCLES<=1)?1:$clog2(HALF_SECOND_CYCLES);
    reg [SW-1:0] scan_count;
    reg [FW-1:0] flash_count;
    reg [1:0] digit_index;
    reg blank;
    wire [11:0] bcd;
    reg [3:0] digit;
    // Convert the binary timer into three decimal digits before segment decoding.
    binary_to_bcd u_bcd(rst,seconds,bcd);
    // The decimal point is active low, so 1 keeps it off.
    assign DP = 1'b1;
    always @(posedge clk100Mhz) begin
        if(rst) begin
            scan_count<=0; digit_index<=0; flash_count<=0; blank<=0;
        end else begin
            // Cycle through ones, tens, and hundreds. Only one digit is enabled at a time.
            if(scan_count == SCAN_CYCLES-1) begin
                scan_count<=0;
                digit_index <= (digit_index==2) ? 0 : digit_index+1'b1;
            end else scan_count<=scan_count+1'b1;
            // While expired, toggle display blanking at each half-second interval.
            if(!expired) begin flash_count<=0; blank<=0; end
            else if(flash_count == HALF_SECOND_CYCLES-1) begin
                flash_count<=0; blank<=~blank;
            end else flash_count<=flash_count+1'b1;
        end
    end
    always @(*) begin
        anode=8'hff; digit=0;
        case(digit_index)
            0: begin anode=8'b11111110; digit=bcd[3:0]; end
            1: begin anode=8'b11111101; digit=bcd[7:4]; end
            2: begin anode=8'b11111011; digit=bcd[11:8]; end
            default: begin anode=8'hff; digit=0; end
        endcase
        // cathode[6:0] = {g,f,e,d,c,b,a}, active low.
        case(digit)
            0: cathode=7'b1000000;
            1: cathode=7'b1111001;
            2: cathode=7'b0100100;
            3: cathode=7'b0110000;
            4: cathode=7'b0011001;
            5: cathode=7'b0010010;
            6: cathode=7'b0000010;
            7: cathode=7'b1111000;
            8: cathode=7'b0000000;
            9: cathode=7'b0010000;
            default: cathode=7'b1111111;
        endcase
        // All ones turn off the active-low anodes and segments for the blank phase.
        if(rst || (expired && blank)) begin anode=8'hff; cathode=7'h7f; end
    end
endmodule
