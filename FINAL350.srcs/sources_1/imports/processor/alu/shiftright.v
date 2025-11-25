module shiftright(data, amount, data_out);
    input [31:0] data;
    input [4:0] amount;
    output [31:0] data_out;
    
    wire [31:0] stage0, stage1, stage2, stage3, stage4;
    wire sign;
    
    assign sign = data[31];  
    
    // Shift by 1
    wire [31:0] shiftedstage0 = {sign, data[31:1]};
    mux_2 #(32) stage0mux(.out(stage0), .select(amount[0]), .in0(data), .in1(shiftedstage0));
    
    // Shift by 2
    wire [31:0] shiftedstage1 = {{2{sign}}, stage0[31:2]};
    mux_2 #(32) stage1mux(.out(stage1), .select(amount[1]), .in0(stage0), .in1(shiftedstage1));
    
    // Shift by 4
    wire [31:0] shiftedstage2 = {{4{sign}}, stage1[31:4]};
    mux_2 #(32) stage2mux(.out(stage2), .select(amount[2]), .in0(stage1), .in1(shiftedstage2));
    
    // Shift by 8
    wire [31:0] shiftedstage3 = {{8{sign}}, stage2[31:8]};
    mux_2 #(32) stage3mux(.out(stage3), .select(amount[3]), .in0(stage2), .in1(shiftedstage3));
    
    // Shift by 16
    wire [31:0] shiftedstage4 = {{16{sign}}, stage3[31:16]};
    mux_2 #(32) stage4mux(.out(stage4), .select(amount[4]), .in0(stage3), .in1(shiftedstage4));
    
    assign data_out = stage4;

endmodule