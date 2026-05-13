

; ------------------
; converts a 16-bit integer (X/A) in the range -32767 to 32767 to FLOAT
; Input:
;   16-bit integer in the range -32767 to 32767
;   X/A: LO/HI bytes of the value

; Output:
;   A_Mantisssa: 7-bit mantissa (MSB always 1)
;   A_Exponent: 7-bit exponent (bias 64)
;  return $8000 if Overflow Error
; destroy: A, X, Y

; integers from 128-255 have the mantissa 128-255
; so we shift the integer up (<128) or down (>255) to fit into that range and adapt the exponent accordingly

convert_int16to_float
    sta TEMP2
    stx TEMP1
    cpx #0
    bne +
    stx A_EXPONENT
    stx A_MANTISSA
    RTS

+   cmp #$7f
    bcc isPositive
    ldy #72+128
    SEC
    LDA #0
    SBC TEMP1
    STA TEMP1
    LDA #0
    SBC TEMP2
    STA TEMP2
    !byte $2c ; bit $a048
isPositive
    ldy #72

    sty A_EXPONENT
    lda TEMP2
    beq lessthan256
-
    lsr TEMP2
    ror TEMP1
    inc A_EXPONENT
    lda TEMP2
    bne -
    beq +

lessthan256
-
    lda TEMP1
    bmi +
    asl TEMP1
    dec A_EXPONENT
    bne -
+
    lda TEMP1
    sta A_MANTISSA
    rts



; ------------------
; converts a Float to a 16-bit integer (X/A) in the range -32767 to 32767
; Input:
;   A_Mantisssa: 7-bit mantissa (MSB always 1)
;   A_Exponent: 7-bit exponent (bias 64)

; Output:
;   16-bit integer in the range -32767 to 32767
;   X/A: LO/HI bytes of the result
;   returns $8000 if Overflow Error
; destroy: A, X, Y


convert_float_to_int16
    LDA A_EXPONENT
    AND #$7F            ; Extract 6-bit exponent (bits 0-5)
    cmp #80             ; Check if exponent is too large
    bcs overflow
    sec
    sbc #floatBias
    bmi isZero
    tax
    lda A_MANTISSA
    beq isZero
    ldy #0
    sty TEMP1
    sty TEMP2
-
    asl
    rol TEMP1
    rol TEMP2
    dex
    bpl -

    bit A_EXPONENT
    bmi negative
    ; Positive:
    ldx TEMP1
    lda TEMP2
    rts
negative:
    ; Negate the 16-bit result
    LDA  TEMP1
    EOR #$FF
    CLC
    ADC #1
    tax
    LDA TEMP2
    EOR #$FF
    ADC #0
    rts

overflow
    LDX #$00
    LDA #$80
    RTS


PrintFACToScreen
    ;convert number in FAC1 to ASCII (pointer in A & Y)
    JSR $BDDD
    LDY #$00
PrintLoop
    LDA $0100,Y
    BEQ +
    JSR $FFD2
    INY
    bne PrintLoop
+
    RTS

        ; ------------------
        ; Converts a 5-byte FAC float to a 2-byte FP7.7 float
        ; OUT: A mantissa
        ;      X Exponent + Sign
        ; DESTROYS:
        ; A X
convertFAC_TO_FP77
       LDA FAC1SGN ; make sure FAC1SGN is $00 or $80
       AND #$80
       STA FAC1SGN

       LDA FAC1EXP
       SEC
       sbc #$40
       BCC isZero
       BPL +

isInfinity
       LDA FAC1SGN
       EOR #$7F
       TAX
       LDA #$ff
       RTS
+      ORA FAC1SGN
       TAX
       LDA FAC1M1    ; get the mantissa
       ora#$80       ; set the leading 1
       RTS
isZero
       LDA #0
       TAX
       RTS


       ; ------------------
       ; Converts a 2-byte FP7.7 float to a 5-byte FAC float
       ; IN: A mantissa
       ;     X Exponent + Sign
       ; DESTROYS:
       ; A

convertFP77_TO_FAC
       STA FAC1M1
       LDA #$00
       STA FAC1M2
       STA FAC1M3
       STA FAC1M4
       TXA
       CLC
       ADC FAC1M1
       BEQ +; isZero
       TXA
       AND #$80
       STA FAC1SGN
       TXA
       AND #$7F
       CLC
       ADC #$40
       STA FAC1EXP
       RTS
