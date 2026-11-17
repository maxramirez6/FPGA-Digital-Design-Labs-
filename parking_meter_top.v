`timescale 1ns/1ps
// This module wires together input conditioning, control, time storage, and display.
// The physical clock stays at 100 MHz. Counters inside the blocks set the slower intervals.
module parking_meter_top #(
    parameter integer USE_CLA=0,
    parameter integer DEBOUNCE_CYCLES=1000000,
    parameter integer SECOND_CYCLES=100000000,
    parameter integer SCAN_CYCLES=100000,
    parameter integer HALF_SECOND_CYCLES=50000000
)(
    input wire clk100Mhz, rst, set15_switch,
    input wire [3:0] buttons,
    output wire [7:0] anode,
    output wire [6:0] cathode,
    output wire DP, overflow
);
    // In the waveform, these internal nets show the path from a button press to the stored seconds.
    wire [3:0] coin_pulse;
    wire set15_pulse, next_zero, expired;
    wire [1:0] command;
    wire [9:0] credit, seconds;
    // Convert physical button and switch levels into one-cycle events.
    input_module #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) u_input
        (clk100Mhz,rst,buttons,set15_switch,coin_pulse,set15_pulse);
    // Choose one action and, for a coin, the number of seconds to add.
    meter_controller #(.SECOND_CYCLES(SECOND_CYCLES)) u_controller
        (clk100Mhz,rst,coin_pulse,set15_pulse,next_zero,command,credit,expired);
    // Store the time and flag amounts that exceed 999 seconds.
    meter_datapath #(.USE_CLA(USE_CLA)) u_datapath
        (clk100Mhz,rst,command,credit,seconds,next_zero,overflow);
    // Drive the three seven-segment digits and flash 000 when time expires.
    output_module #(.SCAN_CYCLES(SCAN_CYCLES),.HALF_SECOND_CYCLES(HALF_SECOND_CYCLES)) u_output
        (clk100Mhz,rst,seconds,expired,anode,cathode,DP);
endmodule
