# Regfile
## Emmanuel Serrano Campa

## Description of Design

This register file supports 2 read ports and 1 write port with 32 registers of 32 bits each. I implemented a modular design using structural Verilog with the following key components:

**Storage**: 32 registers built from D flip-flops (using provided `dffe_ref.v`). Register 0 is hardwired to always output zero regardless of write attempts.

**Write Logic**: A 5-to-32 decoder (`decoder_5.v`) converts the 5-bit write address into 32 write enable signals using the allowed decoder syntax `assign out = enable << select`.

**Read Logic**: Two identical 32-to-1 multiplexers (reusing my `mux_32` hierarchy from checkpoint 1) select register outputs for each read port. Tristate buffers are added at the outputs to satisfy the specification requirement.


## **Module Hierarchy**:
- `regfile.v` - Top-level module with required interface
- `decoder_5.v` - 5-to-32 address decoder 
- `register_32bit.v` - 32-bit register using generate loop of `dffe_ref` instances
- `tristate_buffer_32.v` - 32-bit tristate buffer for read port requirement
- `mux_32.v`, `mux_8.v`, `mux_4.v`, `mux_2.v` - Multiplexer hierarchy from checkpoint 1
- `dffe_ref.v` - Provided D flip-flop with enable


**Key Implementation Details**:
- Used generate loops for creating 32 registers and 32-bit wide tristate buffers
- Register 0 special case handled with `if (i == 0)` condition in generate block
- All code follows structural Verilog constraints (no behavioral constructs, bitwise operators, or case statements)
- Reused proven multiplexer modules from previous checkpoint

## Testing

Created comprehensive test cases in `edge_cases_exp.csv` covering:
- Register 0 behavior (always reads 0)
- Reset functionality 
- Write enable control
- Boundary registers (0, 1, 30, 31)
- Simultaneous read operations
- Maximum value handling (0xFFFFFFFF)

All tests pass successfully.

## Bugs
No current bugs, the status of this regfile is excellent. 

