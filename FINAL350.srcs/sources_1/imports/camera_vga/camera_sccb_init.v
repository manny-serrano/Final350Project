`timescale 1ns / 1ps
/**
 * Minimal SCCB (I2C-like) write-only initializer for OV7670.
 * - Bit-bangs SIOC/SIOD with open-drain style (drive low or release).
 * - Plays a fixed register table once after reset, then asserts done.
 * - Assumes external pull-ups on the camera board (common on OV7670 modules).
 *
 * Default clocks target ~100 kHz SIOC from a 24 MHz input.
 */
module camera_sccb_init #(
    parameter integer CLK_HZ = 24_000_000,
    parameter integer SCL_HZ = 100_000
) (
    input  wire clk,
    input  wire reset,      // active high
    inout  wire sioc,
    inout  wire siod,
    output reg  done
);

   
    function integer clog2;
        input integer value;
        integer i;
        begin
            clog2 = 0;
            for (i = value - 1; i > 0; i = i >> 1)
                clog2 = clog2 + 1;
        end
    endfunction

    // Clock divider for 4 phases per SCL period
    localparam integer DIV   = CLK_HZ / (SCL_HZ * 4);
    localparam integer DIV_W = clog2(DIV);

    reg [DIV_W-1:0] divcnt = {DIV_W{1'b0}};
    wire tick_4x = (divcnt == DIV-1);
    always @(posedge clk) begin
        if (reset) begin
            divcnt <= {DIV_W{1'b0}};
        end else if (tick_4x) begin
            divcnt <= {DIV_W{1'b0}};
        end else begin
            divcnt <= divcnt + 1'b1;
        end
    end

    // Open-drain drivers
    reg scl_oe = 1'b0; // 1 = drive low, 0 = release (pull-up)
    reg sda_oe = 1'b0;
    assign sioc = scl_oe ? 1'b0 : 1'bz;
    assign siod = sda_oe ? 1'b0 : 1'bz;
    wire sda_in = siod;

    // Register table (addr,data)
    localparam integer NUM_WRITES = 24;
    reg [15:0] table [0:NUM_WRITES-1];
    initial begin
        table[0]  = {8'h12, 8'h80}; // COM7 reset
        table[1]  = {8'h12, 8'h04}; // COM7 RGB
        table[2]  = {8'h3a, 8'h04}; // TSLB: correct UV ordering
        table[3]  = {8'h40, 8'hd0}; // COM15: full range, RGB565
        table[4]  = {8'h3d, 8'h88}; // COM13: gamma/UV enable
        table[5]  = {8'h13, 8'he5}; // COM8: AGC AEC AWB on
        table[6]  = {8'h6f, 8'h9f}; // AWB control
        table[7]  = {8'h3e, 8'h19}; // COM14: scaling, PCLK divide
        table[8]  = {8'h70, 8'h3a}; // Scaling X
        table[9]  = {8'h71, 8'h35}; // Scaling Y
        table[10] = {8'h72, 8'h11}; // Downsample control
        table[11] = {8'h73, 8'hf0}; // PCLK divide
        table[12] = {8'ha2, 8'h02}; // PCLK delay
        table[13] = {8'h11, 8'h01}; // CLKRC: prescale /2 (24 MHz -> 12 MHz PCLK max)
        table[14] = {8'h0c, 8'h04}; // COM3: scaling enable
        table[15] = {8'h42, 8'h00}; // COM17: disable test bar
        // Color matrix / gamma (good baseline)
        table[16] = {8'h4f, 8'h80}; // MTX1
        table[17] = {8'h50, 8'h80}; // MTX2
        table[18] = {8'h51, 8'h05}; // MTX3
        table[19] = {8'h52, 8'h22}; // MTX4
        table[20] = {8'h53, 8'h5e}; // MTX5
        table[21] = {8'h54, 8'h80}; // MTX6
        table[22] = {8'h58, 8'h9e}; // MTXS
        table[23] = {8'h3f, 8'h0a}; // Edge enhancement / denoise
    end

    // State machine (Verilog-2001 style)
    localparam [3:0] ST_RESET_WAIT = 4'd0;
    localparam [3:0] ST_START      = 4'd1;
    localparam [3:0] ST_DEV        = 4'd2;
    localparam [3:0] ST_REG        = 4'd3;
    localparam [3:0] ST_DATA       = 4'd4;
    localparam [3:0] ST_STOP       = 4'd5;
    localparam [3:0] ST_NEXT       = 4'd6;
    localparam [3:0] ST_DONE       = 4'd7;
    reg [3:0] state = ST_RESET_WAIT;

    reg [15:0] cur_word = 16'd0;
    reg [4:0]  bit_idx = 5'd0; // up to 8 bits
    reg [1:0]  phase = 2'd0;   // 0..3 within SCL period
    reg [7:0]  powerup_wait = 8'd0; // ~10ms at default clocks
    reg [5:0]  idx = 6'd0;

    // Helper to load next bit onto SDA during phase0 (SCL low)
    reg cur_bit;
    always @* begin
        cur_bit = 1'b1;
        if (state == ST_DEV) begin
            cur_bit = (8'h42 << bit_idx) & 8'h80 ? 1'b1 : 1'b0;
        end else if (state == ST_REG) begin
            cur_bit = cur_word[15 - bit_idx];
        end else if (state == ST_DATA) begin
            cur_bit = cur_word[7 - bit_idx];
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            state        <= ST_RESET_WAIT;
            scl_oe       <= 1'b0;
            sda_oe       <= 1'b0;
            done         <= 1'b0;
            idx          <= 6'd0;
            phase        <= 2'd0;
            bit_idx      <= 5'd0;
            powerup_wait <= 8'd0;
        end else if (done) begin
            // hold lines released
            scl_oe <= 1'b0;
            sda_oe <= 1'b0;
        end else if (tick_4x) begin
            case (state)
                ST_RESET_WAIT: begin
                    // Hold lines high, wait ~10 ms
                    scl_oe <= 1'b0;
                    sda_oe <= 1'b0;
                    powerup_wait <= powerup_wait + 1'b1;
                    if (powerup_wait == 8'd255) begin
                        state   <= ST_START;
                        phase   <= 2'd0;
                        bit_idx <= 5'd0;
                    end
                end
                ST_START: begin
                    // Start condition: SDA falls while SCL high
                    case (phase)
                        2'd0: begin sda_oe <= 1'b0; scl_oe <= 1'b0; phase <= 2'd1; end
                        2'd1: begin sda_oe <= 1'b1; scl_oe <= 1'b0; phase <= 2'd2; end
                        2'd2: begin scl_oe <= 1'b1; phase <= 2'd3; end
                        2'd3: begin state <= ST_DEV; phase <= 2'd0; bit_idx <= 5'd0; end
                    endcase
                end
                ST_DEV, ST_REG, ST_DATA: begin
                    case (phase)
                        2'd0: begin // setup bit while SCL low
                            scl_oe <= 1'b1;
                            sda_oe <= cur_bit ? 1'b0 : 1'b1; // drive low for 0
                            phase  <= 2'd1;
                        end
                        2'd1: begin // clock high
                            scl_oe <= 1'b0;
                            phase  <= 2'd2;
                        end
                        2'd2: begin // hold high
                            phase <= 2'd3;
                        end
                        2'd3: begin // clock low, advance bit
                            scl_oe <= 1'b1;
                            if (bit_idx == 5'd7) begin
                                bit_idx <= 5'd0;
                                state   <= (state == ST_DEV)  ? ST_REG :
                                           (state == ST_REG)  ? ST_DATA :
                                                                ST_STOP; // after data byte
                                // ACK cycle: release SDA for next state to control
                                sda_oe <= 1'b0;
                            end else begin
                                bit_idx <= bit_idx + 1'b1;
                            end
                            phase <= 2'd0;
                        end
                    endcase
                end
                ST_STOP: begin
                    // SDA rises while SCL high
                    case (phase)
                        2'd0: begin sda_oe <= 1'b1; scl_oe <= 1'b1; phase <= 2'd1; end
                        2'd1: begin scl_oe <= 1'b0; phase <= 2'd2; end
                        2'd2: begin sda_oe <= 1'b0; phase <= 2'd3; end
                        2'd3: begin state <= ST_NEXT; phase <= 2'd0; end
                    endcase
                end
                ST_NEXT: begin
                    if (idx == NUM_WRITES-1) begin
                        state <= ST_DONE;
                    end else begin
                        idx    <= idx + 1'b1;
                        state  <= ST_START;
                        cur_word <= table[idx + 1'b1];
                    end
                end
                ST_DONE: begin
                    done   <= 1'b1;
                    scl_oe <= 1'b0;
                    sda_oe <= 1'b0;
                end
                default: state <= ST_DONE;
            endcase
        end
    end

    // Load first word once reset wait finishes
    always @(posedge clk) begin
        if (reset) begin
            cur_word <= table[0];
        end else if (state == ST_RESET_WAIT && powerup_wait == 8'd254) begin
            cur_word <= table[0];
            idx      <= 6'd0;
        end
    end
endmodule

