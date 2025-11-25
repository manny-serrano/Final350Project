/**
 * READ THIS DESCRIPTION!
 *
 * This is your processor module that will contain the bulk of your code submission. You are to implement
 * a 5-stage pipelined processor in this module, accounting for hazards and implementing bypasses as
 * necessary.
 *
 * Ultimately, your processor will be tested by a master skeleton, so the
 * testbench can see which controls signal you active when. Therefore, there needs to be a way to
 * "inject" imem, dmem, and regfile interfaces from some external controller module. The skeleton
 * file, Wrapper.v, acts as a small wrapper around your processor for this purpose. Refer to Wrapper.v
 * for more details.
 *
 * As a result, this module will NOT contain the RegFile nor the memory modules. Study the inputs 
 * very carefully - the RegFile-related I/Os are merely signals to be sent to the RegFile instantiated
 * in your Wrapper module. This is the same for your memory elements. 
 *
 *
 */module processor(
    // Control signals
    clock,                          // I: The master clock
    reset,                          // I: A reset signal

    // Imem
    address_imem,                   // O: The address of the data to get from imem
    q_imem,                         // I: The data from imem

    // Dmem
    address_dmem,                   // O: The address of the data to get or put from/to dmem
    data,                           // O: The data to write to dmem
    wren,                           // O: Write enable for dmem
    q_dmem,                         // I: The data from dmem

    // Regfile
    ctrl_writeEnable,               // O: Write enable for RegFile
    ctrl_writeReg,                  // O: Register to write to in RegFile
    ctrl_readRegA,                  // O: Register to read from port A of RegFile
    ctrl_readRegB,                  // O: Register to read from port B of RegFile
    data_writeReg,                  // O: Data to write to for RegFile
    data_readRegA,                  // I: Data from port A of RegFile
    data_readRegB                   // I: Data from port B of RegFile
);

    // Control signals
    input clock, reset;
    
    // Imem
    output [31:0] address_imem;
    input [31:0] q_imem;

    // Dmem
    output [31:0] address_dmem, data;
    output wren;
    input [31:0] q_dmem;

    // Regfile
    output ctrl_writeEnable;
    output [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
    output [31:0] data_writeReg;
    input [31:0] data_readRegA, data_readRegB;

    /* ===== PIPELINE CONTROL SIGNALS ===== */
    wire [31:0] x_next_pc;
    wire x_pc_change, multdiv_stall, load_use_stall;
    wire dx_mem_to_reg;
    wire [4:0] dx_rd_out, d_rs1, d_rs2;
    
    // Stall and flush control
    wire stall_F_D_PC, flush_F_D, flush_D_X;
    assign stall_F_D_PC = multdiv_stall | load_use_stall;
    assign flush_F_D = x_pc_change;
    assign flush_D_X = x_pc_change | load_use_stall;

    /* ===== FETCH STAGE ===== */
    wire [31:0] pccurrent, pcnext, pc_plus_one;
    wire pc_overflow, pc_cout;
    
    cla32bit pc_adder(.A(pccurrent), .B(32'd1), .Cin(1'b0), .S(pc_plus_one), 
                      .Overflow(pc_overflow), .Cout(pc_cout));
    
    assign pcnext = x_pc_change ? x_next_pc : pc_plus_one;
    
    register_32 pc_reg(.clock(clock), .reset(reset), .enable(~stall_F_D_PC),
                       .data_in(pcnext), .data_out(pccurrent));
    
    assign address_imem = pccurrent;

    /* ===== F/D LATCH ===== */
    wire [31:0] fdInstruction, fd_pc;
    
    register_32 fd_insn_reg(.clock(~clock), .reset(reset), .enable(~stall_F_D_PC),
                            .data_in(flush_F_D ? 32'd0 : q_imem), .data_out(fdInstruction));
    
    register_32 fd_pc_reg(.clock(clock), .reset(reset), .enable(~stall_F_D_PC),
                          .data_in(pccurrent), .data_out(fd_pc));

    /* ===== DECODE STAGE ===== */
    wire [4:0] d_opcode, d_rd, d_rs, d_rt, d_shamt, d_alu_op;
    wire [16:0] d_immediate;
    wire [26:0] d_target;
    
    decoderunit insn_decoder(.instruction(fdInstruction), .opcode(d_opcode), .rd(d_rd),
                            .rs(d_rs), .rt(d_rt), .shamt(d_shamt), .alu_op(d_alu_op),
                            .immediate(d_immediate), .target(d_target));

    // Control signals
    wire d_is_rtype, d_is_addi, d_is_sw, d_is_lw, d_is_bne, d_is_blt, d_is_j, d_is_jal;
    wire d_is_jr, d_is_bex, d_is_setx, d_is_branch, d_is_jump, d_is_mul, d_is_div;
    wire d_reg_we, d_alu_src, d_mem_we, d_mem_to_reg;
    wire [4:0] d_alu_opcode;
    
    control_unit_main ctrl_unit(.opcode(d_opcode), .alu_op(d_alu_op), .is_rtype(d_is_rtype),
        .is_addi(d_is_addi), .is_sw(d_is_sw), .is_lw(d_is_lw), .is_bne(d_is_bne),
        .is_blt(d_is_blt), .is_j(d_is_j), .is_jal(d_is_jal), .is_jr(d_is_jr),
        .is_bex(d_is_bex), .is_setx(d_is_setx), .is_mul(d_is_mul), .is_div(d_is_div),
        .is_branch(d_is_branch), .is_jump(d_is_jump), .rwe(d_reg_we),
        .mem_write_enable(d_mem_we), .mem_to_reg(d_mem_to_reg), .alu_src(d_alu_src),
        .alu_opcode(d_alu_opcode));

    // Register source/destination selection
    assign d_rs1 = d_is_bex ? 5'd30 : d_is_jr ? d_rd : (d_is_bne | d_is_blt) ? d_rd :
                   (d_is_rtype | d_is_addi | d_is_lw | d_is_sw) ? d_rs : 5'd0;
    
    assign d_rs2 = d_is_sw ? d_rd : (d_is_bne | d_is_blt) ? d_rs : d_is_rtype ? d_rt : 5'd0;
    
    wire [4:0] d_rd_out;
    assign d_rd_out = d_is_jal ? 5'd31 : d_is_setx ? 5'd30 :
                      (d_is_rtype | d_is_addi | d_is_lw) ? d_rd : 5'd0;
    
    assign ctrl_readRegA = d_rs1;
    assign ctrl_readRegB = d_rs2;

    // Sign extend and operand selection
    wire [31:0] d_immediate_extended, d_operandB;
    signextend sign_ext(.immediate(d_immediate), .extended(d_immediate_extended));
    
    assign d_operandB = d_is_bex ? 32'b0 : (d_alu_src & ~d_is_branch) ? 
                       d_immediate_extended : data_readRegB;

    // Track whether the current instruction actually uses the register B value for ALU computations
    wire d_use_alu_regB;
    assign d_use_alu_regB = ~d_alu_src | d_is_branch;

    // Branch/Jump target calculation
    wire [31:0] d_branch_target, d_jump_target;
    wire branch_target_overflow, branch_cout;
    cla32bit branch_adder(.A(fd_pc), .B(d_immediate_extended), .Cin(1'b0),
                         .S(d_branch_target), .Overflow(branch_target_overflow), .Cout(branch_cout));
    assign d_jump_target = {5'b0, d_target};

    // Load-use hazard detection
    assign load_use_stall = dx_mem_to_reg & (dx_rd_out != 5'd0) & 
                            ((dx_rd_out == d_rs1) | (dx_rd_out == d_rs2));

    /* ===== D/X LATCH ===== */
    wire [31:0] dx_operandA, dx_operandB, dx_branch_target, dx_jump_target, dx_pc_plus_one, dx_rt_data;
    wire [4:0] dx_alu_opcode, dx_shamt, dx_rs1, dx_rs2;
    wire dx_reg_we, dx_mem_we, dx_is_bne, dx_is_blt, dx_is_j, dx_is_jal, dx_is_jr;
    wire dx_is_bex, dx_is_setx, dx_is_branch, dx_is_jump, dx_is_mul, dx_is_div, dx_is_addi;
    wire dx_use_alu_regB;

    // Data latches
    register_32 dx_opA_reg(.clock(~clock), .reset(reset), .enable(~multdiv_stall),
                          .data_in(data_readRegA), .data_out(dx_operandA));
    register_32 dx_opB_reg(.clock(~clock), .reset(reset), .enable(~multdiv_stall),
                          .data_in(d_operandB), .data_out(dx_operandB));
    register_32 dx_rtdata_reg(.clock(~clock), .reset(reset), .enable(~multdiv_stall),
                             .data_in(data_readRegB), .data_out(dx_rt_data));
    register_32 dx_branch_target_reg(.clock(~clock), .reset(reset), .enable(~multdiv_stall),
                                    .data_in(d_branch_target), .data_out(dx_branch_target));
    register_32 dx_jump_target_reg(.clock(~clock), .reset(reset), .enable(~multdiv_stall),
                                  .data_in(d_jump_target), .data_out(dx_jump_target));
    register_32 dx_pc_plus_one_reg(.clock(~clock), .reset(reset), .enable(~multdiv_stall),
                                  .data_in(fd_pc), .data_out(dx_pc_plus_one));
    
    register5 dx_rd_out_reg(.clock(~clock), .reset(reset), .enable(~multdiv_stall),
                           .data_in(d_rd_out), .data_out(dx_rd_out));
    register5 dx_rs1_reg(.clock(~clock), .reset(reset), .enable(~multdiv_stall),
                        .data_in(d_rs1), .data_out(dx_rs1));
    register5 dx_rs2_reg(.clock(~clock), .reset(reset), .enable(~multdiv_stall),
                        .data_in(d_rs2), .data_out(dx_rs2));
    register5 dx_aluop_reg(.clock(~clock), .reset(reset), .enable(~multdiv_stall),
                          .data_in(d_alu_opcode), .data_out(dx_alu_opcode));
    register5 dx_shamt_reg(.clock(~clock), .reset(reset), .enable(~multdiv_stall),
                          .data_in(d_shamt), .data_out(dx_shamt));

    // Control signal latches with flush
    dffe_ref dx_is_bne_latch(.q(dx_is_bne), .d(flush_D_X ? 1'b0 : d_is_bne), .clk(~clock), .en(~multdiv_stall), .clr(reset));
    dffe_ref dx_is_blt_latch(.q(dx_is_blt), .d(flush_D_X ? 1'b0 : d_is_blt), .clk(~clock), .en(~multdiv_stall), .clr(reset));
    dffe_ref dx_is_j_latch(.q(dx_is_j), .d(flush_D_X ? 1'b0 : d_is_j), .clk(~clock), .en(~multdiv_stall), .clr(reset));
    dffe_ref dx_is_jal_latch(.q(dx_is_jal), .d(flush_D_X ? 1'b0 : d_is_jal), .clk(~clock), .en(~multdiv_stall), .clr(reset));
    dffe_ref dx_is_jr_latch(.q(dx_is_jr), .d(flush_D_X ? 1'b0 : d_is_jr), .clk(~clock), .en(~multdiv_stall), .clr(reset));
    dffe_ref dx_is_bex_latch(.q(dx_is_bex), .d(flush_D_X ? 1'b0 : d_is_bex), .clk(~clock), .en(~multdiv_stall), .clr(reset));
    dffe_ref dx_is_branch_latch(.q(dx_is_branch), .d(flush_D_X ? 1'b0 : d_is_branch), .clk(~clock), .en(~multdiv_stall), .clr(reset));
    dffe_ref dx_is_jump_latch(.q(dx_is_jump), .d(flush_D_X ? 1'b0 : d_is_jump), .clk(~clock), .en(~multdiv_stall), .clr(reset));
    dffe_ref dx_is_setx_latch(.q(dx_is_setx), .d(flush_D_X ? 1'b0 : d_is_setx), .clk(~clock), .en(~multdiv_stall), .clr(reset));
    dffe_ref dx_is_addi_latch(.q(dx_is_addi), .d(flush_D_X ? 1'b0 : d_is_addi), .clk(~clock), .en(~multdiv_stall), .clr(reset));
    dffe_ref dx_is_mul_latch(.q(dx_is_mul), .d(flush_D_X ? 1'b0 : d_is_mul), .clk(~clock), .en(~multdiv_stall), .clr(reset));
    dffe_ref dx_is_div_latch(.q(dx_is_div), .d(flush_D_X ? 1'b0 : d_is_div), .clk(~clock), .en(~multdiv_stall), .clr(reset));
    dffe_ref dx_we_latch(.q(dx_reg_we), .d(flush_D_X ? 1'b0 : d_reg_we), .clk(~clock), .en(~multdiv_stall), .clr(reset));
    dffe_ref dx_mem_we_latch(.q(dx_mem_we), .d(flush_D_X ? 1'b0 : d_mem_we), .clk(~clock), .en(~multdiv_stall), .clr(reset));
    dffe_ref dx_mem_to_reg_latch(.q(dx_mem_to_reg), .d(flush_D_X ? 1'b0 : d_mem_to_reg), .clk(~clock), .en(~multdiv_stall), .clr(reset));
    dffe_ref dx_use_regB_latch(.q(dx_use_alu_regB), .d(flush_D_X ? 1'b0 : d_use_alu_regB), .clk(~clock), .en(~multdiv_stall), .clr(reset));

    /* ===== EXECUTE STAGE ===== */
    wire [31:0] m_data, mw_data;
    wire [4:0] xm_rd_out, mw_rd_out, m_actual_write_reg, mw_actual_write_reg;
    wire xm_reg_we, mw_reg_we;

    // Bypass detection for ALU operands
    // Precompute register-write flags so equality logic is shared everywhere
    wire m_stage_writes, w_stage_writes;
    wire m_matches_rs1, m_matches_rs2, w_matches_rs1, w_matches_rs2;

    assign m_stage_writes = xm_reg_we & (m_actual_write_reg != 5'd0);
    assign w_stage_writes = mw_reg_we & (mw_actual_write_reg != 5'd0);
    assign m_matches_rs1 = m_stage_writes & (m_actual_write_reg == dx_rs1);
    assign m_matches_rs2 = m_stage_writes & (m_actual_write_reg == dx_rs2);
    assign w_matches_rs1 = w_stage_writes & (mw_actual_write_reg == dx_rs1);
    assign w_matches_rs2 = w_stage_writes & (mw_actual_write_reg == dx_rs2);

    wire mx_bypass_a, mx_bypass_b, wx_bypass_a, wx_bypass_b;
    assign mx_bypass_a = m_matches_rs1;
    assign mx_bypass_b = dx_use_alu_regB & m_matches_rs2;
    assign wx_bypass_a = w_matches_rs1 & ~mx_bypass_a;
    assign wx_bypass_b = dx_use_alu_regB & w_matches_rs2 & ~mx_bypass_b;

    // Bypassed operands
    wire [31:0] x_operand_a_final, x_operand_b_final;
    assign x_operand_a_final = mx_bypass_a ? m_data : wx_bypass_a ? mw_data : dx_operandA;
    assign x_operand_b_final = mx_bypass_b ? m_data : wx_bypass_b ? mw_data : dx_operandB;

    // Bypass detection for store data (need both M->X and W->X cases)
    wire mx_bypass_sw_data, wx_bypass_sw_data;
    wire [31:0] dx_rt_data_bypassed;
    // Bypass from memory stage when: instruction writes to reg, not $0, matches store's source reg, and current is store
    // For loads, m_data comes from q_dmem which is only available in memory stage, so we need this bypass

    // Store data reuses the same match results as operand B
    assign mx_bypass_sw_data = dx_mem_we & m_matches_rs2;
    // When the producer has already reached writeback (e.g., after a load-use stall), use MW stage for bypassing
    assign wx_bypass_sw_data = dx_mem_we & w_matches_rs2 & ~mx_bypass_sw_data;
    assign dx_rt_data_bypassed = mx_bypass_sw_data ? m_data :
                                 wx_bypass_sw_data ? mw_data :
                                 dx_rt_data;

    // ALU
    wire [31:0] x_alu_result;
    wire x_isNotEqual, x_isLessThan, x_overflow;
    alu main_alu(.data_operandA(x_operand_a_final), .data_operandB(x_operand_b_final),
                 .ctrl_ALUopcode(dx_alu_opcode), .ctrl_shiftamt(dx_shamt),
                 .data_result(x_alu_result), .isNotEqual(x_isNotEqual),
                 .isLessThan(x_isLessThan), .overflow(x_overflow));

    // Mult/Div unit with start pulse generation
    // Structural token counter drives precise mult/div start pulses
    wire multdiv_start_mult, multdiv_start_div;
    wire [31:0] fd_issue_counter, fd_issue_counter_next;
    wire [31:0] dx_issue_id;
    wire [31:0] multdiv_issue_id;
    wire [31:0] fd_issue_counter_increment;
    wire fd_issue_counter_cout, fd_issue_counter_overflow;
    wire fd_issue_counter_enable, dx_issue_id_enable, multdiv_issue_id_enable;
    wire dx_has_new_instruction;

    assign fd_issue_counter_increment = 32'd1;
    assign fd_issue_counter_enable = ~stall_F_D_PC;
    assign dx_issue_id_enable = ~multdiv_stall;
    assign dx_has_new_instruction = (dx_issue_id != multdiv_issue_id);
    assign multdiv_issue_id_enable = dx_has_new_instruction & (dx_is_mul | dx_is_div);
    assign multdiv_start_mult = dx_is_mul & dx_has_new_instruction;
    assign multdiv_start_div = dx_is_div & dx_has_new_instruction;

    cla32bit fd_issue_counter_adder(
        .A(fd_issue_counter),
        .B(fd_issue_counter_increment),
        .Cin(1'b0),
        .S(fd_issue_counter_next),
        .Overflow(fd_issue_counter_overflow),
        .Cout(fd_issue_counter_cout)
    );

    register_32 fd_issue_counter_reg(
        .clock(~clock),
        .reset(reset),
        .enable(fd_issue_counter_enable),
        .data_in(fd_issue_counter_next),
        .data_out(fd_issue_counter)
    );

    register_32 dx_issue_id_reg(
        .clock(~clock),
        .reset(reset),
        .enable(dx_issue_id_enable),
        .data_in(fd_issue_counter),
        .data_out(dx_issue_id)
    );

    register_32 multdiv_issue_id_reg(
        .clock(~clock),
        .reset(reset),
        .enable(multdiv_issue_id_enable),
        .data_in(dx_issue_id),
        .data_out(multdiv_issue_id)
    );

    wire [31:0] multdivresult;
    wire multdiv_exception, multdiv_ready;
    multdiv multdiv_unit(.data_operandA(x_operand_a_final), .data_operandB(x_operand_b_final),
                        .ctrl_MULT(multdiv_start_mult), .ctrl_DIV(multdiv_start_div),
                        .clock(clock), .data_result(multdivresult),
                        .data_exception(multdiv_exception), .data_resultRDY(multdiv_ready));

    assign multdiv_stall = (dx_is_mul | dx_is_div) & ~multdiv_ready;

    // Result selection
    wire x_is_multdiv, x_is_add, x_is_sub;
    wire [31:0] x_computation_result;
    assign x_is_multdiv = dx_is_mul | dx_is_div;
    assign x_computation_result = x_is_multdiv ? multdivresult : x_alu_result;
    assign x_is_add = (dx_alu_opcode == 5'b00000);
    assign x_is_sub = (dx_alu_opcode == 5'b00001);

    // Exception detection
    wire x_has_exception;
    wire [31:0] x_exception_result;
    assign x_has_exception = ((x_is_add | x_is_sub) & x_overflow) | (dx_is_addi & x_overflow) |
                            (x_is_multdiv & multdiv_ready & multdiv_exception);
    assign x_exception_result = (dx_is_addi & x_overflow) ? 32'd2 : (x_is_add & x_overflow) ? 32'd1 :
                               (x_is_sub & x_overflow) ? 32'd3 : (dx_is_mul & multdiv_ready & multdiv_exception) ? 32'd4 :
                               (dx_is_div & multdiv_ready & multdiv_exception) ? 32'd5 : 32'd0;

    // Branch/Jump logic
    wire x_branch_taken, bne_taken, blt_taken, bex_taken;
    assign bne_taken = dx_is_bne & x_isNotEqual;
    assign blt_taken = dx_is_blt & x_isLessThan;
    assign bex_taken = dx_is_bex & x_isNotEqual;
    assign x_branch_taken = bne_taken | blt_taken | bex_taken;

    wire [31:0] x_effective_branch_target;
    assign x_effective_branch_target = dx_is_bex ? dx_jump_target : dx_branch_target;
    assign x_next_pc = dx_is_jr ? x_operand_a_final : dx_is_jump ? dx_jump_target :
                       x_branch_taken ? x_effective_branch_target : pc_plus_one;
    assign x_pc_change = dx_is_jr | dx_is_jump | x_branch_taken;

    /* ===== X/M LATCH ===== */
    wire [31:0] xm_result, xm_rt_data, xm_pc_plus_one, xm_jump_target, xm_exception_result;
    wire xm_mem_we, xm_mem_to_reg, xm_is_jal, xm_is_setx, xm_has_exception;
    wire [4:0] xm_rs2;

    register_32 xm_result_reg(.clock(~clock), .reset(reset), .enable(~multdiv_stall),
                             .data_in(x_computation_result), .data_out(xm_result));
    register_32 xm_rt_reg(.clock(~clock), .reset(reset), .enable(~multdiv_stall),
                         .data_in(dx_rt_data_bypassed), .data_out(xm_rt_data));
    register_32 xm_pcplusone_reg(.clock(~clock), .reset(reset), .enable(~multdiv_stall),
                                .data_in(dx_pc_plus_one), .data_out(xm_pc_plus_one));
    register_32 xm_jumptarget_reg(.clock(~clock), .reset(reset), .enable(~multdiv_stall),
                                 .data_in(dx_jump_target), .data_out(xm_jump_target));
    register_32 xm_exception_result_reg(.clock(~clock), .reset(reset), .enable(~multdiv_stall),
                                       .data_in(x_exception_result), .data_out(xm_exception_result));
    
    register5 xm_rd_out_reg(.clock(~clock), .reset(reset), .enable(~multdiv_stall),
                           .data_in(dx_rd_out), .data_out(xm_rd_out));
    register5 xm_rs2_reg(.clock(~clock), .reset(reset), .enable(~multdiv_stall),
                        .data_in(dx_rs2), .data_out(xm_rs2));
    
    dffe_ref xm_is_setx_latch(.q(xm_is_setx), .d(dx_is_setx), .clk(~clock), .en(~multdiv_stall), .clr(reset));
    dffe_ref xm_is_jal_latch(.q(xm_is_jal), .d(dx_is_jal), .clk(~clock), .en(~multdiv_stall), .clr(reset));
    dffe_ref xm_exception_latch(.q(xm_has_exception), .d(x_has_exception), .clk(~clock), .en(~multdiv_stall), .clr(reset));
    dffe_ref xm_we_latch(.q(xm_reg_we), .d(dx_reg_we), .clk(~clock), .en(~multdiv_stall), .clr(reset));
    dffe_ref xm_mem_we_latch(.q(xm_mem_we), .d(dx_mem_we), .clk(~clock), .en(~multdiv_stall), .clr(reset));
    dffe_ref xm_mem_to_reg_latch(.q(xm_mem_to_reg), .d(dx_mem_to_reg), .clk(~clock), .en(~multdiv_stall), .clr(reset));

    /* ===== MEMORY STAGE ===== */
    assign m_actual_write_reg = xm_has_exception ? 5'd30 : xm_is_jal ? 5'd31 :
                               xm_is_setx ? 5'd30 : xm_rd_out;
    
    assign address_dmem = xm_result;

    // SW data bypass
    wire wm_bypass_sw;
    wire [31:0] m_sw_data_final;
    wire w_matches_xm_rs2;
    assign w_matches_xm_rs2 = w_stage_writes & (mw_actual_write_reg == xm_rs2);
    // Allow latest writeback value to feed an immediately following store
    assign wm_bypass_sw = w_matches_xm_rs2;
    assign m_sw_data_final = wm_bypass_sw ? mw_data : xm_rt_data;
    assign data = m_sw_data_final;
    assign wren = xm_mem_we;

    // Memory stage writeback data selection
    assign m_data = xm_has_exception ? xm_exception_result : xm_is_setx ? xm_jump_target :
                   xm_is_jal ? xm_pc_plus_one : xm_mem_to_reg ? q_dmem : xm_result;

    /* ===== M/W LATCH ===== */
    wire [31:0] mw_pc_plus_one;
    wire mw_is_jal, mw_is_setx, mw_has_exception;

    register5 mw_rd_out_reg(.clock(~clock), .reset(reset), .enable(1'b1),
                           .data_in(xm_rd_out), .data_out(mw_rd_out));
    register5 mw_actual_wr_reg(.clock(~clock), .reset(reset), .enable(1'b1),
                              .data_in(m_actual_write_reg), .data_out(mw_actual_write_reg));
    register_32 mw_pcplusone_reg(.clock(~clock), .reset(reset), .enable(1'b1),
                                .data_in(xm_pc_plus_one), .data_out(mw_pc_plus_one));
    register_32 mw_data_reg(.clock(~clock), .reset(reset), .enable(1'b1),
                           .data_in(m_data), .data_out(mw_data));
    
    dffe_ref mw_is_setx_latch(.q(mw_is_setx), .d(xm_is_setx), .clk(~clock), .en(1'b1), .clr(reset));
    dffe_ref mw_is_jal_latch(.q(mw_is_jal), .d(xm_is_jal), .clk(~clock), .en(1'b1), .clr(reset));
    dffe_ref mw_exception_latch(.q(mw_has_exception), .d(xm_has_exception), .clk(~clock), .en(1'b1), .clr(reset));
    dffe_ref mw_we_latch(.q(mw_reg_we), .d(xm_reg_we), .clk(~clock), .en(1'b1), .clr(reset));

    /* ===== WRITEBACK STAGE ===== */
    assign ctrl_writeReg = mw_has_exception ? 5'd30 : mw_is_jal ? 5'd31 :
                          mw_is_setx ? 5'd30 : mw_rd_out;
    assign ctrl_writeEnable = mw_reg_we & (ctrl_writeReg != 5'd0);
    assign data_writeReg = mw_data;

    // this was a trip lol - E.S. 

endmodule