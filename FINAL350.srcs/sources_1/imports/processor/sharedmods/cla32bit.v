module cla32bit(A, B, Cin, S, Overflow, Cout);

    output Cout; 
    input [31:0] A, B; 
    input Cin; 
    output [31:0] S; 
    output Overflow; 

    wire [3:0] P_groups, G_groups; 
    wire [2:0] carries; 
    wire Carry; 

// 4 (8bit) CLA blocks

    cla8bit block0(.A(A[7:0]), .B(B[7:0]), .Cin(Cin), .S(S[7:0]), .Cout(), .P_group(P_groups[0]), .G_group(G_groups[0])); 

    cla8bit block1(.A(A[15:8]), .B(B[15:8]), .Cin(carries[0]), .S(S[15:8]), .Cout(), .P_group(P_groups[1]), .G_group(G_groups[1])); 

    cla8bit block2(.A(A[23:16]), .B(B[23:16]), .Cin(carries[1]), .S(S[23:16]), .Cout(), .P_group(P_groups[2]), .G_group(G_groups[2])); 

    cla8bit block3(.A(A[31:24]), .B(B[31:24]), .Cin(carries[2]), .S(S[31:24]), .Cout(), .P_group(P_groups[3]), .G_group(G_groups[3])); 



// C[8] = G_groups[0] + P_groups[0]*Cin

    wire p0cin; 
    and p0cingate(p0cin, P_groups[0], Cin); 
    or c8gate(carries[0], G_groups[0], p0cin); 

// C[16] = G_groups[1] + P_groups[1]*G_groups[0] + P_groups[1]*P_groups[0]*Cin

    wire p1g0, p1p0cin; 
    and p1g0gate(p1g0, P_groups[1], G_groups[0]); 
    and p1p0cingate(p1p0cin, P_groups[1], P_groups[0], Cin); 
    or c16gate(carries[1], G_groups[1], p1g0, p1p0cin); 


// C[24] = G_2 + P_2 * G1 + P2*P1*g0 + P2*p1*p0*cin

    wire p2g1, p2p1g0, p2p1p0cin; 
    and p2g1gate(p2g1, P_groups[2], G_groups[1]); 
    and p2p1g0gate(p2p1g0, P_groups[2], P_groups[1], G_groups[0]); 
    and p2p1p0cingate(p2p1p0cin, P_groups[2], P_groups[1], P_groups[0], Cin); 

    or c24gate(carries[2], G_groups[2], p2g1, p2p1g0, p2p1p0cin); 



// C32 = G3 + P3*G2 + P3*P2*G1 + P3*P2*P1*G0 + P3*P2*P1*P0*Cin;

    wire p3g2, p3p2g1, p3p2p1g0, p3p2p1p0cin; 
    and p3g2gate(p3g2, P_groups[3], G_groups[2]); 
    and p3p2g1gate(p3p2g1, P_groups[3], P_groups[2], G_groups[1]); 
    and p3p2p1g0gate(p3p2p1g0, P_groups[3], P_groups[2], P_groups[1], G_groups[0]); 
    and p3p2p1p0cingate(p3p2p1p0cin, P_groups[3], P_groups[2], P_groups[1], P_groups[0], Cin); 

    or c32gate(Carry, G_groups[3], p3g2, p3p2g1, p3p2p1g0, p3p2p1p0cin); 

    //Overflow 
    wire nota31, notb31, nots31;
    wire pos_overflow, neg_overflow;

    not not_a(nota31, A[31]);
    not not_b(notb31, B[31]);
    not not_s(nots31, S[31]);

    // Positive overflow
    and pos_ovf(pos_overflow, nota31, notb31, S[31]);

    // Negative overflow
    and neg_ovf(neg_overflow, A[31], B[31], nots31);

    // Total overflow 
    or total_overflow(Overflow, pos_overflow, neg_overflow);     

    assign Cout = Carry;


endmodule 






















