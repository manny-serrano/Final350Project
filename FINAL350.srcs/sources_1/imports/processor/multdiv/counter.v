module counter(input clock, enable, reset, output [4:0] count, output done); 

    wire [4:0] current, next; 
    wire [31:0] count_32, increment_32; 

    assign count_32 = {27'b0, current};

    wire unusedoverflow, unused_cout;

    cla32bit adder(.A(count_32), .B(32'b1), .Cin(1'b0), .S(increment_32), 
                   .Cout(unused_cout), .Overflow(unusedoverflow)); 

    assign next = reset ? 5'b0 : increment_32[4:0]; 

    // Enable when reset=1 OR (enable=1 AND reset=0)
    wire enable_no_reset, ff_enable;
    and gate1(enable_no_reset, enable, ~reset);
    or gate2(ff_enable, reset, enable_no_reset);

    genvar i; 
    generate 
        for(i=0; i<5; i=i+1) begin: counterffs
            dffe_ref ff(.q(current[i]), .d(next[i]), .clk(clock), .en(ff_enable), .clr(1'b0)); 
        end
    endgenerate

    assign count = current; 

    wire bit4_high, bits_3_0_low;
    assign bit4_high = current[4];              // Bit 4 is high
    assign bits_3_0_low = ~(|current[3:0]);    // Bits 3-0 are all low
    and done_gate(done, bit4_high, bits_3_0_low);

endmodule