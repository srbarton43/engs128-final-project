# Agent Guidelines for ENGS128 FFT VHDL Project

## Code Style Guidelines
- Use 4-space indentation for VHDL files
- Entity/Architecture pairs should be in the same file
- Use lowercase for VHDL keywords
- Signal names: snake_case, descriptive of purpose
- Constants: UPPER_SNAKE_CASE
- Include proper comments before entity declarations and processes
- Header comment for each file with author, date, and purpose
- Separate signal declarations by type (in, out, inout, internal)
- Use numeric_std for arithmetic operations

## Error Handling
- Use assertions for design validation
- Add timeout conditions for testbenches