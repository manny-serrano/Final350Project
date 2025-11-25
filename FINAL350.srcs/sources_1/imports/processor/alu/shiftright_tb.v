`timescale 1ns / 100ps

module shiftright_tb;
    reg [31:0] data;
    reg [4:0] amount;
    wire [31:0] data_out;
    
    shiftright shiftrightt(.data(data), .amount(amount), .data_out(data_out));
    
    initial begin
        // No shift
        data = 32'b10000000000000000000000000000000;
        amount = 5'b00000;
        #10;
        $display("Shift %b by %d = %b", data, amount, data_out);
        
        // Shift by 1
        data = 32'b10000000000000000000000000000000;
        amount = 5'b00001;
        #10;
        $display("Shift %b by %d = %b", data, amount, data_out);
        
        // Shift 4
        data = 32'b10000000000000000000000000000000;
        amount = 5'b00100;
        #10;
        $display("Shift %b by %d = %b", data, amount, data_out);
        
        // Shift by 8
        data = 32'b10000000000000000000000000000000;
        amount = 5'b01000;
        #10;
        $display("Shift %b by %d = %b", data, amount, data_out);
        
        $finish;
    end
endmodule