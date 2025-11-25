module register_32_tb;


    reg clock;
    reg reset; 
    reg enable; 
    reg [31:0] data_in; 
    wire [31:0] data_out; 

    register_32 initt(.clock(clock), .reset(reset), .enable(enable), .data_in(data_in), .data_out(data_out)); 


    always #5 clock = ~clock; 

    initial begin 
        clock = 0; reset =1; enable =0; data_in =0; 
        #10; 
        $display("Reset: %h (compare to 00000000)", data_out); 

        reset = 0; enable =1; data_in = 32'h12345678; 

        #10;

        $display("Test: %h (should be 12345678)", data_out); 

        enable = 0; data_in = 32'hDEADBEEF; 
        #10; 
        $display("Enable off: %h (should be 12345678)", data_out); 

        enable =1; data_in = 32'hABCD1234; 
        #10; 
        $display("Enable on, write: %h (should be ABCD1234)", data_out); 

        $finish; 
    end

endmodule
