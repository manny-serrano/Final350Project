`timescale 1ns / 1ps

/**
 * Simple true dual-port frame buffer inferred from block RAM.
 * Port A: write side (camera clock domain)
 * Port B: read side (VGA clock domain)
 */
module frame_buffer #(
    parameter integer DATA_WIDTH = 8,
    parameter integer ADDR_WIDTH = 17,
    parameter integer DEPTH      = 76800
) (
    // Port A
    input  wire                     clk_a,
    input  wire                     we_a,
    input  wire [ADDR_WIDTH-1:0]    addr_a,
    input  wire [DATA_WIDTH-1:0]    data_in_a,
    // Port B
    input  wire                     clk_b,
    input  wire [ADDR_WIDTH-1:0]    addr_b,
    output reg  [DATA_WIDTH-1:0]    data_out_b
);

    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge clk_a) begin
        if (we_a && addr_a < DEPTH) begin
            mem[addr_a] <= data_in_a;
        end
    end

    always @(posedge clk_b) begin
        if (addr_b < DEPTH) begin
            data_out_b <= mem[addr_b];
        end else begin
            data_out_b <= {DATA_WIDTH{1'b0}};
        end
    end

endmodule

