# MultDiv
## Emmanuel Serrano Campa 2025

## Description of Design
This repository implements a combined multiplication and division unit for 32-bit signed integers. The design uses a **Modified Booth multiplier** for efficient multiplication and a **restoring division algorithm** for division. 

### Architecture

The `multdiv` module does the following:
- Accepts control signals (`ctrl_MULT`, `ctrl_DIV`) to initiate operations
- Routes operands to the appropriate functional unit (multiplier or divider)
- Tracks which operation type is currently active using a registered flag
- Multiplexes outputs based on the active operation

### Booth_multiplier.v: Modified Booth Algorithm
I implemented a **Modified Booth Radix-4 multiplier** that processes 2 bits of the multiplier per iteration, requiring only 16 clock cycles for a 32-bit multiplication

This module is composed of:
1. **Input Latching**: Operands A and B are latched when `start` is asserted to ensure stable values throughout the computation, even if inputs change externally.

2. **66-bit Product Register**: Stores `{Accumulator[32:0], Q[32:0]}` where:
   - Upper 33 bits hold the partial product accumulator
   - Lower 33 bits hold the multiplier (Q) and shift through during computation
   - Sign-extended to 33 bits for proper signed arithmetic

3. **Booth Encoder**: Examines 3 bits `{Q[1], Q[0], Q[-1]}` to determine the operation

4. **33-bit CLA Adder**: Performs addition/subtraction of the selected Booth value with the accumulator.

5. **Arithmetic Right Shift**: After each add/subtract, the 66-bit product is shifted right by 2 bits with sign extension.

6. **Control FSM**: Two-state machine (IDLE/COMPUTING) that:
   - Transitions to COMPUTING when `start` is asserted
   - Remains in COMPUTING until counter reaches 16 iterations
   - Asserts `ready` for one cycle when operation completes

7. **5-bit Counter**: Counts from 1 to 16, asserting `done` when count reaches 16 (binary `10000`).

8. **Result Extraction**: The final 32-bit result is extracted from `product[32:1]` (the middle 32 bits of the 66-bit product).

9. **Overflow Detection**: Checks if bits `[65:33]` are all sign extensions of `result[31]`. Any mismatch indicates overflow.

### Division (divider.v)
I implemented a **restoring division algorithm** using a 64-bit combined register, requiring 32 clock cycles for a 32-bit division. 

This module is composed of:
1. **Absolute Value Conversion** (`absvalue` module): Converts signed inputs to unsigned by negating negative numbers using two's complement (`~in + 1`).

2. **64-bit Combined Register**: Stores `{Remainder[31:0], Quotient[31:0]}`:
   - Updated each cycle with the shifted and restored/subtracted values
   - Uses modular `register_64` built from existing `register_32` components

3. **Restoring Division Loop** (32 iterations):
   - **Shift left**: `Remainder = {Remainder[30:0], Quotient[31]}`, `Quotient = {Quotient[30:0], 0}`
   - **Trial subtraction**: `Remainder - |B|` using a 32-bit CLA
   - **Decision**: If carry-out = 1 (non-negative result), keep subtraction and set quotient LSB to 1; else restore and set LSB to 0

5. **32-bit CLA Subtractor**: Performs `A + ~B + 1` for each trial subtraction. The carry-out indicates success (no borrow = result ≥ 0).

6. **Control Logic**:
   - **6-bit counter**: Counts 32 iterations
   - **FSM**: Manages IDLE/ACTIVE states and asserts `ready` when done
   - **Enable logic**: Counter advances only when active and not done

7. **Result Sign Application**: After 32 iterations, the quotient is negated if `result_sign = 1`, otherwise output as-is.

8. **Exception Handling**: Divide-by-zero is detected by reduction NOR on B (`~(|B)`) and asserted immediately.

## Bugs
No known bugs as of now. 
