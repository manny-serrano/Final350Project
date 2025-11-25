module cla33bit(input[32:0] A, B, input Cin, output [32:0] S, output Cout); 

wire cout_32;

//lower 32 bits of cla
wire unused_ovf; 

cla32bit lower_adder(.A(A[31:0]), .B(B[31:0]), .Cin(Cin), .S(S[31:0]), .Cout(cout_32), 
.Overflow(unused_ovf)); 


// 33rd bit, full adder with the carry bit 32
    wire sum_33, carry_33;
    

// Sum of bit 32
    wire a_xor_b;
    xor xor1(a_xor_b, A[32], B[32]);
    xor xor2(S[32], a_xor_b, cout_32);
    
    // Carry out of bit 32
    wire a_and_b, axorb_and_cin;
    and and1(a_and_b, A[32], B[32]);
    and and2(axorb_and_cin, a_xor_b, cout_32);
    or  or1(Cout, a_and_b, axorb_and_cin);


endmodule