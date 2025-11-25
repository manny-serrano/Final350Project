`timescale 1ns/100ps

module debug_mult_tb;
    reg [31:0] A, B;
    reg clock, ctrl_MULT;
    wire [31:0] result;
    wire exception, ready;
    integer i;
    
    multdiv dut(
        .data_operandA(A),
        .data_operandB(B),
        .ctrl_MULT(ctrl_MULT),
        .ctrl_DIV(1'b0),
        .clock(clock),
        .data_result(result),
        .data_exception(exception),
        .data_resultRDY(ready)
    );
    
    initial clock = 0;
    always #20 clock = ~clock;
    
    initial begin
        ctrl_MULT = 0;
        A = 0;
        B = 0;
        #100;
        
        // Test 1
        $display("=== Test 1: 1 × 0 = 0 ===");
        A = 1;
        B = 0;
        ctrl_MULT = 1;
        @(negedge clock);
        ctrl_MULT = 0;
        
        for (i = 0; i < 30; i = i + 1) begin
            @(negedge clock);
            if (i < 5 || ready)
                $display("  Cycle %0d: ready=%b active=%b count=%d", 
                         i, ready, dut.multiplier.activemult, dut.multiplier.count);
            if (ready) begin
                $display("  Result=%d", $signed(result));
                
            end
        end
        
        #100;
        
        // Test 2
        $display("\n=== Test 2: 0 × 1 = 0 ===");
        A = 0;
        B = 1;
        ctrl_MULT = 1;
        @(negedge clock);
        ctrl_MULT = 0;
        
        for (i = 0; i < 30; i = i + 1) begin
            @(negedge clock);
            if (i < 5 || ready)
                $display("  Cycle %0d: ready=%b active=%b count=%d", 
                         i, ready, dut.multiplier.activemult, dut.multiplier.count);
            if (ready) begin
                $display("  Result=%d", $signed(result));
            end
        end
        
        #100;
        
        // Test 3
        $display("\n=== Test 3: 1 × 2 = 2 ===");
        A = 1;
        B = 2;
        ctrl_MULT = 1;
        @(negedge clock);
        ctrl_MULT = 0;
        
        for (i = 0; i < 30; i = i + 1) begin
            @(negedge clock);
            $display("  Cycle %0d: ready=%b active=%b count=%d product=%h", 
                     i, ready, dut.multiplier.activemult, dut.multiplier.count,
                     dut.multiplier.productcurrent);
            if (ready) begin
                $display("  Result=%d", $signed(result));
            end
        end
        
        if (i == 30)
            $display("  TIMEOUT!");
        
        $finish;
    end
endmodule