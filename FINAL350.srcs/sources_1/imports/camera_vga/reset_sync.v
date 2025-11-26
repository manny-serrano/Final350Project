`timescale 1ns / 1ps

/**
 * Simple active-high reset synchronizer.
 * async_reset_n is asserted low asynchronously and the synchronous reset
 * output stays high for STAGES clock cycles after async_reset_n deasserts.
 */
module reset_sync #(
    parameter integer STAGES = 4
) (
    input  wire clk,
    input  wire async_reset_n,
    output wire sync_reset
);

    initial begin
        if (STAGES < 2) begin
            $error("reset_sync requires STAGES >= 2");
        end
    end

    reg [STAGES-1:0] shreg = {STAGES{1'b1}};

    always @(posedge clk or negedge async_reset_n) begin
        if (!async_reset_n) begin
            shreg <= {STAGES{1'b1}};
        end else begin
            shreg <= {shreg[STAGES-2:0], 1'b0};
        end
    end

    assign sync_reset = shreg[STAGES-1];

endmodule

