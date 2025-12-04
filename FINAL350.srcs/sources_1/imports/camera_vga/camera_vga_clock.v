`timescale 1ns / 1ps
/**
 * Generates the three clocks required by the design from the 100 MHz system clock.
 *  - 40 MHz for the DLX processor
 *  - 24 MHz for the OV7670 XCLK and capture logic
 *  - 25 MHz for the VGA pixel domain
 *
 * The implementation directly instantiates an MMCME2_BASE so we do not rely
 * on a generated Clocking Wizard IP core.
 */
module camera_vga_clock (
    input  wire clk_in_100mhz,
    input  wire reset,          // Active-high reset
    output wire clk_40mhz,
    output wire clk_24mhz,
    output wire clk_25mhz,
    output wire locked
);
    wire clkfb_int;
    wire clkfb_buf;
    wire clk_out40_int;
    wire clk_out24_int;
    wire clk_out25_int;
    wire unused_clk_out3;
    wire unused_clk_out4;
    wire unused_clk_out5;
    wire unused_clk_out6;
    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKIN1_PERIOD(10.000),   // 100 MHz input
        .DIVCLK_DIVIDE(1),
        .CLKFBOUT_MULT_F(12.0),   // VCO = 1200 MHz
        .CLKFBOUT_PHASE(0.0),
        .CLKOUT0_DIVIDE_F(30.0),  // 40 MHz
        .CLKOUT0_PHASE(0.0),
        .CLKOUT1_DIVIDE(50),      // 24 MHz
        .CLKOUT1_PHASE(0.0),
        .CLKOUT2_DIVIDE(48),      // 25 MHz
        .CLKOUT2_PHASE(0.0),
        .CLKOUT3_DIVIDE(1),
        .CLKOUT4_DIVIDE(1),
        .CLKOUT5_DIVIDE(1),
        .CLKOUT6_DIVIDE(1)
    ) mmcm_inst (
        .CLKIN1(clk_in_100mhz),
        .CLKFBIN(clkfb_buf),
        .CLKFBOUT(clkfb_int),
        .CLKOUT0(clk_out40_int),
        .CLKOUT0B(),
        .CLKOUT1(clk_out24_int),
        .CLKOUT1B(),
        .CLKOUT2(clk_out25_int),
        .CLKOUT2B(),
        .CLKOUT3(unused_clk_out3),
        .CLKOUT3B(),
        .CLKOUT4(unused_clk_out4),
        .CLKOUT5(unused_clk_out5),
        .CLKOUT6(unused_clk_out6),
        .LOCKED(locked),
        .PWRDWN(1'b0),
        .RST(reset)
    );
    BUFG clkfb_bufg (
        .I(clkfb_int),
        .O(clkfb_buf)
    );
    BUFG bufg_clk40 (
        .I(clk_out40_int),
        .O(clk_40mhz)
    );
    BUFG bufg_clk24 (
        .I(clk_out24_int),
        .O(clk_24mhz)
    );
    BUFG bufg_clk25 (
        .I(clk_out25_int),
        .O(clk_25mhz)
    );
endmodule