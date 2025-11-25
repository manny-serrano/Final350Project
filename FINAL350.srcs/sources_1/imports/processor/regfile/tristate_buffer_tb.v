module tristate_buffer_32_tb;

    reg [31:0] in;
    reg enable;
    wire [31:0] out;
    
    tristate_buffer_32 uut(.in(in), .enable(enable), .out(out));
    
    initial begin
        in = 32'h12345678;
        
        enable = 1;
        #1;
        $display("Enable on: %h", out);
        
        enable = 0;
        #1;
        $display("Enable off: %h", out);
        
        $finish;
    end

endmodule