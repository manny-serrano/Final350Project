module counter_tb;
    reg clock, enable, reset;
    wire [4:0] count;
    wire done;
    integer i;
    
    counter checking(.clock(clock), .enable(enable), .reset(reset),
                     .count(count), .done(done));
    
    initial clock = 0;
    always #10 clock = ~clock;
    
    initial begin
        $display("count | done");
        
        reset = 1; enable = 0;
        #20;
        
        reset = 0; enable = 1;
        
        for (i = 0; i < 20; i = i + 1) begin
            #20;
            $display("%d     | %b", count, done);
        end
        
        $finish;
    end
endmodule