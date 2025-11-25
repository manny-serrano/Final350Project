module boothencoder(input [2:0] booth_bits, output add_1x, add_2x, sub_1x, sub_2x);

    wire b2, b1, b0; 
    assign b2 = booth_bits[2]; 
    assign b1 = booth_bits[1]; 
    assign b0 = booth_bits[0]; 


    wire notb2, notb1, notb0; 

    not b2not(notb2, b2);
    not b1not(notb1, b1); 
    not b0not(notb0, b0); 
    

    wire case_001, case_010, case_101, case_110; 
    // add_1x: 001, 010//

    and and_001(case_001, notb2, notb1, b0); 
    and and_010(case_010, notb2, b1, notb0); 
    or or_add1x(add_1x, case_001, case_010); 

    // add_2x: 011//
    and and_011(add_2x, notb2, b1, b0); 


    // sub1x//
    and and_101(case_101, b2, notb1, b0); 
    and and_110(case_110, b2, b1, notb0); 
    or or_sub1x(sub_1x, case_101, case_110); 

    // sub2x

    and and_100(sub_2x, b2, notb1, notb0); 


endmodule