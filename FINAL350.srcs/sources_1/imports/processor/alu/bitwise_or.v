module bitwise_or(A, B, result); 

    input [31:0] A, B; 
    output [31:0] result; 

    genvar i; 
    generate 
        for(i=0; i<32; i=i+1) begin : gates
            or or_gate(result[i], A[i], B[i]); 

        end 
    endgenerate


endmodule
