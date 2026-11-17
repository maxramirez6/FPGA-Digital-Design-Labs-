`timescale 1ns/1ps
// Adapted from the provided two-flop synchronizer/debouncer interface.
// Require a continuous stable interval instead of a wrapping 4-bit counter.
module debouncer #(parameter integer STABLE_CYCLES = 1000000)(
    input wire clk100Mhz, rst, i_sig,
    output reg o_sig_debounced
);
    localparam integer W = (STABLE_CYCLES <= 1) ? 1 : $clog2(STABLE_CYCLES);
    // The two flip-flops synchronize a board input before the stability check.
    (* ASYNC_REG = "TRUE" *) reg meta, sync;
    reg [W-1:0] count;
    always @(posedge clk100Mhz) begin
        if (rst) begin
            meta <= 0; sync <= 0; count <= 0; o_sig_debounced <= 0;
        end else begin
            meta <= i_sig;
            sync <= meta;
            // Start over when the synchronized input returns to the current clean level.
            // Accept a changed level only after STABLE_CYCLES consecutive samples.
            if (sync == o_sig_debounced) count <= 0;
            else if (count == STABLE_CYCLES-1) begin
                o_sig_debounced <= sync;
                count <= 0;
            end else count <= count + 1'b1;
        end
    end
endmodule
