`timescale 1ns/1ps
// Check digit select and segment codes with 483, then verify the flash phases for 000.
module tb_output;
 reg clk=0,rst=1,expired=0;
 reg [9:0] seconds=483;
 wire [7:0] anode; wire [6:0] cathode; wire DP;
 integer i,seen=0;
 reg expected_blank;
 always #5 clk=~clk;
 output_module #(.SCAN_CYCLES(3),.HALF_SECOND_CYCLES(10)) dut
   (clk,rst,seconds,expired,anode,cathode,DP);
 initial begin
   repeat(3) @(negedge clk); rst=0;
   for(i=0;i<30;i=i+1) begin
     @(posedge clk); #1;
     if(anode[7:3]!==5'b11111 || DP!==1) $fatal(1,"Unused pins");
     case(anode)
       8'hfe: begin if(cathode!==7'b0110000) $fatal(1,"Ones"); seen=seen|1; end
       8'hfd: begin if(cathode!==7'b0000000) $fatal(1,"Tens"); seen=seen|2; end
       8'hfb: begin if(cathode!==7'b0011001) $fatal(1,"Hundreds"); seen=seen|4; end
       default: $fatal(1,"Anode not one active digit");
     endcase
   end
   if(seen!=7) $fatal(1,"Not all digits scanned");
   @(negedge clk); expired=1; seconds=0;
   for(i=1;i<=40;i=i+1) begin
     @(posedge clk); #1;
     expected_blank=((i/10)%2)!=0;
     if((anode==8'hff)!==expected_blank) $fatal(1,"Flash phase cycle %0d",i);
     if(!expected_blank && cathode!==7'b1000000) $fatal(1,"Expired zero glyph");
   end
   @(negedge clk); expired=0; seconds=999;
   repeat(10) begin
     @(posedge clk); #1;
     if(anode==8'hff || cathode!==7'b0010000) $fatal(1,"Resume/nine glyph");
   end
   @(negedge clk); rst=1; @(posedge clk); #1;
   if(anode!==8'hff) $fatal(1,"Reset blanking");
   $display("PASS tb_output: digit polarity/order, scanning, exact flash periods, reset");
   $finish;
 end
 initial begin #100000; $fatal(1,"Watchdog timeout"); end
endmodule
