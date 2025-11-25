`timescale 1ns / 1ps

module divider_clean_tb();

    reg [31:0] A, B;
    reg clock, start;
    wire [31:0] result;
    wire exception, ready;
    
    integer pass_count, fail_count;
    
    // Instantiate the divider
    divider dut(
        .A(A),
        .B(B),
        .clock(clock),
        .start(start),
        .result(result),
        .exception(exception),
        .ready(ready)
    );
    
    // Clock generation - 10ns period
    initial begin
        clock = 0;
        forever #5 clock = ~clock;
    end
    
    // Task to run a division test
    task test_division;
        input [31:0] a_val, b_val, expected;
        input expect_exception;
        input [200*8:1] test_name;
        begin
            // Wait for system to be completely idle
            @(negedge clock);
            @(negedge clock);
            
            A = a_val;
            B = b_val;
            
            @(negedge clock);
            
            // Pulse start for exactly one clock cycle
            @(posedge clock);
            start = 1;
            @(posedge clock);
            start = 0;
            
            // Wait for ready signal
            wait(ready == 1);
            @(posedge clock);
            
            // Check result
            if (expect_exception) begin
                if (exception == 1) begin
                    $display("PASS: %0s - Exception detected", test_name);
                    pass_count = pass_count + 1;
                end else begin
                    $display("FAIL: %0s - Expected exception, got result=%d", test_name, $signed(result));
                    fail_count = fail_count + 1;
                end
            end else begin
                if (result == expected && exception == 0) begin
                    $display("PASS: %0s - %0d / %0d = %0d", test_name, $signed(a_val), $signed(b_val), $signed(result));
                    pass_count = pass_count + 1;
                end else begin
                    $display("FAIL: %0s - %0d / %0d = %0d (expected %0d, exception=%b)", 
                             test_name, $signed(a_val), $signed(b_val), $signed(result), $signed(expected), exception);
                    fail_count = fail_count + 1;
                end
            end
            
            // Wait for ready to go back low
            wait(ready == 0);
            @(posedge clock);
            @(posedge clock);
        end
    endtask
    
    // Test stimulus
    initial begin
        $dumpfile("divider_clean.vcd");
        $dumpvars(0, divider_clean_tb);
        
        // Initialize
        A = 0;
        B = 0;
        start = 0;
        pass_count = 0;
        fail_count = 0;
        
        #20;
        
        $display("\n========================================");
        $display("   Divider Test Suite");
        $display("========================================\n");
        
        // Test 1: Simple positive division
        test_division(32'd100, 32'd10, 32'd10, 0, "Test 1: 100 / 10");
        
        // Test 2: Negative dividend
        test_division(-32'd100, 32'd10, -32'd10, 0, "Test 2: -100 / 10");
        
        // Test 3: Negative divisor
        test_division(32'd100, -32'd10, -32'd10, 0, "Test 3: 100 / -10");
        
        // Test 4: Both negative
        test_division(-32'd100, -32'd10, 32'd10, 0, "Test 4: -100 / -10");
        
        // Test 5: Divide by zero
        test_division(32'd100, 32'd0, 32'd0, 1, "Test 5: 100 / 0 (div by zero)");
        
        // Test 6: Larger numbers
        test_division(32'd1000, 32'd25, 32'd40, 0, "Test 6: 1000 / 25");
        
        // Test 7: Division with remainder (truncated)
        test_division(32'd100, 32'd7, 32'd14, 0, "Test 7: 100 / 7");
        
        // Test 8: Dividend smaller than divisor
        test_division(32'd5, 32'd10, 32'd0, 0, "Test 8: 5 / 10");
        
        // Test 9: Divide by 1
        test_division(32'd12345, 32'd1, 32'd12345, 0, "Test 9: 12345 / 1");
        
        // Test 10: Equal numbers
        test_division(32'd42, 32'd42, 32'd1, 0, "Test 10: 42 / 42");
        
        #50;
        
        $display("\n========================================");
        $display("   Test Results Summary");
        $display("========================================");
        $display("Total Tests: %0d", pass_count + fail_count);
        $display("Passed:      %0d", pass_count);
        $display("Failed:      %0d", fail_count);
        if (fail_count == 0) begin
            $display("\n*** ALL TESTS PASSED! ***\n");
        end else begin
            $display("\n*** SOME TESTS FAILED ***\n");
        end
        $display("========================================\n");
        
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #100000;
        $display("ERROR: Testbench timeout!");
        $finish;
    end

endmodule