`timescale 1ns / 100ps

module bitbybit_and_tb; 

    reg [31:0] A, B; 
    wire [31:0] result; 

    bitbybit_and bit_and(.A(A), .B(B), .result(result)); 

    initial begin

        A = 32'b00000000000000000000000000000000;  
        B = 32'b11111111111111111111111111111111;  
        #10; 
        $display("Test 1: %b & %b = %b", A, B, result); 


        A = 32'b10101010101010101010101010101010;  
        B = 32'b01100110011001100110011001100110;  
        #80; 
        $display("Test 2: %b & %b = %b", A, B, result); 


        A = 32'b10101010101010101010101010101010;  
        B = 32'b01010101010101010101010101010101;  
        #10; 
        $display("Test 3: %b & %b = %b", A, B, result);


        $finish; 
    end

endmodule
