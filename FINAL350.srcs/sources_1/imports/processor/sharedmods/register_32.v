module register_32(input clock, input reset, input enable, input [31:0] data_in, output [31:0] data_out); 


    genvar i; 
    generate
            for (i=0; i<32; i=i+1) begin : dff
                dffe_ref flip_flop(.q(data_out[i]), .d(data_in[i]), .clk(clock), .en(enable), .clr(reset)); 
            end 
    endgenerate

        

endmodule