`timescale 1ns / 1ps

/**
 * Captures OV7670 pixel data into a linear framebuffer.
 * Down-samples the incoming 640x480 stream to 320x240 by dropping every other
 * pixel and every other line.
 */
module camera_capture #(
    parameter integer FRAME_WIDTH  = 320,
    parameter integer FRAME_HEIGHT = 240,
    parameter integer ADDR_WIDTH   = 17
) (
    input  wire                    pclk,
    input  wire                    reset,
    input  wire                    vsync,
    input  wire                    href,
    input  wire [7:0]              pixel_data,
    output reg                     framebuf_we,
    output reg  [ADDR_WIDTH-1:0]   framebuf_addr,
    output reg  [15:0]             framebuf_data,
    output reg                     frame_done
);

    localparam integer FRAME_SIZE = FRAME_WIDTH * FRAME_HEIGHT;

    reg vsync_d = 1'b0;
    reg href_d  = 1'b0;

    reg frame_active = 1'b0;
    reg drop_line    = 1'b0;
    reg pixel_skip   = 1'b0; // drop every other pixel horizontally
    reg byte_phase   = 1'b0; // 0 = first byte (MSB), 1 = second byte (LSB)

    reg [ADDR_WIDTH-1:0] write_addr = {ADDR_WIDTH{1'b0}};
    reg [8:0]            column_cnt = 9'd0;
    reg [8:0]            row_cnt    = 9'd0;
    reg                  buffer_full = 1'b0;
    reg [15:0]           pixel_word = 16'd0;

    wire href_rising  = href & ~href_d;
    wire href_falling = ~href & href_d;

    always @(posedge pclk) begin
        if (reset) begin
            framebuf_we   <= 1'b0;
            framebuf_addr <= {ADDR_WIDTH{1'b0}};
            framebuf_data <= 16'd0;
            frame_done    <= 1'b0;
            vsync_d       <= 1'b0;
            href_d        <= 1'b0;
            frame_active  <= 1'b0;
            drop_line     <= 1'b0;
            pixel_skip    <= 1'b0;
            byte_phase    <= 1'b0;
            write_addr    <= {ADDR_WIDTH{1'b0}};
            column_cnt    <= 9'd0;
            row_cnt       <= 9'd0;
            buffer_full   <= 1'b0;
            pixel_word    <= 16'd0;
        end else begin
            vsync_d      <= vsync;
            href_d       <= href;
            framebuf_we  <= 1'b0;
            frame_done   <= 1'b0;

            if (vsync) begin
                frame_active <= 1'b0;
                drop_line    <= 1'b0;
                pixel_skip   <= 1'b0;
                byte_phase   <= 1'b0;
                column_cnt   <= 9'd0;
                row_cnt      <= 9'd0;
                write_addr   <= {ADDR_WIDTH{1'b0}};
                buffer_full  <= 1'b0;
                pixel_word   <= 16'd0;
            end else if (vsync_d && !vsync) begin
                frame_active <= 1'b1; // start of frame
            end

            if (href_rising) begin
                pixel_skip   <= 1'b0;
                byte_phase   <= 1'b0;
                column_cnt   <= 9'd0;
            end

            if (href_falling) begin
                pixel_skip   <= 1'b0;
                byte_phase   <= 1'b0;
                column_cnt   <= 9'd0;
                if (frame_active && !drop_line && (row_cnt < FRAME_HEIGHT)) begin
                    row_cnt <= row_cnt + 1'b1;
                end
                drop_line <= ~drop_line;
            end

            if (frame_active && href && !buffer_full) begin
                if (byte_phase == 1'b0) begin
                    pixel_word[15:8] <= pixel_data;
                    byte_phase       <= 1'b1;
                end else begin
                    byte_phase <= 1'b0;
                    pixel_word <= {pixel_word[15:8], pixel_data};

                    if (!drop_line) begin
                        if (!pixel_skip && (column_cnt < FRAME_WIDTH) && (row_cnt < FRAME_HEIGHT)) begin
                            framebuf_we   <= 1'b1;
                            framebuf_addr <= write_addr;
                            framebuf_data <= {pixel_word[15:8], pixel_data};
                            column_cnt    <= column_cnt + 1'b1;

                            if (write_addr == FRAME_SIZE[ADDR_WIDTH-1:0] - 1'b1) begin
                                buffer_full <= 1'b1;
                                frame_done  <= 1'b1;
                            end else begin
                                write_addr <= write_addr + 1'b1;
                            end
                        end
                        pixel_skip <= ~pixel_skip;
                    end
                end
            end
        end
    end

endmodule

