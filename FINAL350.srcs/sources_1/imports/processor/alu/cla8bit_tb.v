`timescale 1ns / 100ps


module cla8bit_tb; 


    reg [7:0] A,B; 
    reg Cin; 
    wire [7:0] S; 
    wire Cout, P_group, G_group; 

    cla8bit addertest(.A(A), .B(B), .Cin(Cin), .S(S), .Cout(Cout), .P_group(P_group), .G_group(G_group)); 

    initial begin

        A = 8'b00000001; B = 8'b00000010; Cin = 1'b0; #10;
        $display("A:%b, B:%b, Cin:%b => S:%b, Cout:%b", A, B, Cin, S, Cout);
        
        A = 8'b11111111; B = 8'b00000001; Cin = 1'b0; #10;
        $display("A:%b, B:%b, Cin:%b => S:%b, Cout:%b", A, B, Cin, S, Cout);
        
        A = 8'b10101010; B = 8'b01010101; Cin = 1'b1; #10;
        $display("A:%b, B:%b, Cin:%b => S:%b, Cout:%b", A, B, Cin, S, Cout);
        
        A = 8'b11110000; B = 8'b00001111; Cin = 1'b0; #10;
        $display("A:%b, B:%b, Cin:%b => S:%b, Cout:%b, P_group:%b, G_group:%b", A, B, Cin, S, Cout, P_group, G_group);
        
        $finish;
    end
    


endmodule