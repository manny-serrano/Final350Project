// Extracts fields from 32-bit instruction
module decoderunit(
    input [31:0] instruction,
    
    // R-type and I-type fields
    output [4:0] opcode,
    output [4:0] rd,
    output [4:0] rs,
    output [4:0] rt,
    output [4:0] shamt,
    output [4:0] alu_op,
    output [16:0] immediate,
    
    // J-type field 
    output [26:0] target
);

    // Instruction format:
    // R-type: [opcode][rd][rs][rt][shamt][alu_op][00]
    // I-type: [opcode][rd][rs][immediate]
    // J-type: [opcode][target]
    
    assign opcode = instruction[31:27];
    assign rd = instruction[26:22];
    assign rs = instruction[21:17];
    assign rt = instruction[16:12];
    assign shamt = instruction[11:7];
    assign alu_op = instruction[6:2];
    assign immediate = instruction[16:0];
    assign target = instruction[26:0];

endmodule