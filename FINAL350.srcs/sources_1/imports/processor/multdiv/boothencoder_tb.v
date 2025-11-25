module boothencoder_tb;
    reg [2:0] bits;
    wire add_1x, add_2x, sub_1x, sub_2x;
    integer i;
    
    boothencoder checking(.booth_bits(bits), .add_1x(add_1x), .add_2x(add_2x), 
                     .sub_1x(sub_1x), .sub_2x(sub_2x));
    
    initial begin
        $display("bits | outputs");
        for (i = 0; i < 8; i = i + 1) begin
            bits = i;
            #10;
            $display(" %b  |  %b%b%b%b", bits, add_1x, add_2x, sub_1x, sub_2x);
        end
        $finish;
    end
endmodule
