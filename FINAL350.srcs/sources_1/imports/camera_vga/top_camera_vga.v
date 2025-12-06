`timescale 1ns / 1ps

module top_camera_vga (
    input  wire        clk_100mhz,
    input  wire        reset_n,      // CPU_RESET button (active low)
    input  wire        cam_pclk,
    input  wire        cam_href,
    input  wire        cam_vsync,
    input  wire [7:0]  cam_data,
    inout  wire        cam_sioc,     // new SCCB clock
    inout  wire        cam_siod,     // new SCCB data
    output wire        cam_xclk,
    output wire        cam_reset,
    output wire        cam_pwdn,
    output wire        vga_hsync,
    output wire        vga_vsync,
    output wire [3:0]  vga_r,
    output wire [3:0]  vga_g,
    output wire [3:0]  vga_b,
    output wire [15:0] led
);

    localparam integer FRAME_WIDTH       = 320;
    localparam integer FRAME_HEIGHT      = 240;
    localparam integer FRAME_ADDR_WIDTH  = 17;
    localparam integer FRAME_BUFFER_DEPTH = FRAME_WIDTH * FRAME_HEIGHT;

    wire reset_btn = ~reset_n;

    wire clk_40mhz;
    wire clk_24mhz;
    wire clk_25mhz;
    wire clocks_locked;

    camera_vga_clock u_clock_gen (
        .clk_in_100mhz(clk_100mhz),
        .reset(reset_btn),
        .clk_40mhz(clk_40mhz),
        .clk_24mhz(clk_24mhz),
        .clk_25mhz(clk_25mhz),
        .locked(clocks_locked)
    );

    wire global_reset_n = reset_n & clocks_locked;

    wire cpu_reset;
    wire vga_reset;
    wire pclk_reset;

    reset_sync u_cpu_reset (
        .clk(clk_40mhz),
        .async_reset_n(global_reset_n),
        .sync_reset(cpu_reset)
    );

    reset_sync u_vga_reset (
        .clk(clk_25mhz),
        .async_reset_n(global_reset_n),
        .sync_reset(vga_reset)
    );

    reset_sync u_pclk_reset (
        .clk(cam_pclk),
        .async_reset_n(global_reset_n),
        .sync_reset(pclk_reset)
    );

    // Camera control lines
    assign cam_xclk  = clk_24mhz;
    assign cam_pwdn  = 1'b0;       // keep camera powered
    assign cam_reset = global_reset_n;

    // SCCB initializer (configure OV7670 for RGB565 full range)
    wire sccb_done;
    camera_sccb_init #(
        .CLK_HZ(24_000_000),
        .SCL_HZ(100_000)
    ) u_sccb_init (
        .clk(clk_24mhz),
        .reset(~global_reset_n), // active high
        .sioc(cam_sioc),
        .siod(cam_siod),
        .done(sccb_done)
    );

    // Frame buffer wiring
    wire                     framebuf_we;
    wire [FRAME_ADDR_WIDTH-1:0] framebuf_wr_addr;
    wire [15:0]              framebuf_wr_data;
    wire                     frame_capture_done;

    wire [FRAME_ADDR_WIDTH-1:0] framebuf_rd_addr;
    wire [15:0]              framebuf_rd_data;

    camera_capture #(
        .FRAME_WIDTH(FRAME_WIDTH),
        .FRAME_HEIGHT(FRAME_HEIGHT),
        .ADDR_WIDTH(FRAME_ADDR_WIDTH)
    ) u_camera_capture (
        .pclk(cam_pclk),
        .reset(pclk_reset),
        .vsync(cam_vsync),
        .href(cam_href),
        .pixel_data(cam_data),
        .framebuf_we(framebuf_we),
        .framebuf_addr(framebuf_wr_addr),
        .framebuf_data(framebuf_wr_data),
        .frame_done(frame_capture_done)
    );

    frame_buffer #(
        .DATA_WIDTH(16),
        .ADDR_WIDTH(FRAME_ADDR_WIDTH),
        .DEPTH(FRAME_BUFFER_DEPTH)
    ) u_frame_buffer (
        .clk_a(cam_pclk),
        .we_a(framebuf_we),
        .addr_a(framebuf_wr_addr),
        .data_in_a(framebuf_wr_data),
        .clk_b(clk_25mhz),
        .addr_b(framebuf_rd_addr),
        .data_out_b(framebuf_rd_data)
    );

    wire [11:0] vga_rgb;

    vga_controller #(
        .FRAME_WIDTH(FRAME_WIDTH),
        .FRAME_HEIGHT(FRAME_HEIGHT),
        .ADDR_WIDTH(FRAME_ADDR_WIDTH)
    ) u_vga_controller (
        .clk(clk_25mhz),
        .reset(vga_reset),
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .rgb(vga_rgb),
        .framebuf_rd_addr(framebuf_rd_addr),
        .framebuf_rd_data(framebuf_rd_data)
    );

    assign vga_r = vga_rgb[11:8];
    assign vga_g = vga_rgb[7:4];
    assign vga_b = vga_rgb[3:0];

    // Keep the existing DLX processor running at 40 MHz
  Wrapper u_dlx_wrapper (
        clk_40mhz,    // clock
        cpu_reset     // reset
    );

    // Simple status LEDs
    reg [23:0] heartbeat_counter = 24'd0;
    always @(posedge clk_40mhz) begin
        if (cpu_reset) begin
            heartbeat_counter <= 24'd0;
        end else begin
            heartbeat_counter <= heartbeat_counter + 1'b1;
        end
    end

    reg [15:0] pclk_activity = 16'd0;
    reg        frame_toggle  = 1'b0;
    always @(posedge cam_pclk) begin
        if (pclk_reset) begin
            pclk_activity <= 16'd0;
            frame_toggle  <= 1'b0;
        end else begin
            pclk_activity <= pclk_activity + 1'b1;
            if (frame_capture_done) begin
                frame_toggle <= ~frame_toggle;
            end
        end
    end

    assign led[0]     = heartbeat_counter[23];
    assign led[1]     = clocks_locked;
    assign led[2]     = frame_toggle;
    assign led[3]     = pclk_activity[15];
    assign led[4]     = ~global_reset_n;
    assign led[5]     = sccb_done;
    assign led[15:6]  = 10'd0;

endmodule

