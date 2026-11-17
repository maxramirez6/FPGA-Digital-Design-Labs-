`timescale 1ns/1ps
// Test controller and datapath directly against an independent reference timer.
// Run with USE_CLA=0 and USE_CLA=1 to check both arithmetic paths.
module tb_core;
 parameter integer USE_CLA=0;
 localparam integer PERIOD=8;
 reg clk=0,rst=1,set15=0;
 reg [3:0] coins=0;
 wire [1:0] command;
 wire [9:0] credit,seconds;
 wire zero,expired,overflow;
 integer ref_time=0,ref_count=0,amount,total,i;
 reg ref_overflow=0;
 always #5 clk=~clk;
 meter_controller #(.SECOND_CYCLES(PERIOD)) ctrl
   (clk,rst,coins,set15,zero,command,credit,expired);
 meter_datapath #(.USE_CLA(USE_CLA)) dp
   (clk,rst,command,credit,seconds,zero,overflow);
 // Reference model observes external events, not DUT internal commands.
 always @(posedge clk) begin
   if(rst) begin ref_time=0; ref_count=0; ref_overflow=0; end
   else if(set15) begin ref_time=15; ref_count=0; ref_overflow=0; end
   else if(coins!=0) begin
     if(coins[3]) amount=300;
     else if(coins[2]) amount=180;
     else if(coins[1]) amount=120;
     else amount=30;
     total=ref_time+amount;
     ref_overflow=(total>999);
     ref_time=(total>999)?999:total; ref_count=0;
   end else if(ref_time>0) begin
     if(ref_count==PERIOD-1) begin ref_time=ref_time-1; ref_count=0; end
     else ref_count=ref_count+1;
   end else ref_count=0;
   #1;
   if(seconds!==ref_time[9:0] || overflow!==ref_overflow || expired!==(ref_time==0))
     $fatal(1,"Core t=%0t got %0d/%b/%b expected %0d/%b",$time,seconds,overflow,expired,ref_time,ref_overflow);
 end
 task step(input [3:0] c,input s);
   begin
   @(negedge clk); coins=c; set15=s;
   @(posedge clk); #2;
   end
 endtask
 initial begin
   repeat(3) @(negedge clk); rst=0;
   step(1,0); step(2,0); step(4,0); step(8,0);
   if(seconds!=630) $fatal(1,"Denominations");
   step(8,0); step(8,0);
   if(seconds!=999 || !overflow) $fatal(1,"Saturation");
   step(15,1);
   if(seconds!=15 || overflow) $fatal(1,"Set15 priority");
   repeat(20*PERIOD) step(0,0);
   if(seconds!=0 || !expired) $fatal(1,"Countdown/zero floor");
   step(15,0);
   if(seconds!=300) $fatal(1,"Coin priority");
   repeat(PERIOD-1) step(0,0); step(1,0);
   if(seconds!=330) $fatal(1,"Coin/tick priority");
   // Exact 999 is legal; the next attempted addition must overflow.
   step(0,1);
   repeat(6*PERIOD) step(0,0);
   step(8,0); step(8,0); step(8,0);
   step(1,0); step(1,0); step(1,0);
   if(seconds!=999 || overflow) $fatal(1,"Exact 999 must not overflow");
   step(1,0);
   if(seconds!=999 || !overflow) $fatal(1,"999 plus 30 must saturate");
   // Assignment's worked example: 300 counts down to 200, then add 180.
   step(0,1); repeat(15*PERIOD) step(0,0);
   step(8,0); repeat(100*PERIOD) step(0,0);
   if(seconds!=200) $fatal(1,"300 to 200 countdown");
   step(4,0);
   if(seconds!=380) $fatal(1,"200 plus 180");
   for(i=0;i<2000;i=i+1) begin
     if(i%17==0) step($random,0);
     else if(i%113==0) step(0,1);
     else step(0,0);
   end
   @(negedge clk); rst=1; coins=15; set15=1;
   @(posedge clk); #2;
   if(seconds!=0 || overflow || !expired) $fatal(1,"Reset priority");
   $display("PASS tb_core USE_CLA=%0d: denominations, countdown, overflow, priorities, 2000-cycle scoreboard",USE_CLA);
   $finish;
 end
 initial begin #1000000; $fatal(1,"Watchdog timeout"); end
endmodule
