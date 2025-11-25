module booth_multiplier(
    input [31:0] A, B, 
    input clock, start, 
    output [31:0] result, 
    output overflow, ready
); 

    genvar i;
    // Latch inputs when start asserted 
    wire [31:0] A_latched, B_latched;
    generate 
        for (i = 0; i < 32; i = i + 1) begin: inputlatches
            dffe_ref ff_a(.q(A_latched[i]), .d(A[i]), .clk(clock), .en(start), .clr(1'b0));
            dffe_ref ff_b(.q(B_latched[i]), .d(B[i]), .clk(clock), .en(start), .clr(1'b0));
        end
    endgenerate

    // Use latched values for computation
    // Sign-extend latched operands to 33 bits for signed arithmetic

    wire [32:0] M, Q_init; 
    assign M = {A_latched[31], A_latched}; 
    assign Q_init = {B_latched[31], B_latched};

    // Control and counter 
    wire [4:0] count; 
    wire counter_done, activemult; 
    wire counter_enable;
    assign counter_enable = activemult & ~counter_done; 

    counter counterer(
        .clock(clock), 
        .enable(counter_enable),  
        .reset(start), 
        .count(count), 
        .done(counter_done)
    );
    // FSM: controls multiplication state (idle vs computing)

    control_fsm fsm(
        .clock(clock), 
        .start(start), 
        .counter_done(counter_done), 
        .active(activemult), 
        .ready(ready)
    ); 

    // Product register: 66-bit {Accumulator[32:0], Q[32:0]}
    wire [65:0] productcurrent, productnext;
    wire [32:0] acc_current, qcurrent; 
    assign acc_current = productcurrent[65:33]; 
    assign qcurrent = productcurrent[32:0];

    // Previous q[0] bit
    wire q_previous, q_prev_next; 
    assign q_prev_next = start ? 1'b0 : qcurrent[1];
    dffe_ref q_prev_ff(.q(q_previous), .d(q_prev_next), .clk(clock), .en(1'b1), .clr(1'b0));

    // Examine 3 bits from booth encoder
    wire [2:0] booth_bits; 
    assign booth_bits = {qcurrent[1], qcurrent[0], q_previous}; 

    wire add_1x, add_2x, sub_1x, sub_2x; 

    boothencoder encoder(
        .booth_bits(booth_bits), 
        .add_1x(add_1x), 
        .add_2x(add_2x), 
        .sub_1x(sub_1x), 
        .sub_2x(sub_2x)
    ); 

    // Booth mux selecting value to add/subtract 
    wire [32:0] selected_val; 
    wire is_subtract; 

    booth_mux mux(
        .M(M),
        .add_1x(add_1x),
        .add_2x(add_2x),
        .sub_1x(sub_1x),
        .sub_2x(sub_2x),
        .selected(selected_val),
        .is_subtract(is_subtract)
    );

    // 33-bit addition/subtraction 
    wire [32:0] acc_next;
    cla33bit adder(
        .A(acc_current),
        .B(selected_val),
        .Cin(is_subtract), // Cin = 1 for subtract
        .S(acc_next)
    );

    // Update product: new accumulator + current Q
    wire [65:0] product_updated;
    assign product_updated = {acc_next, qcurrent};

    // Shift right by 2 (arithmetic)
    wire [65:0] shiftedproduct;
    assign shiftedproduct = {product_updated[65], product_updated[65], product_updated[65:2]};
    
     // Initial product value
    wire [65:0] product_initial;
    wire [32:0] Q_init_direct;
    assign Q_init_direct = {B[31], B};  // Direct from input port
    assign product_initial = {33'b0, Q_init_direct};
    // Mux: load initial product on start, else shift

    assign productnext = start ? product_initial : shiftedproduct;

    // Enable product register when starting or actively computing
    wire reg_enable;
    assign reg_enable = start | (activemult & ~counter_done);

    // 66-bit product register

    generate
        for (i = 0; i < 66; i = i + 1) begin: product_reg
            dffe_ref ff(
                .q(productcurrent[i]),
                .d(productnext[i]),
                .clk(clock),
                .en(reg_enable),
                .clr(1'b0)
            );
        end
    endgenerate

    // Extract result from bits [32:1] (middle 32, truncate outerbits)
    assign result = productcurrent[32:1];

    // Overflow detection: check if upper bits are sign extension of result

    wire sign_bit;
    assign sign_bit = productcurrent[32];

// XOR upper bits with sign bit; any mismatch is overflow
    wire [32:0] upper_bits_mismatch;
    assign upper_bits_mismatch = productcurrent[65:33] ^ {33{sign_bit}};

    // Overflow if any upper bit doesn't match sign extension
    assign overflow = |upper_bits_mismatch;
    
endmodule