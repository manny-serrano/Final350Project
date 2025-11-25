module booth_mux_tb; 

    reg [32:0] M; 
    reg [3:0] control; 
    wire add_1x, add_2x, sub_1x, sub_2x; 
    wire [32:0] selected; 
    wire is_subtract; 

    assign add_1x = control[3];
    assign add_2x = control[2];
    assign sub_1x = control[1];
    assign sub_2x = control[0]; 

    integer i; 

    booth_mux checking(.M(M), .add_1x(add_1x), .add_2x(add_2x), .sub_1x(sub_1x), .sub_2x(sub_2x),
    .selected(selected), .is_subtract(is_subtract)); 

    initial begin
        M = 33'd5; 

        $display("Testing booth_mux with M=5"); 
        $display("control | selected | is_sub"); 

        for (i=0; i<5; i=i+1) begin
            case (i)
                0: control = 4'b0000; 
                1: control = 4'b1000; 
                2: control = 4'b0100; 
                3: control = 4'b0010; 
                4: control = 4'b0001; 
            endcase
            #10; 
            $display("%b      |  %d     | %b", control, $signed(selected), is_subtract); 
        end

        $finish;
    end 

endmodule



