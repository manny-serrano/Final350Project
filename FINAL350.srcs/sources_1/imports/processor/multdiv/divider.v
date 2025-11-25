module divider(
    input [31:0] A, B,
    input clock, start,
    output [31:0] result,
    output exception, ready
);
    // Check for divide by zero
    assign exception = ~(|B);
    
    // Compute and latch result sign 
    wire result_sign;
    dffe_ref sign_ff(
        .q(result_sign),
        .d(A[31] ^ B[31]),  
        .clk(clock),
        .en(start),
        .clr(1'b0)
    );
    // 32-cycle counter and state machine
    wire [5:0] count;
    wire counter_done, activediv;
    wire counter_enable;
    assign counter_enable = activediv & ~counter_done & ~start;
    
    divcounter div_counter(
        .clock(clock),
        .enable(counter_enable),
        .reset(start),
        .count(count),
        .done(counter_done)
    );
    
    control_fsm fsm(
        .clock(clock),
        .start(start),
        .counter_done(counter_done),
        .active(activediv),
        .ready(ready)
    );
    
    // Compute absolute values
    wire [31:0] A_abs_direct, B_abs_direct;
    absvalue abs_A(.in(A), .out(A_abs_direct));
    absvalue abs_B(.in(B), .out(B_abs_direct));
    
    //  Latch divisor on start
    wire [31:0] B_abs_latched;
    register_32 b_abs_reg(
        .clock(clock),
        .reset(1'b0),
        .enable(start),
        .data_in(B_abs_direct),
        .data_out(B_abs_latched)
    );
    
    // Combined 64-bit register: {Remainder[31:0], Quotient[31:0]}
    wire [63:0] divreg_current, divreg_next;
    wire [31:0] remainder_current, quotient_current;
    
    assign remainder_current = divreg_current[63:32];
    assign quotient_current = divreg_current[31:0];
    
    // Restoring division algorithm
   // shift left by 1 (R = R << 1 | Q[31], Q = Q << 1)
    wire [31:0] remainder_shifted, quotient_shifted;
    assign remainder_shifted = {remainder_current[30:0], quotient_current[31]};
    assign quotient_shifted = {quotient_current[30:0], 1'b0};
    
    // Subtract divisor from shifted remainder 
    wire [31:0] remainder_sub;
    wire cout_sub;
    cla32bit subtractor(
        .A(remainder_shifted),
        .B(~B_abs_latched),  
        .Cin(1'b1),
        .S(remainder_sub),
        .Cout(cout_sub)
    );
    
    // Restore or keep subtraction result based on carry-out
    //If subtraction succeeded (cout=1), keep result; else restore
    wire [31:0] remainder_final, quotient_final;
    assign remainder_final = cout_sub ? remainder_sub : remainder_shifted;
    assign quotient_final = {quotient_shifted[31:1], cout_sub};
    
    // Mux: load initial on start, else update
    // Initialize with {0, A_abs} on start

    assign divreg_next = start ? {32'b0, A_abs_direct} : {remainder_final, quotient_final};
    
    // 64-bit combined register
    register_64 divreg(
        .clock(clock),
        .reset(1'b0),
        .enable(start | counter_enable),  // Inline logic
        .data_in(divreg_next),
        .data_out(divreg_current)
    );
    
    // Apply sign to result 
    wire [31:0] quotient_negated;
    wire unused_cout, unused_ovf;
    cla32bit negate_result(
        .A(~quotient_current),  
        .B(32'b0),
        .Cin(1'b1),
        .S(quotient_negated),
        .Cout(unused_cout),
        .Overflow(unused_ovf)
    );
    
    // select the result sign based off original latched sign
    assign result = result_sign ? quotient_negated : quotient_current;

endmodule