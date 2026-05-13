# FP77 - 2-Byte Floating-Point Library for 6502

## Overview

Radwar Enterprises 1941 proudly presents FP77, a compact and efficient floating-point arithmetic library for 6502 assembly language. 
FP77 provides a complete set of math operations using a custom 2-byte floating-point format providing low-precision, high-performance math operations for the Commodore 64 and other 6502-based systems.

## Key Features

- **Compact Format**: 2 bytes per number (vs 5 bytes in C64 BASIC ROM)
- **Complete Math Library**: Addition, subtraction, multiplication, division, square root, squaring
- **Bonus Operations**: 16-bit integer conversion, number comparison, conversion to/from FAC format
- **Lookup Table Optimization**: Pre-computed tables for multiplication and square root

## FP77 Format

FP77 numbers are stored in 2 bytes:

```
Byte 1: Mantissa   (7-bit normalized, MSB always 1)
Byte 2: Exponent + Sign (7-bit exponent with bias $41, sign in MSB)
```

**Example Values:**

||Mantissa|Exponent|
|---|---|---|
|`1.5`            |$c0|$41|
|`2.25`           |$90|$42|
|`9.0`            |$90|$44|
|`-3.5`           |$e0|$c2|
|`0`              |$00|$00|
|`'PI' ~ 3,140625`|$49|$42|


## Supported Operations

### Arithmetic
- **Addition** (`jsr addition`) - Add two FP77 numbers
- **Subtraction** (`jsr subtraction`) - Subtract two FP77 numbers
- **Multiplication** (`jsr Multiply`) - Multiply two FP77 numbers
- **Division** - (`jsr Divide`) - Divide two FP77 numbers (multiply with 1/x)
- **Square** (`jsr Square`) - Square a number: result = x²
- **Square Root** (`jsr SqRoot`) - Square root with table lookup

### Utility Operations
- **Compare** (`jsr compare`) - Compare two FP77 numbers (sets carry/zero flags)
- **16-bit Int Conversion** 
  - (`jsr convert_int16to_float`) - Convert signed 16-bit integer to FP77
  - (`jsr convert_float_to_int16`) - Convert FP77 to signed 16-bit integer
- **FAC Conversion** 
  - (`jsr convertFP77_TO_FAC`) Convert FP77 to C64 BASIC 5-byte FAC format
  - (`jsr convertFAC_TO_FP77`) Convert C64 BASIC 5-byte FAC format to FP77

## Usage

### Basic Macro Usage

Load a fixed value into memory:
```asm
+loadFixedTo 0xc0, 0x41, $18    ; Load 1.5 at $18/$19
```

Load a 2-byte value from memory into register pair:
```asm
+loadToA $18                    ; Load from $18/$19 into A_MANTISSA/A_EXPONENT
+loadToB $1a                    ; Load from $1a/$1b into B_MANTISSA/B_EXPONENT
```

Store result back to memory:
```asm
+storeToA $20                   ; Store A (mantissa/exponent) to $20/$21
```

### Performing Operations

Addition example:
```asm
+loadFixedTo 0xc0, 0x41, A_MANTISSA    ; Load 1.5 into A
+loadFixedTo 0x90, 0x42, B_MANTISSA    ; Load 2.25 into B
jsr addition                           ; A = A + B
```

Multiplication example:
```asm
+loadFixedTo 0xc0, 0x41, A_MANTISSA    ; Load 1.5 into A
+loadFixedTo 0x90, 0x42, B_MANTISSA    ; Load 2.25 into B
jsr Multiply                           ; A = A * B
```

Square/Square Root example:
```asm
+loadFixedTo 0x90, 0x44, A_MANTISSA    ; Load 9.0 into A
jsr SqRoot                             ; A => sqrt(A) = 3.0
jsr Square                             ; A => A² = 9.0
```

### Register Layout

**Math Registers (Zero Page):**
- `A_MANTISSA = $12` - Input/output mantissa for operand A
- `A_EXPONENT = $13` - Input/output exponent for operand A
- `B_MANTISSA = $14` - Input/output mantissa for operand B
- `B_EXPONENT = $15` - Input/output exponent for operand B

**FAC (5-byte) Registers (used for BASIC ROM operations):**
- `$61`     - Exponent
- `$62-$65` - Mantissa bytes
- `$66`     - Sign

## File Structure

```
FP77_Official_MACRODEFINITIONS.asm     - Macro helpers and constants
FP77_Official.asm                      - Routine implementations
Example/fp77_demo.asm                  - Side-by-side demo (5-byte vs 2-byte)
Example/mandelbrot.as                  - calculates the Mandelbrot Set
Fragments/                             - Support routines
```

## Assembly Instructions

Requires **ACME Cross Assembler**:

```bash
acme "fp77_demo.asm"   # Assemble demo program
acme "mandelbrot.asm"  # Assemble Mandelbrot
```

## Technical References

**FP77 Format Details:**
- Mantissa: 7-bit normalized (implicit leading 1)
  - values from $80 to $ff represent mantissas from 1.0 to 1.9921875; $00 represents zero 
- Exponent: 7-bit with bias 0x41 (65) and 1 Sign Bit
  - Sign Bit: MSB of exponent byte; 0 = positive, 1 = negative
  - Exponent Range: -65 to +62 (after bias)
- Range: ±0.00000000000000000002732 to ±9187343239835810000
- Precision: ~5 significant decimal digits
- All integer from 0 to 256 are available
- the largest value (9187343239835810000) is considered "infinity" 

The [XLS-file fp77.xls](fp77.xls) provides an overview of all possible numbers.

## Integration Example

Drop FP77 into existing 6502 projects:

```asm
!source "FP77_Official_MACRODEFINITIONS.asm"
!source "FP77_Official.asm"

my_program:
    +generateMultTables           ; Initialize lookup tables (once at startup)
    +generateAddTables
    
    ...
    
    ; Your code using FP77 macros and subroutines...
    +loadFixedTo $c0, $41, A_MANTISSA
    jsr SqRoot
```

## Notes

- Initialize lookup tables once at program start with `+generateMultTables` and `+generateAddTables`
- Results are always returned in the A register pair (A_MANTISSA/A_EXPONENT)
- operations preserve operand B intact (safe for intermediate calculations)
- Flags (carry, zero) may be modified; save if needed for control flow

## License & Attribution

This software is released into public domain under the [Unlicense](LICENSE).

FP77 floating-point library for 6502 systems designed for space-critical and speed-critical demos.

If you are even thinking about using this code in anything "serious" (navigation, health care, nuclear power plants, space probes etc.) you should not develop software at all!
