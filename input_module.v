`timescale 1ns/1ps
module input_module #(parameter integer DEBOUNCE_CYCLES = 1000000)(
    input wire clk100Mhz, rst,
    input wire [3:0] buttons,
    input wire set15_switch,
    output wire [3:0] coin_pulse,
    output wire set15_pulse
);
    wire [4:0] clean;
    // Bits 3:0 are the coin buttons. Bit 4 is the load-15 switch.
    wire [4:0] raw = {set15_switch, buttons};
    reg [4:0] previous;
    genvar i;
    // Build one independent debouncer per input.
    generate for (i=0; i<5; i=i+1) begin: inputs_debounce
        debouncer #(.STABLE_CYCLES(DEBOUNCE_CYCLES)) u_db
            (clk100Mhz, rst, raw[i], clean[i]);
    end endgenerate
    always @(posedge clk100Mhz) begin
        if (rst) previous <= 0;
        else previous <= clean;
    end
    // A clean high paired with a previous low gives one clock of pulse.
    // Holding the input high makes both samples high, ending the pulse.
    // A clean release rearms the detector for the next press or switch flip.
    assign coin_pulse = rst ? 4'b0 : clean[3:0] & ~previous[3:0];
    assign set15_pulse = !rst && clean[4] && !previous[4];
endmodule
