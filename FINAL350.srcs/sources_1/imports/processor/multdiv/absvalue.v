module absvalue(
    input [31:0] in,
    output [31:0] out
);
    wire [31:0] negated;
    wire unused_cout, unused_ovf;
    
    cla32bit negate(
        .A(~in),
        .B(32'b0),
        .Cin(1'b1),
        .S(negated),
        .Cout(unused_cout),
        .Overflow(unused_ovf)
    );
    
    assign out = in[31] ? negated : in;
endmodule