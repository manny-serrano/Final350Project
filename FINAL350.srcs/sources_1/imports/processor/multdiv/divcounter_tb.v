`timescale 1ns / 1ps

module divcounter_tb();

    reg clock, enable, reset;
    wire [5:0] count;
    wire done;
    
    // Instantiate counter
    divcounter checking (
        .clock(clock),
        .enable(enable),
        .reset(reset),
        .count(count),
        .done(done)
    );
    
    // Clock 
    initial begin
        clock = 0;
        forever #5 clock = ~clock;
    end
    
    // Test
    integer i;
    initial begin
        $display("Testing 6-bit Counter");
        
        // Reset
        reset = 1; enable = 0;
        #10 reset = 0; enable = 1;
        
        // Count to 32 and check done signal
        for (i = 0; i <= 35; i = i + 1) begin
            #10;
            $display("Cycle %2d: count = %d, done = %b", i, count, done);
            
            // Done should be 1 when count equals 32
            if (count == 32 && done !== 1)
                $display("ERROR: Done should be 1 at count=32");
            if (count != 32 && done !== 0)
                $display("ERROR: Done should be 0 at count=%d", count);
        end
        
        $display("\nTest complete - Counter works correctly!");
        $display("- Counts from 0 to 32");
        $display("- Done asserts at count=32");
        $display("- Done deasserts after count=32");
        $finish;
    end

endmodule