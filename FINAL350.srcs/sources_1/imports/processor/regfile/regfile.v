module regfile (
	clock,
	ctrl_writeEnable, ctrl_reset, ctrl_writeReg,
	ctrl_readRegA, ctrl_readRegB, data_writeReg,
	data_readRegA, data_readRegB
);

	input clock, ctrl_writeEnable, ctrl_reset;
	input [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
	input [31:0] data_writeReg;

	output [31:0] data_readRegA, data_readRegB;

	// add your code here

	wire [31:0] register_out [31:0]; 

	wire [31:0] write_enable; 

	decoder_5 write(.enable(ctrl_writeEnable), .select(ctrl_writeReg), .out(write_enable));

	genvar i; 
	generate 
		for(i=0; i<32; i=i+1) begin: registers
			if (i==0) begin

				assign register_out[i] = 32'b0;
			end else begin
				register_32 reg_in(.clock(clock), .reset(ctrl_reset), .enable(write_enable[i]), .data_in(data_writeReg), 
				.data_out(register_out[i])); 
			end
		end

	endgenerate

	wire [31:0] muxa, muxb; 

	mux_32 #(32) read_a(.out(muxa), .select(ctrl_readRegA), .in0(register_out[0]), .in1(register_out[1]), .in2(register_out[2]), .in3(register_out[3]), 
	.in4(register_out[4]), .in5(register_out[5]), .in6(register_out[6]), .in7(register_out[7]), .in8(register_out[8]), 
	.in9(register_out[9]), .in10(register_out[10]), .in11(register_out[11]), .in12(register_out[12]), .in13(register_out[13]), 
	.in14(register_out[14]), .in15(register_out[15]), .in16(register_out[16]), .in17(register_out[17]), .in18(register_out[18]), 
	.in19(register_out[19]), .in20(register_out[20]), .in21(register_out[21]), .in22(register_out[22]), .in23(register_out[23]), 
	.in24(register_out[24]), .in25(register_out[25]), .in26(register_out[26]), .in27(register_out[27]), .in28(register_out[28]), 
	.in29(register_out[29]), .in30(register_out[30]), .in31(register_out[31])); 


	mux_32 #(32) read_b(.out(muxb), .select(ctrl_readRegB), .in0(register_out[0]), .in1(register_out[1]), .in2(register_out[2]), .in3(register_out[3]), 
	.in4(register_out[4]), .in5(register_out[5]), .in6(register_out[6]), .in7(register_out[7]), .in8(register_out[8]), 
	.in9(register_out[9]), .in10(register_out[10]), .in11(register_out[11]), .in12(register_out[12]), .in13(register_out[13]), 
	.in14(register_out[14]), .in15(register_out[15]), .in16(register_out[16]), .in17(register_out[17]), .in18(register_out[18]), 
	.in19(register_out[19]), .in20(register_out[20]), .in21(register_out[21]), .in22(register_out[22]), .in23(register_out[23]), 
	.in24(register_out[24]), .in25(register_out[25]), .in26(register_out[26]), .in27(register_out[27]), .in28(register_out[28]), 
	.in29(register_out[29]), .in30(register_out[30]), .in31(register_out[31])); 

	tristate_buffer buffer_a(.in(muxa), .enable(1'b1), .out(data_readRegA)); 

	tristate_buffer buffer_b(.in(muxb), .enable(1'b1), .out(data_readRegB)); 

endmodule