+
       LDA #0
       STA FAC1EXP
       STA FAC1M1
       STA FAC1M2
       STA FAC1M3
       STA FAC1M4
       STA FAC1SGN
       RTS



        ; ------------------
        ; Compares the value in A with the value in B
        ; IN:
        ; OUT z=0 when A = B
        ;     c=1 when A >= B
        ;     c=0 when A < B
        ; DESTROYS:
        ; A Y


compare:
    ;Sign compare
    LDY A_EXPONENT
    TYA
    EOR B_EXPONENT
    BPL equalSign

    TYA ;A_EXPONENT
    EOR #$80 ; Invert signs
    asl; 0 = A > B, 1 = A < B
    RTS

equalSign
    TYA ;A_EXPONENT
    BMI negativeNumbers
+
    ;Exponent compare
    CMP B_EXPONENT
    BNE +
    ; Mantissa compare
    LDA A_MANTISSA
    cmp B_MANTISSA
+
    RTS

negativeNumbers
    ;Exponent compare
    LDA B_EXPONENT
    CMP A_EXPONENT
    BNE +
    ; Mantissa compare
    LDA B_MANTISSA
    cmp A_MANTISSA
+
    RTS



    ; ------------------
    ; Subtracts the value in B from the value in A
    ; IN:
    ; OUT A mantissa
    ;     X Exponent + Sign
    ; DESTROYS:
    ; A X Y

subtraction:
    ;  a - b: negate B
    LDA B_EXPONENT
    EOR #$80
    STA B_EXPONENT

    ; ------------------
    ; Adds the value in B to the value in A
    ; IN:
    ; OUT A mantissa
    ;     X Exponent + Sign
    ; DESTROYS:
    ; A X Y

addition:
    LDA A_EXPONENT
    EOR B_EXPONENT
    BMI handleSub  ; a - b or -a + b
    SEC
    LDA A_EXPONENT
    SBC B_EXPONENT

    BPL aexp_ge_bexp
    ; B > A => shift A
    cmp #$f9
    bcc resIsB ; shifting results is 0 => B is result

    ;sawp a and b
    ldx A_MANTISSA
    ldy B_MANTISSA
    sty A_MANTISSA
    stx B_MANTISSA

    ldx A_EXPONENT
    ldy B_EXPONENT
    sty A_EXPONENT
    stx B_EXPONENT
    bcs + ; carry still set
aexp_ge_bexp
    ; A >= B => shift B
    cmp #$08
    bcs resIsA ; shifting results is 0 => A is result
+
    LDX A_EXPONENT
    tay
    lda shiftTab,Y
    sta shiftingA+2
    ldy B_MANTISSA
shiftingA
    lda shiftTabsAdr,Y
    clc
    adc A_MANTISSA
    bcc +
normalize
    ror
    tay
    inx ;inc A_EXPONENT
+
    rts
resIsA
    lda A_MANTISSA
    ldx A_EXPONENT
    RTS
resIsB
    lda B_MANTISSA
    ldx B_EXPONENT
    RTS

handleSub
    SEC
    LDA A_EXPONENT
    EOR #$80  ; align signs
    SBC B_EXPONENT
    bne +
    ldx A_MANTISSA
    cpx B_MANTISSA
    bcs aexp_ge_bexp2
    bcc bexp_gt_aexp2
+
    BPL aexp_ge_bexp2

    ; B > A => shift A
    cmp #$f9
    bcc resIsB ; shifting results is 0 => B is result
bexp_gt_aexp2
    LDX B_EXPONENT

    tay
    lda shiftTab,Y
    sta shiftingA2+2
    ldy A_MANTISSA
    sec
    LDA B_MANTISSA
shiftingA2
    SBC shiftTabsAdr,Y
    beq resIsZero
    bcs normalizeFromRight
normalizeFromLeft
    sec
    bcs normalize

aexp_ge_bexp2
    ; A >= B => shift B
    cmp #$08
    bcs resIsA ; shifting results is 0 => A is result

    LDX A_EXPONENT
    tay
    lda shiftTab,Y
    sta shiftingB2+2
    ldy B_MANTISSA
    sec
    LDA A_MANTISSA
