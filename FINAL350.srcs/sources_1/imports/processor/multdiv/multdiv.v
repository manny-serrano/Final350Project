module multdiv(
    data_operandA, data_operandB, 
    ctrl_MULT, ctrl_DIV, 
    clock, 
    data_result, data_exception, data_resultRDY);

    input [31:0] data_operandA, data_operandB;
    input ctrl_MULT, ctrl_DIV, clock;

    output [31:0] data_result;
    output data_exception, data_resultRDY;

    // Track which operation is active
    // Latches the operation type when ctrl_MULT or ctrl_DIV asserted
    wire active_is_div, active_is_div_next;
    assign active_is_div_next = ctrl_DIV ? 1'b1 : ctrl_MULT ? 1'b0 : active_is_div;
    
    dffe_ref active_op_ff(
        .q(active_is_div), 
        .d(active_is_div_next), 
        .clk(clock), 
        .en(1'b1), 
        .clr(1'b0)
    );

    // Multiplication using modified booth
    wire [31:0] mult_result;
    wire mult_overflow, mult_ready;
    
    booth_multiplier multiplier(
        .A(data_operandA),
        .B(data_operandB),
        .clock(clock),
        .start(ctrl_MULT),
        .result(mult_result),
        .overflow(mult_overflow),
        .ready(mult_ready)
    );
    // Division ready signal (1 cycle delay)

    wire [31:0] div_result;
    wire div_exception, div_ready;
    
    divider div_unit(
        .A(data_operandA),
        .B(data_operandB),
        .clock(clock),
        .start(ctrl_DIV),
        .result(div_result),
        .exception(div_exception),
        .ready(div_ready)
    );
    
    // Mux outputs based on which operation is active

    assign data_result = active_is_div ? div_result : mult_result;
    assign data_exception = active_is_div ? div_exception : mult_overflow;
    assign data_resultRDY = active_is_div ? div_ready : mult_ready;

endmodule