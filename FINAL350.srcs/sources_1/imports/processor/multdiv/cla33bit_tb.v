module cla33bit_tb;
    reg [32:0] A, B;
    reg Cin;
    wire [32:0] S;
    integer i;
    reg [32:0] test_a [0:7];
    reg [32:0] test_b [0:7];
    reg test_cin [0:7];
    
    cla33bit checking(.A(A), .B(B), .Cin(Cin), .S(S));
    
    initial begin
        // Load test cases
        test_a[0] = 33'd5;        test_b[0] = 33'd3;      test_cin[0] = 0;
        test_a[1] = 33'd100;      test_b[1] = 33'd200;    test_cin[1] = 0;
        test_a[2] = 33'd10;       test_b[2] = ~33'd3;     test_cin[2] = 1;
        test_a[3] = -33'd5;       test_b[3] = 33'd3;      test_cin[3] = 0;
        test_a[4] = -33'd10;      test_b[4] = -33'd20;    test_cin[4] = 0;
        test_a[5] = 33'd0;        test_b[5] = 33'd0;      test_cin[5] = 0;
        test_a[6] = 33'h1FFFFFFF; test_b[6] = 33'd1;      test_cin[6] = 0;
        test_a[7] = -33'd1;       test_b[7] = 33'd1;      test_cin[7] = 0;
        
        $display("Test | A      | B      | Cin | Sum");
        
        for (i = 0; i < 8; i = i + 1) begin
            A = test_a[i];
            B = test_b[i];
            Cin = test_cin[i];
            #10;
            $display("%d    | %d  | %d  | %b   | %d", 
                     i, $signed(A), $signed(B), Cin, $signed(S));
        end
        
        $finish;
    end
endmodule