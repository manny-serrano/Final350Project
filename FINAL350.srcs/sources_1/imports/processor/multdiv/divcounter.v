module divcounter(input clock, enable, reset, output [5:0] count, output done); 

    wire [5:0] current, next; 
    wire [31:0] count_32, increment_32; 

    assign count_32 = {26'b0, current};

    wire unusedoverflow, unused_cout;

    cla32bit adder(.A(count_32), .B(32'b1), .Cin(1'b0), .S(increment_32), 
                   .Cout(unused_cout), .Overflow(unusedoverflow)); 

    assign next = reset ? 6'b0 : increment_32[5:0]; 

    // Enable when reset=1 OR (enable=1 AND reset=0)
    wire enable_no_reset, ff_enable;

    wire not_reset;
    not not_reset_gate(not_reset, reset);
    and gate1(enable_no_reset, enable, not_reset);
    or gate2(ff_enable, reset, enable_no_reset);

    genvar i; 
    generate 
        for(i=0; i<6; i=i+1) begin: counterffs
            dffe_ref ff(.q(current[i]), .d(next[i]), .clk(clock), .en(ff_enable), .clr(1'b0)); 
        end
    endgenerate

    assign count = current; 

    // Done when count = 32 = 6'b100000 (bit 5 high, bits 4-0 low)
    wire bit5_high, bits_4_0_low;
    assign bit5_high = current[5];              // Bit 5 is high
    assign bits_4_0_low = ~(|current[4:0]);     // Bits 4-0 are all low
    and done_gate(done, bit5_high, bits_4_0_low);

endmodule