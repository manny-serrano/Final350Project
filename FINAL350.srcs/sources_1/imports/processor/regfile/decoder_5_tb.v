module decoder_5_tb;

    reg enable;
    reg [4:0] select;
    wire [31:0] out;
    
    decoder_5 initt(.enable(enable), .select(select), .out(out));
    
    initial begin
        // Test enable off
        enable = 0; select = 5;
        #1;
        $display("Enable=0: %h (should be 00000000)", out);
        
        enable = 1;
        
        select = 0;
        #1;
        $display("Select=0: %h (should be 00000001)", out);
        
        select = 5;
        #1;
        $display("Select=5: %h (should be 00000020)", out);
        
        select = 31;
        #1;
        $display("Select=31: %h (should be 80000000)", out);
        
        $finish;
    end

endmodule