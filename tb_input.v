`timescale 1ns/1ps
// Count one-clock pulses to verify bounce rejection, held inputs, and rearming.
module tb_input;
 reg clk=0,rst=1,sw=0;
 reg [3:0] buttons=0;
 wire [3:0] pulses;
 wire set15;
 integer counts[0:4]; integer i,j;
 always #5 clk=~clk;
 input_module #(.DEBOUNCE_CYCLES(4)) dut(clk,rst,buttons,sw,pulses,set15);
 always @(posedge clk) begin
   if(rst) for(j=0;j<5;j=j+1) counts[j]=0;
   else begin
     for(j=0;j<4;j=j+1) if(pulses[j]) counts[j]=counts[j]+1;
     if(set15) counts[4]=counts[4]+1;
   end
 end
 task cycles(input integer n);
   begin
   repeat(n) begin @(posedge clk); #1; end
   end
 endtask
 initial begin
   cycles(3); @(negedge clk); rst=0;
   buttons=1; cycles(1); @(negedge clk); buttons=0; cycles(12);
   if(counts[0]!=0) $fatal(1,"Bounce counted as coin");
   for(i=0;i<4;i=i+1) begin
     @(negedge clk); buttons=1<<i; cycles(25);
     if(counts[i]!=1) $fatal(1,"Held button %0d must produce one pulse",i);
     @(negedge clk); buttons=0; cycles(12);
   end
   @(negedge clk); buttons=1; cycles(12);
   if(counts[0]!=2) $fatal(1,"Second press missing");
   @(negedge clk); buttons=0; sw=1; cycles(30);
   if(counts[4]!=1) $fatal(1,"Switch must pulse only once while held");
   @(negedge clk); sw=0; cycles(12);
   @(negedge clk); sw=1; cycles(12);
   if(counts[4]!=2) $fatal(1,"Switch rearm failed");
   @(negedge clk); rst=1; cycles(2);
   if(pulses!==0 || set15!==0) $fatal(1,"Reset pulses");
   $display("PASS tb_input: bounce, all buttons, hold, rearm, switch, reset");
   $finish;
 end
 initial begin #100000; $fatal(1,"Watchdog timeout"); end
endmodule
