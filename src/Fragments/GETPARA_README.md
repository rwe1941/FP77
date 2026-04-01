# GETPARA Routine

## Purpose

`GETP` (in `GETPARA.asm`) reads inline parameters placed directly after a `JSR` call and copies them into a zero-page parameter block.

This is a compact 6502 pattern for passing arguments to subroutines without hardcoding addresses and have large lda/sta sequences.
```asm
lda #<source_addr
sta MEMCOPY_FROMLO
lda #>source_addr
sta MEMCOPY_FROMHI
lda #<target_addr
sta MEMCOPY_TOLO
lda #>target_addr
sta MEMCOPY_TOHI
lda #<length
sta MEMCOPY_LENLO
lda #>length
sta MEMCOPY_LENHI

jsr MEMCOPY
...
```

## What It Does

1. Reads the caller return address from the stack.
2. Treats the bytes after `JSR` as a parameter block.
3. Copies parameter bytes into zero page.
4. Adjusts the return address so `RTS` skips over the inline parameter bytes.

## Parameter Block Format

Bytes directly after `JSR` must be:

```asm
!byte END-*, <zp_target>
!byte <param0>
!byte <param1>
...
END
```

Meaning:

- Byte 0: `END-*` = total byte count from this byte up to (but not including) label `END`
- Byte 1: `<zp_target>` = destination zero-page start address
- Byte 2..N: payload bytes to copy into zero page

The payload starts at `<zp_target>` and is written sequentially.

The first instruction of the called function must be `JSR GETP`

## Required Zero-Page Scratch

`GETP` uses these symbols (must be defined by the caller):

- `GETPARA_Z` (2 bytes): temporary pointer
- `GETPARA_ZCNT` (1 byte): byte count/end marker

Example from this project:

```asm
GETPARA_Z = $34
GETPARA_ZCNT = $36
```

## Register/State Effects

- Destroys: `A`, `X`, `Y`
- Processor flags are modified
- Caller should preserve any needed registers before `JSR GETP`

## Typical Usage

### Example 1: For MEMCOPY

```asm
JSR MEMCOPY
!byte END-*, MEMCOPY_FROMLO
!word source_addr
!word target_addr
!word length
END
```

This copies 6 payload bytes into:

- `MEMCOPY_FROMLO..MEMCOPY_FROMHI`
- `MEMCOPY_TOLO..MEMCOPY_TOHI`
- `MEMCOPY_LENLO..MEMCOPY_LENHI`

### Example 2: For MEMFILL

```asm
JSR MEMFILL
!byte END-*, MEMFILL_LO
!word target_addr
!word length
!byte fill_value
END
```

This copies 5 payload bytes into:

- `MEMFILL_LO..MEMFILL_HI`
- `MEMFILL_LENLO..MEMFILL_LENHI`
- `MEMFILL_DATA`

## Notes
- The first byte must match the actual block size (`END-*`).
- If the size is wrong, return-address adjustment will jump to the wrong location.