shiftingB2
    sbc shiftTabsAdr,Y
    beq resIsZero
    bcc normalizeFromLeft

normalizeFromRight
    bmi +
-   cpx #$80
    beq resIsZero
    cpx #$00
    beq resIsZero
    dex
    asl
    bpl -
+
    rts

resIsZero
    LDA #0
    TAX
    RTS


; ------------------
; Divide the number in A by B
; (or better multiply a by 1/B, where 1/B is looked up in a table)
; IN:
; OUT A Mantissa
;     X Exponent + Sign
; DESTROYS:
; A X Y

Divide:
  ldy B_MANTISSA
  lda DivExponent,Y
  sec
  sbc B_EXPONENT
  adc #floatBias
  sta B_EXPONENT
  lda DivMantissa,Y
  sta B_MANTISSA


; ------------------
; Multiplies the numbers in A and B
; IN:
; OUT A Mantissa
;     X Exponent + Sign
; DESTROYS:
; A X Y

Multiply:
    ; store sign ins RES_EXPONENT
    LDA A_EXPONENT
    EOR B_EXPONENT
    AND #$80
    sta RES_EXPONENT

    LDA A_EXPONENT
    AND #$7f
    sta RES_MANTISSA ; temp only

    CLC
    LDA B_EXPONENT
    AND #$7f
    ADC RES_MANTISSA ; temp only
    bcs resIsInfinity
    cmp #floatBias
    bcc resIsZero
    cmp #floatBias+$7f
    bcs resIsInfinity

    SEC
    SBC #floatBias-1 ;force +1, if we need to mormalize, we decrease the exponent
    ora RES_EXPONENT
    sta RES_EXPONENT

    LDY A_MANTISSA
    beq resIsZero
    LDa B_MANTISSA
    beq resIsZero

    clc
    ADC A_MANTISSA
    TAX ; a+b

    LDA B_MANTISSA
    sec
    SBC A_MANTISSA
    tay ; a-b, don't care if negative, the table is symetric

    ;(A + B)^2 - (A - B)^2
    sec
    lda sqAddLo,X
    sbc sqSubLo,Y
    sta RES_MANTISSA
    lda sqAddHi,X
    ldx RES_EXPONENT ; can be done here, we don't need a+b anymore
    sbc sqSubHi,Y

    ;if the smallest result $80 * $80 = $4000 then shift left once, otherwise its normalized
    bmi +
    dex
    asl RES_MANTISSA
    rol
+   rts

resIsPosInfinity
    LDX #$7F
    lda #$ff
    RTS
resIsInfinity
    lda RES_EXPONENT
    ORA #$7F
    tax
    lda #$ff
    RTS

; ------------------
; Squares the numbers in A
; IN:
; OUT A Mantissa
;     X Exponent + Sign
; DESTROYS:
; A X Y

Square:
    LDA A_MANTISSA
    bne +
    jmp resIsZero
+   asl
    tay

    LDA A_EXPONENT
    asl
    cmp #floatBias
    bcs +
    jmp resIsZero
+   cmp #floatBias+$7f
    bcs resIsPosInfinity

    SEC
    SBC #floatBias-1 ;force +1, if we need to normalize, we decrease the exponent
    tax

    lda sqAddHi,y

     ;if the smallest result $80 * $80 = $4000 then shift left once, otherwise its normalized
     bmi +
     sta RES_MANTISSA
     lda sqAddLo,y
     dex
     asl
     rol RES_MANTISSA
     lda RES_MANTISSA
+    rts

; ------------------
; Calculates the square root of the number in A using a lookup table for the mantissa and adjusting the exponent accordingly
; IN:
; OUT A Mantissa
;     X Exponent + Sign
; DESTROYS:
; A X Y

SqRoot:
    LDA A_EXPONENT
    bmi resIsPosInfinity
    bne +
    jmp resIsZero
+
    sec
    SBC #floatBias
    beq +
    tax
    ; invert the carry bit
    BCC CarryIsClear
    CLC        ; If Carry was set (1), clear it (0)
CarryIsClear = *+1
    bit $38   ; Skip the SEC ; If Carry was clear (0), set it (1)
    txa
    ror
+
    clc
    adc #floatBias
    and #$7f ; force positive result
    tax
    lsr A_EXPONENT
    bcc .continue ; if floatbias is even, we need to use bne here
    lda A_MANTISSA
    and #$7f ; lower half of table
    tay
