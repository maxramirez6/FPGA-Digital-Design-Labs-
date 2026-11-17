`timescale 1ns/1ps
// Compare the BCD converter and manual CLA against simple arithmetic references.
module tb_arithmetic;
 reg rst=1;
 reg [15:0] a=0,b=0;
 wire [15:0] sum; wire cout;
 reg [9:0] binary=0;
 wire [11:0] bcd;
 reg [16:0] expected;
 integer i,j,expected_bcd;
 cla16 add(rst,a,b,sum,cout);
 binary_to_bcd conv(rst,binary,bcd);
 initial begin
   #1; rst=0; #1;
   for(i=0;i<1000;i=i+1) begin
     binary=i;
     // Division is used ONLY in this simulation reference, never in RTL.
     expected_bcd=((i/100)<<8) | (((i/10)%10)<<4) | (i%10);
     #1;
     if(bcd!==expected_bcd[11:0]) $fatal(1,"BCD at %0d",i);
     for(j=0;j<4;j=j+1) begin
       a=i;
       case(j) 0:b=30; 1:b=120; 2:b=180; 3:b=300; endcase
       expected={1'b0,a}+{1'b0,b}; #1;
       if({cout,sum}!==expected) $fatal(1,"CLA coin sum");
     end
   end
   a=16'hffff; b=1; #1;
   if({cout,sum}!==17'h10000) $fatal(1,"CLA long carry");
   for(i=0;i<5000;i=i+1) begin
     a=$random; b=$random; expected={1'b0,a}+{1'b0,b}; #1;
     if({cout,sum}!==expected) $fatal(1,"CLA random");
   end
   rst=1; #1;
   if({cout,sum}!==0 || bcd!==0) $fatal(1,"Combinational reset");
   $display("PASS tb_arithmetic: 1000 BCD values, 4000 coin sums, 5000 random CLA sums");
   $finish;
 end
endmodule
