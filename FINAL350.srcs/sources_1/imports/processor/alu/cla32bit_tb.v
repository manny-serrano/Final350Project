`timescale 1ns / 100ps

module cla32bit_tb;
    reg [31:0] A, B;
    reg Cin;
    wire [31:0] S;
    wire Overflow;
    
    cla32bit uut(.A(A), .B(B), .Cin(Cin), .S(S), .Overflow(Overflow));
    
    initial begin
        // Default values
        A = 32'd0; 
        B = 32'd0; 
        Cin = 1'b0;
        #100;

        A = 32'h7FFFFFFF;  // max signed int
        B = 32'd1;
        Cin = 1'b0;
        #5 $display("%d + %d + %d = %d, Overflow = %b", A, B, Cin, S, Overflow);

        A = 32'h80000000;  // min signed int
        B = 32'hFFFFFFFF;  // -1
        Cin = 1'b0;
        #5 $display("%d + %d + %d = %d, Overflow = %b", A, B, Cin, S, Overflow);

        A = 32'd100;
        B = -32'd50;
        Cin = 1'b0;
        #5 $display("%d + %d + %d = %d, Overflow = %b", A, B, Cin, S, Overflow);


        #100; 
        $finish;
    end
    
    always #10 A = A + 32'd1000; 
    always #15 B = B + 32'd500;  
    always #25 Cin = ~Cin;
    
    always @(A, B, Cin) begin
        #1;
        $display("%d + %d + %d = %d, Overflow = %b", A, B, Cin, S, Overflow);
    end

endmodule
