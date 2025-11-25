module alu(data_operandA, data_operandB, ctrl_ALUopcode, ctrl_shiftamt, data_result, isNotEqual, isLessThan, overflow);
        
    input [31:0] data_operandA, data_operandB;
    input [4:0] ctrl_ALUopcode, ctrl_shiftamt;

    output [31:0] data_result;
    output isNotEqual, isLessThan, overflow;

    // add your code here

    wire [31:0] add_result, sub_result, and_result, or_result, sll_result, sra_result; 
    wire a_overflow, sub_overflow; 

     wire [31:0] bnot;

    // ADDITION

    cla32bit adder(.A(data_operandA), .B(data_operandB), .Cin(1'b0), .S(add_result), .Overflow(a_overflow));

    // Subtraction: (A - B = A + (~B) + 1)

    genvar i; 
    generate
        for(i=0; i<32; i=i+1) begin : notb 

            not bnott(bnot[i], data_operandB[i]); 


        end
    endgenerate


    cla32bit subtractor(.A(data_operandA), .B(bnot), .Cin(1'b1), .S(sub_result), .Overflow(sub_overflow)); 

    // AND and OR   UNITS

    bitbybit_and bitwise_and(.A(data_operandA), .B(data_operandB), .result(and_result)); 

    bitwise_or bitor(.A(data_operandA), .B(data_operandB), .result(or_result)); 

    // Barrel shifts

    shiftleft sll(.data(data_operandA), .amount(ctrl_shiftamt), .data_out(sll_result)); 
    shiftright rsa(.data(data_operandA), .amount(ctrl_shiftamt), .data_out(sra_result)); 

    // ADD: 00000, SUBTRACT: 00001, AND: 00010, OR: 00011, SLL: 00100, SRA: 00101

    mux_32 #(32) resultmux(.out(data_result), .select(ctrl_ALUopcode), .in0(add_result), .in1(sub_result), .in2(and_result), .in3(or_result),
    .in4(sll_result), .in5(sra_result), .in6(32'b0), .in7(32'b0), .in8(32'b0), .in9(32'b0), .in10(32'b0), .in11(32'b0), 
    .in12(32'b0), .in13(32'b0), .in14(32'b0), .in15(32'b0), .in16(32'b0), .in17(32'b0), .in18(32'b0), .in19(32'b0), 
    .in20(32'b0), .in21(32'b0), .in22(32'b0), .in23(32'b0), .in24(32'b0), .in25(32'b0), .in26(32'b0), 
    .in27(32'b0), .in28(32'b0), .in29(32'b0), .in30(32'b0), .in31(32'b0));

    //isLessThan
    wire sub_resultnotted;
    not not_sub_result(sub_resultnotted, sub_result[31]);

    assign isLessThan = sub_overflow ? sub_resultnotted : sub_result[31]; 

    //isNotEqual (used generate loops)
    wire [15:0] or1;
    wire [7:0] or2; 
    wire [3:0] or3;
    wire [1:0] or4;     

    generate

        for (i=0; i<16; i=i+1) begin : tree1
            or gate1(or1[i], sub_result[2*i], sub_result[2*i+1] ); 

        end

    endgenerate


    generate

        for (i=0; i<8; i=i+1) begin : tree2
            or gate2(or2[i], or1[2*i], or1[2*i+1]); 

        end

    endgenerate


    generate

        for (i=0; i<4; i=i+1) begin : tree3
            or gate3(or3[i], or2[2*i], or2[2*i+1]); 

        end

    endgenerate


     generate

        for (i=0; i<2; i=i+1) begin : tree4
            or gate4(or4[i], or3[2*i], or3[2*i+1]); 

        end

    endgenerate


    or finalor(isNotEqual, or4[0], or4[1]);


    assign overflow = ctrl_ALUopcode[0] ? sub_overflow : a_overflow;



endmodule