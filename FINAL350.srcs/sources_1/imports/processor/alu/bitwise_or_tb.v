`timescale 1ns / 100ps

module bitwise_or_tb; 

    reg [31:0] A, B; 
    wire [31:0] result; 

    bitwise_or bit_or(.A(A), .B(B), .result(result)); 

    initial begin

        A = 32'b00000000000000000000000000000000;  
        B = 32'b11111111111111111111111111111111;  
        #10; 
        $display("Test 1: %b | %b = %b", A, B, result); // Should be all 1s

        A = 32'b10101010101010101010101010101010;  
        B = 32'b01010101010101010101010101010101;  
        #10; 
        $display("Test 2: %b | %b = %b", A, B, result); // Should be all 1s

        A = 32'b00000000000000000000000000000000;  
        B = 32'b00000000000000000000000000000000;  
        #10; 
        $display("Test 3: %b | %b = %b", A, B, result); // Should be all 0s

        $finish; 
    end

endmodule