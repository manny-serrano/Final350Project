`timescale 1ns / 1ps

/**
 * VGA controller for 640x480 @ 60 Hz timing.
 * Reads an 8-bit grayscale framebuffer that stores 320x240 pixels and
 * performs simple 2x upscaling by duplicating pixels horizontally and vertically.
 */
module vga_controller #(
    parameter integer FRAME_WIDTH  = 320,
    parameter integer FRAME_HEIGHT = 240,
    parameter integer ADDR_WIDTH   = 17
) (
    input  wire                  clk,
    input  wire                  reset,
    output reg                   hsync,
    output reg                   vsync,
    output reg  [11:0]           rgb,
    output reg  [ADDR_WIDTH-1:0] framebuf_rd_addr,
    input  wire [7:0]            framebuf_rd_data
);

    localparam integer H_ACTIVE = 640;
    localparam integer H_FRONT  = 16;
    localparam integer H_SYNC   = 96;
    localparam integer H_BACK   = 48;
    localparam integer H_TOTAL  = H_ACTIVE + H_FRONT + H_SYNC + H_BACK; // 800

    localparam integer V_ACTIVE = 480;
    localparam integer V_FRONT  = 10;
    localparam integer V_SYNC   = 2;
    localparam integer V_BACK   = 33;
    localparam integer V_TOTAL  = V_ACTIVE + V_FRONT + V_SYNC + V_BACK; // 525

    reg [9:0] h_count = 10'd0;
    reg [9:0] v_count = 10'd0;
    reg [7:0] pixel_reg = 8'd0;

    wire display_active = (h_count < H_ACTIVE) && (v_count < V_ACTIVE);

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
                } else begin
                    v_count <= v_count + 1'b1;
                end
            } else begin
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
    wire [9:0] h_count_next = (h_count == H_TOTAL - 1) ? 10'd0 : (h_count + 1'b1);
    wire [9:0] v_count_next = (h_count == H_TOTAL - 1) ?
                              ((v_count == V_TOTAL - 1) ? 10'd0 : (v_count + 1'b1)) :
                              v_count;

    wire next_active = (h_count_next < H_ACTIVE) && (v_count_next < V_ACTIVE);

    wire [8:0] col_idx = h_count_next[9:1]; // divide by 2
    wire [8:0] row_idx = v_count_next[9:1]; // divide by 2

    wire [16:0] row_base = (row_idx << 8) + (row_idx << 6); // row * 320 = row*256 + row*64
    wire [16:0] next_addr = row_base + col_idx;

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
            pixel_reg <= 8'd0;
        end else if (display_active) begin
            pixel_reg <= framebuf_rd_data;
        end else begin
            pixel_reg <= 8'd0;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            rgb <= 12'd0;
        end else if (display_active) begin
            rgb <= {3{pixel_reg[7:4]}};
        end else begin
            rgb <= 12'd0;
        end
    end

endmodule

