`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
// Module Name: tb_top
// Project Name: CSE 320 Lab 3 - Parking Meter
// Description: Tests coin inputs, loading 15 seconds, countdown,
//              overflow, expiration, and reset for both adder implementations.
// Dependencies: parking_meter_top and its input, controller, datapath,
//               arithmetic, and display modules.
// Additional Comments: Follow the stage waveform row through each test below.
//////////////////////////////////////////////////////////////////////////////////

module tb_top;

// Clock and physical controls driven by this testbench.
// Reset starts high. The switch and all buttons start low.
reg clk=0,rst=1,sw=0;
reg [3:0] buttons=0;

// Display outputs from the inferred-adder version (0) and CLA version (1).
// Anodes and segments are active low.
wire [7:0] an0,an1;
wire [6:0] seg0,seg1;

// Decimal points stay high to remain off. of0 and of1 report overflow.
wire dp0,dp1,of0,of1;
// Waveform stages: 0 reset, 1 idle, 2..5 four coins, 6 overflow,
// 7 set15/countdown, 8 held coin, 9 countdown to expiry, 10 reset.
reg [3:0] stage=0;
// Toggle every 5 ns for a 10 ns period. The DUT timing overrides below
// make each displayed second last 200 cycles, or 2 us, in this run.
always #5 clk=~clk;
// Apply identical stimulus to both adder implementations and compare their pins.
parking_meter_top #(.USE_CLA(0),.DEBOUNCE_CYCLES(4),.SECOND_CYCLES(200),
.SCAN_CYCLES(3),.HALF_SECOND_CYCLES(100)) dut
(clk,rst,sw,buttons,an0,seg0,dp0,of0);
parking_meter_top #(.USE_CLA(1),.DEBOUNCE_CYCLES(4),.SECOND_CYCLES(200),
.SCAN_CYCLES(3),.HALF_SECOND_CYCLES(100)) cla_dut
(clk,rst,sw,buttons,an1,seg1,dp1,of1);
always @(posedge clk) begin
    // Wait past the rising edge so the clocked outputs settle before comparison.
    #2;
    if({an0,seg0,dp0,of0} !== {an1,seg1,dp1,of1}) $fatal(1,"Top variant mismatch");
    if(an0[7:3]!==5'b11111) $fatal(1,"Unused anodes enabled");
end
// Report pre-edge decisions and post-edge stored results separately.
always @(posedge clk) begin
    if(!rst && dut.command != 0) begin
        $display("EVENT time_ns=%0t stage=%0d command=%0d credit=%0d old_seconds=%0d",
        $time,stage,dut.command,dut.credit,dut.seconds);
        #1;
        $display("RESULT seconds=%0d overflow=%b expired=%b",dut.seconds,of0,dut.expired);
    end
end

// Wait for n rising clock edges and allow registered values to settle.
task cycles(input integer n);
    begin
        repeat(n) begin @(posedge clk);
        #1;
    end
end
endtask

// Hold and release a selected button long enough for debouncing.
task press(input [3:0] b);
    begin
        // Change inputs on the falling edge, leaving them stable at the sampling edge.
        @(negedge clk);
        buttons=b;
        cycles(12);
        @(negedge clk);
        buttons=0;
        cycles(12);
    end
endtask
initial begin
    $timeformat(-9,0,"",0);
    $dumpfile("tb_top.vcd");
    $dumpvars(0,tb_top);

    // Hold reset for three cycles, then release it on a falling edge.
    // Stage 1 checks that the timer stays at zero before a coin is inserted.
    cycles(3);
    @(negedge clk);
    rst=0;
    stage=1;
    cycles(12);
    if(dut.seconds!=0) $fatal(1,"Startup zero");
    // Stages 2-5 show the four credit values. Stage 6 takes 630 to 930,
    // then tries 930 + 300 and clamps at 999.

    // Stage 2 presses button 0 and adds 30 seconds to the empty meter.
    stage=2;
    press(1);
    if(dut.seconds!=30) $fatal(1,"30 seconds");

    // Stage 3 presses button 1 and adds 120 seconds, taking 30 to 150.
    stage=3;
    press(2);
    if(dut.seconds!=150) $fatal(1,"120 seconds");

    // Stage 4 presses button 2 and adds 180 seconds, taking 150 to 330.
    stage=4;
    press(4);
    if(dut.seconds!=330) $fatal(1,"180 seconds");

    // Stage 5 presses button 3 and adds 300 seconds, taking 330 to 630.
    stage=5;
    press(8);
    if(dut.seconds!=630) $fatal(1,"300 seconds");

    // Stage 6 adds 300 twice. The first press produces 930.
    // The second attempts 1230, so seconds becomes 999 and overflow rises.
    stage=6;
    press(8);
    press(8);
    if(dut.seconds!=999 || !of0) $fatal(1,"Top overflow");
    // Load 15 once. The timer reaches 14 even though the switch is still high.
    stage=7;
    @(negedge clk);
    sw=1;
    cycles(250);
    if(dut.seconds!=14 || of0) $fatal(1,"Switch must load once then count down");

    // Lower the switch and let its debounced value return low.
    // This rearms the detector for the next switch activation.
    @(negedge clk);
    sw=0;
    cycles(12);
    // Hold the 30-second button. The timer moves from 14 to 44 once,
    // then to 43 on the next tick even while the button remains high.
    stage=8;
    @(negedge clk);
    buttons=1;
    cycles(250);
    if(dut.seconds!=43) $fatal(1,"Held coin/countdown: %0d",dut.seconds);
    // Raise the switch again to load 15. Wait for the timer to reach zero.
    stage=9;
    @(negedge clk);
    buttons=0;
    sw=1;
    cycles(12);
    if(dut.seconds!=15) $fatal(1,"Reload switch");

    // Wait for the timer to reach zero. expired then rises to start display flashing.
    cycles(3200);
    if(dut.seconds!=0 || !dut.expired) $fatal(1,"Integration expiry");
    // Reassert reset, check the final state, then stop the test.
    stage=10;
    @(negedge clk);
    rst=1;
    cycles(2);
    if(dut.seconds!=0 || of0) $fatal(1,"Integration reset");

    // Print PASS after all expected results have been checked.
    $display("PASS tb_top: physical inputs, both adders, hold/rearm, saturation, expiry, pins");
    $finish;
end

// Stop with an error if the test becomes stuck.
initial begin #1000000;
$fatal(1,"Watchdog timeout");
end
endmodule
