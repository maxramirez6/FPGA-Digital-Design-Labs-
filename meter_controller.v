`timescale 1ns/1ps
module meter_controller #(parameter integer SECOND_CYCLES = 100000000)(
    input wire clk100Mhz, rst,
    input wire [3:0] coin_pulse,
    input wire set15_pulse, next_zero,
    output reg [1:0] command,
    output reg [9:0] credit,
    output wire expired
);
    localparam EXPIRED=1'b0, ACTIVE=1'b1;
    localparam integer W = (SECOND_CYCLES <= 1) ? 1 : $clog2(SECOND_CYCLES);
    reg state;
    reg [W-1:0] second_count;
    // Generate a one-cycle timing event from the main clock. The board uses
    // 100,000,000 cycles per second. tb_top uses 200 cycles per displayed second.
    wire tick = (second_count == SECOND_CYCLES-1);
    assign expired = (state == EXPIRED);
    // Combinational decision: choose what the datapath captures at the NEXT edge.
    // Default HOLD prevents unintended storage in this decision logic.
    always @(*) begin
        command = 0; credit = 0;
        // After reset handling in the clocked blocks, action priority is load 15,
        // then a coin, then an active countdown tick, then hold.
        if(set15_pulse) command = 1;
        else if(|coin_pulse) begin
            command = 2;
            // When multiple coins arrive together, the highest denomination wins.
            if(coin_pulse[3]) credit = 300;
            else if(coin_pulse[2]) credit = 180;
            else if(coin_pulse[1]) credit = 120;
            else credit = 30;
        end else if(state == ACTIVE && tick) command = 3;
    end
    always @(posedge clk100Mhz) begin
        if(rst) begin state <= EXPIRED; second_count <= 0; end
        else begin
            // next_zero describes the SAME next_seconds value captured by the
            // datapath on this edge, so state and seconds stay consistent.
            // Update the ACTIVE or EXPIRED state on the same edge that stores seconds.
            state <= next_zero ? EXPIRED : ACTIVE;
            // A new transaction gets a fresh full second before decrementing.
            if(command == 1 || command == 2 || state == EXPIRED || tick)
                second_count <= 0;
            else second_count <= second_count + 1'b1;
        end
    end
endmodule
