// Sign extends a 17-bit immediate to 32 bits
module signextend(
    input [16:0] immediate,
    output [31:0] extended
);
    // Bit 16 is the sign bit
    // Replicate it to bits [31:17]
    assign extended[16:0] = immediate[16:0];
    assign extended[17] = immediate[16];
    assign extended[18] = immediate[16];
    assign extended[19] = immediate[16];
    assign extended[20] = immediate[16];
    assign extended[21] = immediate[16];
    assign extended[22] = immediate[16];
    assign extended[23] = immediate[16];
    assign extended[24] = immediate[16];
    assign extended[25] = immediate[16];
    assign extended[26] = immediate[16];
    assign extended[27] = immediate[16];
    assign extended[28] = immediate[16];
    assign extended[29] = immediate[16];
    assign extended[30] = immediate[16];
    assign extended[31] = immediate[16];
    
endmodule