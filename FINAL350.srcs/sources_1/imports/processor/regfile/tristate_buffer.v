module tristate_buffer(input[31:0] in, input enable, output [31:0] out ); 

    genvar i; 
    generate
        for (i=0; i<32; i=i+1) begin: tristates
            assign out[i] = enable ? in[i] :1'bz; 

        end
    


    endgenerate



endmodule