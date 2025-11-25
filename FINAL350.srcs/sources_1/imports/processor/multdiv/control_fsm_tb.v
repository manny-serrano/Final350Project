module control_fsm_tb;
    reg clock, start, counter_done;
    wire active, ready;
    integer i;
    
    control_fsm check(.clock(clock), .start(start), 
                     .counter_done(counter_done),
                     .active(active), .ready(ready));
    
    initial clock = 0;
    always #10 clock = ~clock;
    
    initial begin
        $display("time | start | done | active | ready");
        start = 0; counter_done = 0;
        
        for (i = 0; i < 25; i = i + 1) begin
            if (i == 2) start = 1;  // Start at cycle 2
            if (i == 3) start = 0;  // Pulse for 1 cycle
            if (i == 18) counter_done = 1;  // Done at cycle 18
            
            #20;
            $display("%4d | %b     | %b    | %b      | %b", 
                     i*20, start, counter_done, active, ready);
        end
        
        $finish;
    end
endmodule