.continue =*+1
    bit A_MANTISSA*256 + $a4 ;  => ldy A_MANTISSA
+
    lda SquareRoot,Y
    rts


!align 255,0
DivMantissa
!fill 128,128
    !byte 128,254, 252, 250, 248, 246, 244, 242, 240, 239, 237, 235, 234, 232, 230, 229, 227, 225, 224, 222, 221, 219, 218, 217, 215, 214, 212, 211, 210, 208, 207, 206, 204, 203, 202, 201, 199, 198, 197, 196, 195, 193, 192, 191, 190, 189, 188, 187, 186, 185, 184, 183, 182, 181, 180, 179, 178, 177, 176, 175, 174, 173, 172, 171, 170, 169, 168, 168, 167, 166, 165, 164, 163, 163, 162, 161, 160, 159, 159, 158, 157, 156, 156, 155, 154, 153, 153, 152, 151, 151, 150, 149, 148, 148, 147, 146, 146, 145, 144, 144, 143, 143, 142, 141, 141, 140, 140, 139, 138, 138, 137, 137, 136, 135, 135, 134, 134, 133, 133, 132, 132, 131, 131, 130, 130, 129, 129, 128

DivExponent
!fill 128,65
    !byte 65, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64

SquareRoot
; 1 - 1,9921875000
    !byte 128, 128, 129, 129, 130, 130, 131, 131, 132, 132, 133, 133, 134, 134, 135, 135, 136, 136, 137, 137, 138, 138, 139, 139, 139, 140, 140, 141, 141, 142, 142, 143, 143, 144, 144, 144, 145, 145, 146, 146, 147, 147, 147, 148, 148, 149, 149, 150, 150, 150, 151, 151, 152, 152, 153, 153, 153, 154, 154, 155, 155, 155, 156, 156, 157, 157, 157, 158, 158, 159, 159, 160, 160, 160, 161, 161, 161, 162, 162, 163, 163, 163, 164, 164, 165, 165, 165, 166, 166, 167, 167, 167, 168, 168, 168, 169, 169, 170, 170, 170, 171, 171, 171, 172, 172, 173, 173, 173, 174, 174, 174, 175, 175, 176, 176, 176, 177, 177, 177, 178, 178, 178, 179, 179, 179, 180, 180, 181
; 2- 3,9843750000
    !byte 181, 182, 183, 183, 184, 185, 185, 186, 187, 187, 188, 189, 189, 190, 191, 192, 192, 193, 193, 194, 195, 195, 196, 197, 197, 198, 199, 199, 200, 201, 201, 202, 203, 203, 204, 204, 205, 206, 206, 207, 208, 208, 209, 209, 210, 211, 211, 212, 212, 213, 214, 214, 215, 215, 216, 217, 217, 218, 218, 219, 219, 220, 221, 221, 222, 222, 223, 224, 224, 225, 225, 226, 226, 227, 227, 228, 229, 229, 230, 230, 231, 231, 232, 232, 233, 234, 234, 235, 235, 236, 236, 237, 237, 238, 238, 239, 240, 240, 241, 241, 242, 242, 243, 243, 244, 244, 245, 245, 246, 246, 247, 247, 248, 248, 249, 249, 250, 250, 251, 251, 252, 252, 253, 253, 254, 254, 255, 255

shiftTab
        !byte       0+shiftTabsAdrHi,1+shiftTabsAdrHi,2+shiftTabsAdrHi,3+shiftTabsAdrHi,4+shiftTabsAdrHi,5+shiftTabsAdrHi,6+shiftTabsAdrHi,7+shiftTabsAdrHi
        !byte       8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte 	    8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte     	8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi,8+shiftTabsAdrHi
        !byte		8+shiftTabsAdrHi,7+shiftTabsAdrHi,6+shiftTabsAdrHi,5+shiftTabsAdrHi,4+shiftTabsAdrHi,3+shiftTabsAdrHi,2+shiftTabsAdrHi,1+shiftTabsAdrHi
        !align 255,0
sqAddLo
!fill 256,0
sqAddHi
!fill 256,0
sqSubLo
!fill 256,0
sqSubHi
!fill 256,0

shiftTabsAdr
shiftTabsAdrHi = >shiftTabsAdr
!fill 8*256,0
