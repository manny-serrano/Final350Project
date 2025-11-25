// register_64.v
module register_64(
    input clock, 
    input reset, 
    input enable, 
    input [63:0] data_in, 
    output [63:0] data_out
); 
    genvar i; 
    generate
        for (i=0; i<64; i=i+1) begin : dff
            dffe_ref flip_flop(
                .q(data_out[i]), 
                .d(data_in[i]), 
                .clk(clock), 
                .en(enable), 
                .clr(reset)
            ); 
        end 
    endgenerate
endmodule