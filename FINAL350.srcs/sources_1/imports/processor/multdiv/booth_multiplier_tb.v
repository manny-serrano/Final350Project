module booth_multiplier_tb;
    reg [31:0] A, B;
    reg clock, start;
    wire [31:0] result;
    wire overflow, ready;
    integer i;
    
    booth_multiplier checking(
        .A(A), .B(B), .clock(clock), .start(start),
        .result(result), .overflow(overflow), .ready(ready)
    );
    
    initial clock = 0;
    always #10 clock = ~clock;  // 20ns period = 50MHz (faster than required 25MHz)
    
    initial begin
        $display("=== Booth Multiplier Testbench ===");
        $display("");
        
        // Initialize
        start = 0; A = 0; B = 0;
        #40;
        
        $display("--- Detailed Test: 5 × 3 = 15 ---");
        A = 32'd5; B = 32'd3;
        start = 1; #20; start = 0;
        
        repeat(20) begin
            @(posedge clock);
            if (checking.activemult) begin
                $display("Cycle %2d: count=%d product=%h booth_bits=%b acc=%h q=%h", 
                    $time/20, checking.count, checking.productcurrent,
                    checking.booth_bits, checking.acc_current, checking.qcurrent);
            end
            if (ready) begin
                $display("READY! Result=%d (%h), Overflow=%b", 
                    $signed(result), result, overflow);
            end
        end
        $display("");
        
        // run systematic tests
        $display("=== Systematic Test Cases ===");
        $display("%-10s | %-10s | %-10s | %-10s | Overflow | Status", 
                "A", "B", "Expected", "Result");
        $display("-----------|-----------|-----------|-----------|----------|--------");
        
        
        for (i = 0; i < 10; i = i + 1) begin
            case(i)
                0: begin A = 32'd5;           B = 32'd3;           end  // 15
                1: begin A = 32'd7;           B = -32'd2;          end  // -14
                2: begin A = -32'd4;          B = 32'd6;           end  // -24
                3: begin A = -32'd3;          B = -32'd5;          end  // 15
                4: begin A = 32'd0;           B = 32'd100;         end  // 0
                5: begin A = 32'd100;         B = 32'd0;           end  // 0
                6: begin A = 32'd1;           B = -32'd1;          end  // -1
                7: begin A = 32'd1000;        B = 32'd1000;        end  // 1,000,000
                8: begin A = 32'h40000000;    B = 32'd2;           end  // Overflow test
                9: begin A = -32'd2147483648; B = 32'd2;           end  // -2^31 * 2 (overflow)
            endcase
            
            #20;  // Small delay before start
            start = 1; 
            @(posedge clock); 
            start = 0;
            
            // Wait for ready
            wait(ready);
            @(posedge clock);  // Wait one more cycle for signals to settle
            
            // Check result
            $display("%10d | %10d | %10d | %10d | %8b | %s", 
                    $signed(A), $signed(B), 
                    $signed(A) * $signed(B),
                    $signed(result), 
                    overflow,
                    (($signed(result) == $signed(A) * $signed(B)) && !overflow) ? "PASS" :
                    (overflow && (($signed(A) * $signed(B) > 32'd2147483647) || 
                                  ($signed(A) * $signed(B) < -32'd2147483648))) ? "PASS (OVF)" : 
                    "FAIL");
            
            #40;  // Wait before next test
        end
        
        $display("");
        $display("=== Edge Cases ===");
        
        // Test maximum positive
        A = 32'h7FFFFFFF; B = 32'd1;
        start = 1; @(posedge clock); start = 0;
        wait(ready); @(posedge clock);
        $display("Max positive × 1: Result=%d, Overflow=%b", $signed(result), overflow);
        #40;
        
        // Test maximum negative
        A = 32'h80000000; B = 32'd1;
        start = 1; @(posedge clock); start = 0;
        wait(ready); @(posedge clock);
        $display("Max negative × 1: Result=%d, Overflow=%b", $signed(result), overflow);
        #40;
        
        // Test -1 × -1 = 1
        A = -32'd1; B = -32'd1;
        start = 1; @(posedge clock); start = 0;
        wait(ready); @(posedge clock);
        $display("-1 × -1: Result=%d, Overflow=%b (expect 1, no overflow)", $signed(result), overflow);
        #40;
        
        $display("");
        $display("=== Tests Complete ===");
        $finish;
    end
    
    // Optional: Timeout watchdog
    initial begin
        #100000;  // 100us timeout
        $display("ERROR: Testbench timeout!");
        $finish;
    end
    
    // Optional: Generate VCD for waveform viewing
    initial begin
        $dumpfile("booth_multiplier.vcd");
        $dumpvars(0, booth_multiplier_tb);
    end
endmodule