`timescale 1ns / 1ps
/**
 * VGA controller for 640x480 @ 60 Hz timing.
 * Reads a 16-bit RGB565 framebuffer that stores 320x240 pixels and
 * performs simple 2x upscaling by duplicating pixels horizontally and vertically.
 */
module vga_controller #(
    parameter FRAME_WIDTH  = 320,
    parameter FRAME_HEIGHT = 240,
    parameter ADDR_WIDTH   = 17
) (
    input  wire                  clk,
    input  wire                  reset,
    output reg                   hsync,
    output reg                   vsync,
    output reg  [11:0]           rgb,
    output reg  [ADDR_WIDTH-1:0] framebuf_rd_addr,
    input  wire [15:0]           framebuf_rd_data
);
    localparam H_ACTIVE = 640;
    localparam H_FRONT  = 16;
    localparam H_SYNC   = 96;
    localparam H_BACK   = 48;
    localparam H_TOTAL  = H_ACTIVE + H_FRONT + H_SYNC + H_BACK; // 800
    localparam V_ACTIVE = 480;
    localparam V_FRONT  = 10;
    localparam V_SYNC   = 2;
    localparam V_BACK   = 33;
    localparam V_TOTAL  = V_ACTIVE + V_FRONT + V_SYNC + V_BACK; // 525
    reg [9:0] h_count = 10'd0;
    reg [9:0] v_count = 10'd0;
    reg [15:0] pixel_reg = 16'd0;
    wire display_active;
    assign display_active = (h_count < H_ACTIVE) && (v_count < V_ACTIVE);
    // Advance counters
    always @(posedge clk) begin
        if (reset) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end else begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 10'd0;
                if (v_count == V_TOTAL - 1) begin
                    v_count <= 10'd0;
                end else begin
                    v_count <= v_count + 1'b1;
                end
            end else begin
                h_count <= h_count + 1'b1;
            end
        end
    end
    // Generate sync pulses (active low)
    always @(posedge clk) begin
        if (reset) begin
            hsync <= 1'b1;
            vsync <= 1'b1;
        end else begin
            hsync <= ~((h_count >= (H_ACTIVE + H_FRONT)) && (h_count < (H_ACTIVE + H_FRONT + H_SYNC)));
            vsync <= ~((v_count >= (V_ACTIVE + V_FRONT)) && (v_count < (V_ACTIVE + V_FRONT + V_SYNC)));
        end
    end
    // Address generation: request the pixel for the NEXT clock tick
    wire [9:0] h_count_next;
    wire [9:0] v_count_next;
    wire next_active;
    wire [8:0] col_idx;
    wire [8:0] row_idx;
    wire [16:0] row_base;
    wire [16:0] next_addr;
    assign h_count_next = (h_count == H_TOTAL - 1) ? 10'd0 : (h_count + 1'b1);
    assign v_count_next = (h_count == H_TOTAL - 1) ?
                          ((v_count == V_TOTAL - 1) ? 10'd0 : (v_count + 1'b1)) :
                          v_count;
    assign next_active = (h_count_next < H_ACTIVE) && (v_count_next < V_ACTIVE);
    assign col_idx = h_count_next[9:1]; // divide by 2
    assign row_idx = v_count_next[9:1]; // divide by 2
    assign row_base = (row_idx << 8) + (row_idx << 6); // row * 320 = row*256 + row*64
    assign next_addr = row_base + col_idx;
    always @(posedge clk) begin
        if (reset) begin
            framebuf_rd_addr <= {ADDR_WIDTH{1'b0}};
        end else if (next_active) begin
            framebuf_rd_addr <= next_addr;
        end else begin
            framebuf_rd_addr <= {ADDR_WIDTH{1'b0}};
        end
    end
    // Pipeline pixel data (framebuf_rd_data is valid one clock after the address request)
    always @(posedge clk) begin
        if (reset) begin
            pixel_reg <= 16'd0;
        end else if (display_active) begin
            pixel_reg <= framebuf_rd_data;
        end else begin
            pixel_reg <= 16'd0;
        end
    end

    wire [4:0] r5 = pixel_reg[15:11];
    wire [5:0] g6 = pixel_reg[10:5];
    wire [4:0] b5 = pixel_reg[4:0];

    always @(posedge clk) begin
        if (reset) begin
            rgb <= 12'd0;
        end else if (display_active) begin
            rgb <= {r5[4:1], g6[5:2], b5[4:1]};
        end else begin
            rgb <= 12'd0;
        end
    end
endmodule