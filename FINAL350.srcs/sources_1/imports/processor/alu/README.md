# ALU
## Emmanuel Serrano Campa

## Description of Design

I implemented a 32-bit ALU supporting six operations: ADD, SUBTRACT, AND, OR, SLL (Shift Left Logical), and SRA (Shift Right Arithmetic). The design follows a modular hierarchical structure where each operation is implemented in separate modules and then combined using a 32-to-1 multiplexer. This is the first checkpoint of a larger final implementation of a CPU. 

The design strictly follows structural Verilog constraints, using only basic gates (AND, OR, NOT, XOR), generate loops, and assign statements.


### Organization
I implemented the alu first by creating the necessary modules for each instruction, which included the
* cla32bit adder (carried out by 4 (8bit cla))
* 32 bit barrel shiftleft 
* 32 bit shift right arithmetic,
* Bitwise AND 
* Bitwise OR

I chose to make these modules seperately because it provided more structure, and allowed abstraction for cleaner code and easier implementation. 


### The CLA (2-level)

Referencing the slides from lecture, I implemented a two-Level carry look-ahead adder (CLA) that was composed of 
four 8-bit CLA blocks connected hierarchically. 

Each 8-bit block generates group propagate (P_group) and group generate (G_group) signals

The 32-bit level uses these signals to compute carries between 8-bit blocks using fully expanded Boolean expressions
Supports both addition (A + B) and subtraction (A + ~B + 1) operations
Includes signed overflow detection using the logic. 

I decided on this and did not pursue further progress such as a CSA, because we covered this more in depth in class and thought it would be feasable. 



### Bitwise Logic Units (OR and AND)

Both modules use generate loops 
* 32-bit AND operation implemented bit-by-bit using individual AND gates
* 32-bit OR operation implemented bit-by-bit using individual OR gates

### Barrel Shifters
This **ALU** is composed of 2 Barrel shifters:

* **Left shift (SLL)**: 32-bit logical left shifter supporting shifts of 0-31 positions
* **Right shift (SRA)**: 32-bit arithmetic right shifter with sign extension for negative numbers

They both implement 5-stage barrel shifter architecture using a 5-stage binary-weighted barrel shifter architecture using concatenation operators for bit manipulation and 2-to-1 multiplexers at each stage, where each stage can shift by powers of 2 (1, 2, 4, 8, 16 bits) controlled by the corresponding bit of the 5-bit shift amount.

I used the [2:1] multiplexer we created in lab because it was ready to use and I implemented it in ECE250 for the CPU project in that course. 


### Final Control Logic (alu.v)

I implemented a 32-to-1 multiplexer that selects the appropriate operation result based on the 5-bit ALU opcode. 

This includes a 3 outputs (Information Signals) which are:

* **isNotEqual**: Uses a tree of OR gates to detect if subtraction result is non-zero
* **isLessThan**: Implements signed comparison with overflow handling using ternary logic
* **overflow**: Selects between addition and subtraction overflow signals based on operation type


## Bugs
Initial Overflow Detection Issue

Problem: The original CLA adder overflow detection was incorrect, causing failures in test cases 25 and 32 during addition testing.

Root Cause: The initial overflow logic only detected positive overflow (two positive numbers yielding a negative result) but missed negative overflow (two negative numbers yielding a positive result).

Solution: Implemented comprehensive signed overflow detection that checks both cases:

* Positive overflow: (A[31]==0) AND (B[31]==0) AND (S[31]==1)
* Negative overflow: (A[31]==1) AND (B[31]==1) AND (S[31]==0)
* Final overflow signal: OR of both conditions

### Testing Strategy
I created comprehensive test suites for each operation:
* `add_exp.csv`: Addition with overflow edge cases (provided)
* `sub_exp.csv`: Subtraction including signed overflow scenarios  
* `and_exp.csv`: Bitwise AND with various bit patterns
* `or_exp.csv`: Bitwise OR with complementary patterns
* `sll_exp.csv`: Left shifts across all shift amounts (0-31)
* `sra_exp.csv`: Arithmetic right shifts with sign extension verification

## Current Status
The ALU implementation is fully functional and passes all test cases for the six required operations. The design successfully handles edge cases including signed arithmetic overflow, zero operands, and maximum shift amounts while maintaining strict adherence to structural Verilog design constraints. 
