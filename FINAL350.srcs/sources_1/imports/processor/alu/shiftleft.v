module shiftleft(data, amount, data_out); 
    input [31:0] data; 
    input [4:0] amount; 
    output [31:0] data_out; 

    wire [31:0] stage0, stage1, stage2, stage3, stage4; 

    //shift 1
    wire[31:0] shiftedstage0 = {data[30:0], 1'b0}; 
    mux_2 #(32) stage0mux(.out(stage0), .select(amount[0]), .in0(data), .in1(shiftedstage0)); 


    //shift 2

    wire[31:0] shiftedstage1 = {stage0[29:0], 2'b0}; 
    mux_2 #(32) stage1mux(.out(stage1), .select(amount[1]), .in0(stage0), .in1(shiftedstage1)); 


    //shift 4

    wire[31:0] shiftedstage2 = {stage1[27:0], 4'b0}; 
    mux_2 #(32) stage2mux(.out(stage2), .select(amount[2]), .in0(stage1), .in1(shiftedstage2)); 


    //shift 8

    wire[31:0] shiftedstage3 = {stage2[23:0], 8'b0}; 
    mux_2 #(32) stage3mux(.out(stage3), .select(amount[3]), .in0(stage2), .in1(shiftedstage3)); 


    //shift 16

    wire[31:0] shiftedstage4 = {stage3[15:0], 16'b0}; 
    mux_2 #(32) stage4mux(.out(stage4), .select(amount[4]), .in0(stage3), .in1(shiftedstage4)); 




    assign data_out = stage4; 

endmodule