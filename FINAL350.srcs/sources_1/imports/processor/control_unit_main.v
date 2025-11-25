module control_unit_main(
    input [4:0] opcode,
    input [4:0] alu_op,
    
    output is_rtype,
    output is_addi,

    output is_sw, 
    output is_lw,
    output is_bne, 
    output is_blt, 

    output is_j, 
    output is_jal, 
    output is_jr,

    output is_bex, 
    output is_setx,

    output is_mul, 
    output is_div,
    output is_branch, 
    output is_jump, 

    output rwe, // Register write enable
    output mem_write_enable,    // Write to data memory
    output mem_to_reg, 
    output alu_src,  
    output [4:0] alu_opcode

);

    wire [4:0] OP_RTYPE, OP_ADDI, OP_SW, OP_LW, OP_J, OP_BNE, OP_JAL, OP_JR, OP_BLT, OP_BEX, OP_SETX;

    // Opcode definitions
    assign OP_RTYPE = 5'b00000;
    assign OP_ADDI  = 5'b00101;
    assign OP_SW    = 5'b00111;
    assign OP_LW    = 5'b01000;
    assign OP_J     = 5'b00001;
    assign OP_BNE   = 5'b00010;
    assign OP_JAL   = 5'b00011;
    assign OP_JR    = 5'b00100;
    assign OP_BLT   = 5'b00110;
    assign OP_BEX   = 5'b10110;
    assign OP_SETX  = 5'b10101;

    // Instruction types 
    assign is_rtype = (opcode == OP_RTYPE);
    assign is_addi  = (opcode == OP_ADDI);
    assign is_sw    = (opcode == OP_SW);
    assign is_lw    = (opcode == OP_LW);
    assign is_bne   = (opcode == OP_BNE);
    assign is_blt   = (opcode == OP_BLT);
    assign is_j     = (opcode == OP_J);
    assign is_jal   = (opcode == OP_JAL);
    assign is_jr    = (opcode == OP_JR);
    assign is_bex   = (opcode == OP_BEX);
    assign is_setx  = (opcode == OP_SETX);

    // R type mul/div
    assign is_mul   = is_rtype & (alu_op == 5'b00110); // MUL   
    assign is_div   = is_rtype & (alu_op == 5'b00111); // DIV

    // Combined signals
    assign is_branch = is_bne | is_blt | is_bex;
    assign is_jump   = is_j | is_jal | is_jr;


    
    assign rwe = is_rtype | is_addi | is_lw | is_jal | is_setx;   // Register write enable: R-type, addi, lw, jal, setx
    assign alu_src = is_addi | is_lw | is_sw | is_branch; 
    
    assign mem_to_reg = is_lw; // Memory to register: only lw uses memory data
    assign mem_write_enable = is_sw;  // Memory write enable: only sw writes to memory

    
    // ALU opcode mux

    wire [4:0] ALU_ADD, ALU_SUB; 
    assign ALU_ADD = 5'b00000;
    assign ALU_SUB = 5'b00001;  // SUB for branches (bne, blt, bex)

    
    // ALU opcode selection:
    // - Branches (bne, blt, bex) use SUB
    // - R-type uses alu_op field
    // - Everything else (addi, lw, sw) uses ADD
    assign alu_opcode = is_branch ? ALU_SUB :      
                        is_rtype ? alu_op :        
                        ALU_ADD;                  

endmodule