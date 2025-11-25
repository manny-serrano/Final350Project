module control_fsm(input clock, start, counter_done, output active, ready); 

    // single bit state: if 0=idle, 1=computing

    wire current_state, nextstate; 


    //logic for next state, start computing or continue until finished
    wire continue; 
    and continuegate(continue, current_state, ~counter_done); 
    or nextstategate(nextstate, start, continue); 

    // one register for state
    dffe_ref state_ff(.q(current_state), .d(nextstate), .clk(clock), .en(1'b1), .clr(1'b0)); 

    assign active = current_state; 

    // ready, which means active last cycle then counter done now

    wire previousactive; 
    dffe_ref prev_ff(.q(previousactive), .d(current_state), .clk(clock), .en(1'b1), .clr(1'b0)); 

    and readygate(ready, previousactive, counter_done); 


endmodule