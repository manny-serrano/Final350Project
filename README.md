# Camera-to-VGA Display System for Nexys A7

## Overview

Connects an OV7670 camera module to the VGA port on the Nexys A7 board to display a live grayscale video feed currently.  


## What It Does

- Captures live video from OV7670 camera at 320x240 resolution
- Displays the feed on a VGA monitor at 640x480 (each pixel doubled in both dimensions)
- Runs continuously at approximately 30 fps
- Outputs grayscale video (8-bit per pixel)
- DLX processor remains operational and unaffected

## Project Structure

All source files are located in `FINAL350.srcs/sources_1/imports/camera_vga/`

### Verilog Modules

**camera_vga_clock.v**
- Clock generation using MMCME2 primitive
- Takes 100 MHz system clock and produces:
  - 40 MHz for DLX processor
  - 24 MHz for camera XCLK and capture logic
  - 25 MHz for VGA controller

**reset_sync.v**
- Synchronizes reset signal across different clock domains
- Prevents metastability issues

**camera_capture.v**
- Interfaces with OV7670 camera signals (PCLK, HREF, VSYNC)
- Performs downsampling from 640x480 to 320x240 by skipping alternate rows and columns
- Writes grayscale pixel data to frame buffer
- Operates in 24 MHz clock domain

**frame_buffer.v**
- Dual-port block RAM (76,800 bytes)
- Port A: Camera writes at 24 MHz
- Port B: VGA reads at 25 MHz
- Stores 320x240 grayscale image (8-bit per pixel)

**vga_controller.v**
- Generates standard 640x480 @ 60Hz VGA timing
- Reads from frame buffer and duplicates pixels 2x2 for scaling
- Converts 8-bit grayscale to 12-bit RGB output
- Operates in 25 MHz clock domain

**top_camera_vga.v**
- Top-level module integrating all components
- Instantiates the existing DLX Wrapper (unchanged)
- Connects camera pipeline and VGA output
- Handles clock distribution and reset synchronization

### Constraints

**nexys_a7_camera_vga.xdc**
- Pin assignments for camera interface (Pmod JA, JB)
- Pin assignments for VGA output
- Clock constraints for 100 MHz input and generated clocks
- Asynchronous clock group definitions

## System Architecture

The video pipeline works as follows:

1. OV7670 camera captures 640x480 frames and outputs pixel data on an 8-bit bus synchronized to its PCLK (approximately 24 MHz)

2. camera_capture module samples this data stream:
   - Monitors VSYNC to detect frame boundaries
   - Monitors HREF to detect valid line data
   - Skips every other row and every other pixel
   - Writes resulting 320x240 grayscale bytes to frame buffer

3. Dual-port frame buffer stores one complete frame (76,800 bytes):
   - Write port connected to camera capture (24 MHz domain)
   - Read port connected to VGA controller (25 MHz domain)
   - No synchronization needed between domains

4. VGA controller generates 640x480 timing:
   - Reads pixels from frame buffer during active display region
   - Duplicates each 320x240 pixel into a 2x2 block for 640x480 output
   - Converts grayscale value to RGB by replicating across all color channels

## Camera Wiring

Connect the OV7670 module to Pmod connectors JA and JB on the Nexys A7.

### Pmod JA - Camera Data Bus

Top row (pins 1-4): D0, D1, D2, D3  
Bottom row (pins 7-10): D4, D5, D6, D7  
Power: Pin 5 (GND), Pin 6 (3.3V)

Detailed pin mapping:
- JA Pin 1 (C17) → cam_data[0]
- JA Pin 2 (D18) → cam_data[1]
- JA Pin 3 (E18) → cam_data[2]
- JA Pin 4 (G17) → cam_data[3]
- JA Pin 7 (D17) → cam_data[4]
- JA Pin 8 (E17) → cam_data[5]
- JA Pin 9 (F18) → cam_data[6]
- JA Pin 10 (G18) → cam_data[7]

### Pmod JB - Camera Control Signals

Top row:
- JB Pin 1 (D14) → cam_pclk (input from camera)
- JB Pin 2 (F16) → cam_href (input from camera)
- JB Pin 3 (G16) → cam_vsync (input from camera)
- JB Pin 4 (H14) → cam_xclk (output to camera, 24 MHz)

Bottom row:
- JB Pin 7 (E16) → cam_reset (output to camera)
- JB Pin 8 (F13) → cam_pwdn (output to camera, held low)

Power: Pin 11 (GND), Pin 12 (3.3V)

Note: SCCB (I2C) pins are not connected in this version. Camera uses power-on defaults.

## LED Status Indicators (planned)

- LED0: Blinks at ~1 Hz (40 MHz processor clock)
- LED1: Stays on when MMCM is locked (clocks are stable)
- LED2: Toggles when a frame is captured from camera
- LED3: Indicates PCLK activity from camera

If LED1 is off, clock generation has failed. If LED2 and LED3 are not toggling, check camera connections.


## Next Steps and Improvements for upcoming days

Potential enhancements for future revisions:

1. Add SCCB controller module to configure camera registers // perhaps
   - Set proper output format (RGB565 or YUV422)
   - Configure exposure, gain, white balance
   - Enable better image quality

2. Implement double buffering
   - Use two frame buffers (ping-pong)
   - Eliminate tearing artifacts
   - Camera and VGA work on separate buffers

3. Processor integration
   - Add memory-mapped registers for CPU control
   - Enable/disable camera capture
   - Adjust brightness/contrast from software
   - Read frame status

4. Image processing pipeline
   - Edge detection
   - Threshold/binarization
   - Simple filters (blur, sharpen)
   - Insert between capture and frame buffer

## Technical Notes

Clock Domain Crossings:
- Frame buffer handles crossing between 24 MHz (write) and 25 MHz (read) automatically
- Both clock domains are generated from same MMCM so they are related
- No explicit synchronization required for addresses since write and read pointers never overlap during normal operation

Resolution Scaling:
- Camera outputs 640x480 but only 320x240 is stored
- Line skipping: only even-numbered rows are captured
- Pixel skipping: only even-numbered columns are captured
- VGA duplicates each stored pixel 2x horizontally and 2x vertically

Memory Usage:
- Frame buffer: 76,800 bytes (320 * 240 * 8 bits)
- Fits comfortably in Nexys A7 block RAM (4,860 Kbits available)
- Leaves plenty of BRAM for other uses

Processor Integration:
- DLX processor and camera system are completely independent
- Share only the global reset and power
- Processor can be modified to access camera status via memory-mapped I/O
- Current design allows both systems to coexist without modification to DLX core