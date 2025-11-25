module cla8bit(A, B, Cin, S, Cout, P_group, G_group); 


    input [7:0] A, B; 
    input Cin; 
    output [7:0] S; 
    output Cout, P_group, G_group; 

    wire [7:0] G, P; // overall generate and propogate
    wire [7:0] C; // individual carry for each position

// generate for each bit calculation
// G[i] = A[i] AND B[i] (both 1 = guaranteed carry out)

    and g0(G[0], A[0], B[0]);
    and g1(G[1], A[1], B[1]); 
    and g2(G[2], A[2], B[2]); 
    and g3(G[3], A[3], B[3]);  
    and g4(G[4], A[4], B[4]);  
    and g5(G[5], A[5], B[5]);  
    and g6(G[6], A[6], B[6]);  
    and g7(G[7], A[7], B[7]);  


// P[i] = A[i] OR B[i]  (at least one 1 = can propagate carry)

    or p0(P[0], A[0], B[0]); 
    or p1(P[1], A[1], B[1]);
    or p2(P[2], A[2], B[2]);  
    or p3(P[3], A[3], B[3]); 
    or p4(P[4], A[4], B[4]); 
    or p5(P[5], A[5], B[5]); 
    or p6(P[6], A[6], B[6]); 
    or p7(P[7], A[7], B[7]); 



    assign C[0] = Cin; 



    // C[1] = G[0] + P[0]*Cin
    wire p0cin; 
    and p0cingate(p0cin, P[0], Cin); 
    or c1gate(C[1], G[0], p0cin); 



    // C[2] = G[1] + P[1]*G[0] + P[1]*P[0]*Cin

    wire p1g0, p1p0cin; 
    and p1p0gate(p1g0, P[1], G[0]); 
    and p1p0cingate(p1p0cin, P[1], P[0], Cin); 
    or c2gate(C[2], G[1], p1g0, p1p0cin); 

    // C[3] = G[2] + P[2]*G[1] + P[2]*P[1]*G[0] + P[2]*P[1]*P[0]*Cin

    wire p2g1, p2p1g0, p2p1p0cin; 
    and p2g1gate(p2g1, P[2], G[1]); 
    and p2p1g0gate(p2p1g0, P[2], P[1], G[0]); 
    and p2p1p0cingate(p2p1p0cin, P[2], P[1], P[0], Cin); 
    or c3gate(C[3], G[2], p2g1, p2p1g0, p2p1p0cin); 

     // C[4] = G[3] + P[3]*G[2] + P[3]*P[2]*G[1] + P[3]*P[2]*P[1]*G[0] + P[3]*P[2]*P[1]*P[0]*Cin

     wire p3g2, p3p2g1, p3p2p1g0, p3p2p1p0cin; 
     and p3g2gate(p3g2, P[3], G[2]); 
     and p3p2g1gate(p3p2g1, P[3], P[2], G[1]); 
     and p3p2p1g0gate(p3p2p1g0, P[3], P[2], P[1], G[0]); 
     and p3p2p1p0cingate(p3p2p1p0cin, P[3], P[2], P[1], P[0], Cin); 
     or c4gate(C[4], G[3], p3g2, p3p2g1, p3p2p1g0, p3p2p1p0cin); 

    // C[5] = G[4] + P[4]*G[3] + P[4]*P[3]*G[2] + P[4]*P[3]*P[2]*G[1] + P[4]*P[3]*P[2]*P[1]*G[0] + P[4]*P[3]*P[2]*P[1]*P[0]*Cin

    wire p4g3, p4p3g2, p4p3p2g1, p4p3p2p1g0, p4p3p2p1p0cin; 
    and p4g3gate(p4g3, P[4], G[3]); 
    and p4p3g2gate(p4p3g2, P[4], P[3], G[2]); 
    and p4p3p2g1gate(p4p3p2g1, P[4], P[3], P[2], G[1]); 
    and p4p3p2p1g0gate(p4p3p2p1g0, P[4], P[3], P[2], P[1], G[0]); 
    and p4p3p2p1p0cingate(p4p3p2p1p0cin, P[4], P[3], P[2], P[1], P[0], Cin); 
    or c5gate(C[5], G[4], p4g3, p4p3g2, p4p3p2g1, p4p3p2p1g0, p4p3p2p1p0cin); 

    // C[6] = G[5] + P[5]*G[4] + P[5]*P[4]*G[3] + P[5]*P[4]*P[3]*G[2] + P[5]*P[4]*P[3]*P[2]*G[1] + P[5]*P[4]*P[3]*P[2]*P[1]*G[0] + P[5]*P[4]*P[3]*P[2]*P[1]*P[0]*Cin

    wire p5g4, p5p4g3, p5p4p3g2, p5p4p3p2g1, p5p4p3p2p1g0, p5p4p3p2p1p0cin; 
    and p5g4gate(p5g4, P[5], G[4]); 
    and p5p4g3gate(p5p4g3, P[5], P[4], G[3]); 
    and p5p4p3g2gate(p5p4p3g2, P[5], P[4], P[3], G[2]); 
    and p5p4p3p2g1gate(p5p4p3p2g1, P[5], P[4], P[3], P[2], G[1]); 
    and p5p4p3p2p1g0gate(p5p4p3p2p1g0, P[5], P[4], P[3], P[2], P[1], G[0]); 
    and p5p4p3p2p1p0cingate(p5p4p3p2p1p0cin, P[5], P[4], P[3], P[2], P[1], P[0], Cin); 
    or c6gate(C[6], G[5], p5g4, p5p4g3, p5p4p3g2, p5p4p3p2g1, p5p4p3p2p1g0, p5p4p3p2p1p0cin); 

    //C[7] = G[6] + P[6]*G[5] + P[6]*P[5]*G[4] ...
    
    wire p6g5, p6p5g4, p6p5p4g3, p6p5p4p3g2, p6p5p4p3p2g1, p6p5p4p3p2p1g0, p6p5p4p3p2p1p0cin; 

    and p6g5gate(p6g5, P[6], G[5]); 
    and p6p5g4gate(p6p5g4, P[6], P[5], G[4]); 
    and p6p5p4g3gate(p6p5p4g3, P[6], P[5], P[4], G[3]); 
    and p6p5p4p3g2gate(p6p5p4p3g2, P[6], P[5], P[4], P[3], G[2]); 
    and p6p5p4p3p2g1gate(p6p5p4p3p2g1, P[6], P[5], P[4], P[3], P[2], G[1]); 
    and p6p5p4p3p2p1g0gate(p6p5p4p3p2p1g0, P[6], P[5], P[4], P[3], P[2], P[1], G[0]); 
    and p6p5p4p3p2p1p0cingate(p6p5p4p3p2p1p0cin, P[6], P[5], P[4], P[3], P[2], P[1], P[0], Cin); 
    or c7gate(C[7], G[6], p6g5, p6p5g4, p6p5p4g3, p6p5p4p3g2, p6p5p4p3p2g1, p6p5p4p3p2p1g0, p6p5p4p3p2p1p0cin); 

    //Cout = G[7] + P[7]*G[6] + P[7]*P[6]*G[5]...

    wire p7g6, p7p6g5, p7p6p5g4, p7p6p5p4g3, p7p6p5p4p3g2, p7p6p5p4p3p2g1, p7p6p5p4p3p2p1g0, p7p6p5p4p3p2p1p0cin; 
    
    and p7g6gate(p7g6, P[7], G[6]); 
    and p7p6g5gate(p7p6g5, P[7], P[6], G[5]); 
    and p7p6p5g4gate(p7p6p5g4, P[7], P[6], P[5], G[4]); 
    and p7p6p5p4g3gate(p7p6p5p4g3, P[7], P[6], P[5], P[4], G[3]); 
    and p7p6p5p4p3g2gate(p7p6p5p4p3g2, P[7], P[6], P[5], P[4], P[3], G[2]); 
    and p7p6p5p4p3p2g1gate(p7p6p5p4p3p2g1, P[7], P[6], P[5], P[4], P[3], P[2], G[1]); 
    and p7p6p5p4p3p2p1g0gate(p7p6p5p4p3p2p1g0, P[7], P[6], P[5], P[4], P[3], P[2], P[1], G[0]); 
    and p7p6p5p4p3p2p1p0cingate(p7p6p5p4p3p2p1p0cin, P[7], P[6], P[5], P[4], P[3], P[2], P[1], P[0], Cin); 
    or coutgate(Cout, G[7], p7g6, p7p6g5, p7p6p5g4, p7p6p5p4g3, p7p6p5p4p3g2, p7p6p5p4p3p2g1, p7p6p5p4p3p2p1g0, p7p6p5p4p3p2p1p0cin); 

// Sums
    xor s0(S[0], A[0], B[0], C[0]); 
    xor s1(S[1], A[1], B[1], C[1]);
    xor s2(S[2], A[2], B[2], C[2]);
    xor s3(S[3], A[3], B[3], C[3]);
    xor s4(S[4], A[4], B[4], C[4]);
    xor s5(S[5], A[5], B[5], C[5]);
    xor s6(S[6], A[6], B[6], C[6]);
    xor s7(S[7], A[7], B[7], C[7]);

// Propogate and Generate for entire block

    and propgroup(P_group, P[7], P[6], P[5], P[4], P[3], P[2], P[1], P[0]);
    or gengroup(G_group, G[7], p7g6, p7p6g5, p7p6p5g4, p7p6p5p4g3, p7p6p5p4p3g2, p7p6p5p4p3p2g1, p7p6p5p4p3p2p1g0); 


endmodule



