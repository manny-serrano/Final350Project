// this mux selects what value to add based on the encoder// 

//M is multiplicand, number being multiplied, 33 bits for correct handling of modified booth

// inputs from encoder, one of these is going to be high

module booth_mux(input[32:0] M, input add_1x, add_2x, sub_1x, sub_2x, output [32:0] selected, 
output is_subtract); 

    wire [32:0] Mtimes2; 
    assign Mtimes2 = {M[31:0], 1'b0}; 
    // shift M left by 1 which multiplies by 2, this dropes the sign bit and appends a 0 to the right

    wire [32:0] magnitude; 
    assign magnitude = add_2x ? Mtimes2 : sub_2x ? Mtimes2 : add_1x ? M : sub_1x ? M : 33'b0; 

    // check if we need to subtract

    or sub_gate(is_subtract, sub_1x, sub_2x); 
    assign selected = is_subtract ? ~magnitude : magnitude; 
    // invert if subtracting, for 2s complement 


endmodule