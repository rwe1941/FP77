!cpu 6502
!to "fp77_demo.prg",cbm

	*= $0801

	!byte $00,$08,$95,$07,$9e
	!text "2061"
	!byte 0,0,0

!source "../FP77_Official_MACRODEFINITIONS.asm"

ptr = $fb

VAL_A_MAN = $e0   ; -3.5
VAL_A_EXP = $c2
VAL_B_MAN = $90   ; 2.25
VAL_B_EXP = $42

	; Required by FP77 add/mul/div/sqrt routines.
	+generateMultTables
	+generateAddTables

	; ADD: A + B
	lda #<msgAdd
	ldy #>msgAdd
	jsr printString
	+loadFixedTo VAL_A_MAN, VAL_A_EXP, A_MANTISSA
	jsr printFp77
	lda #' '
	jsr $ffd2
	lda #'+'
	jsr $ffd2
	+loadFixedTo VAL_B_MAN, VAL_B_EXP, A_MANTISSA
	jsr printFp77
	lda #'='
	jsr $ffd2
	lda #' '
	jsr $ffd2

	+loadFixedTo VAL_A_MAN, VAL_A_EXP, A_MANTISSA
	+loadFixedTo VAL_B_MAN, VAL_B_EXP, B_MANTISSA
	
	jsr addition
	jsr printFp77
	jsr printCR

	; SUB: B - A
	lda #<msgSub
	ldy #>msgSub
	jsr printString
	+loadFixedTo VAL_A_MAN, VAL_A_EXP, A_MANTISSA
	jsr printFp77
	lda #' '
	jsr $ffd2
	lda #'-'
	jsr $ffd2
	+loadFixedTo VAL_B_MAN, VAL_B_EXP, A_MANTISSA
	jsr printFp77
	lda #'='
	jsr $ffd2
	lda #' '
	jsr $ffd2

	+loadFixedTo VAL_B_MAN, VAL_B_EXP, B_MANTISSA
	+loadFixedTo VAL_A_MAN, VAL_A_EXP, A_MANTISSA
	jsr subtraction
	jsr printFp77
	jsr printCR

	; MUL: A * B
	lda #<msgMul
	ldy #>msgMul
	jsr printString
	+loadFixedTo VAL_A_MAN, VAL_A_EXP, A_MANTISSA
	jsr printFp77
	lda #' '
	jsr $ffd2
	lda #'*'
	jsr $ffd2
	+loadFixedTo VAL_B_MAN, VAL_B_EXP, A_MANTISSA
	jsr printFp77
	lda #'='
	jsr $ffd2
	lda #' '
	jsr $ffd2

	+loadFixedTo VAL_A_MAN, VAL_A_EXP, A_MANTISSA
	+loadFixedTo VAL_B_MAN, VAL_B_EXP, B_MANTISSA
	jsr Multiply
	jsr printFp77
	jsr printCR

	; DIV: C / A
	lda #<msgDiv
	ldy #>msgDiv
	jsr printString
	+loadFixedTo VAL_A_MAN, VAL_A_EXP, A_MANTISSA
	jsr printFp77
	lda #' '
	jsr $ffd2
	lda #'/'
	jsr $ffd2
	+loadFixedTo VAL_B_MAN, VAL_B_EXP, A_MANTISSA
	jsr printFp77
	lda #'='
	jsr $ffd2
	lda #' '
	jsr $ffd2

	+loadFixedTo VAL_A_MAN, VAL_A_EXP, A_MANTISSA
	+loadFixedTo VAL_B_MAN, VAL_B_EXP, B_MANTISSA
	jsr Divide
	jsr printFp77
	jsr printCR

	; SQRT: sqrt(C)
	lda #<msgSqrt
	ldy #>msgSqrt
	jsr printString
	lda #<msgSqrtExpr
	ldy #>msgSqrtExpr
	jsr printString
	+loadFixedTo VAL_B_MAN, VAL_B_EXP, A_MANTISSA
	jsr printFp77
	jsr $ffd2
	lda #')'
	jsr $ffd2
	lda #'='
	jsr $ffd2
	lda #' '
	jsr $ffd2

	+loadFixedTo VAL_B_MAN, VAL_B_EXP, A_MANTISSA
	jsr SqRoot
	jsr printFp77
	jsr printCR

	; SQR: A^2
	lda #<msgSqr
	ldy #>msgSqr
	jsr printString
	+loadFixedTo VAL_A_MAN, VAL_A_EXP, A_MANTISSA
	jsr printFp77
	lda #'^'
	jsr $ffd2
	lda #'2'
	jsr $ffd2
	lda #' '
	jsr $ffd2
	lda #' '
	jsr $ffd2
	lda #' '
	jsr $ffd2
	lda #' '
	jsr $ffd2
	lda #' '
	jsr $ffd2
	lda #'='
	jsr $ffd2

	+loadFixedTo VAL_A_MAN, VAL_A_EXP, A_MANTISSA
	jsr Square
	jsr printFp77
	jsr printCR
	jsr printCR
	jsr printCR

	lda #<msgDivResult
	ldy #>msgDivResult
	jsr printString
	jsr printCR

	rts

printFp77
	jsr convertFP77_TO_FAC
	jmp PrintFACToScreen


printString
	sta ptr
	sty ptr+1
	ldy #0
.loop
	lda (ptr),y
	beq .done
	jsr $ffd2
	iny
	bne .loop
	inc ptr+1
	bne .loop
.done
	rts

printHex
	pha
	lsr
	lsr
	lsr
	lsr
	jsr printNibble
	pla
	and #$0f
printNibble
	ora #$30
	cmp #$3a
	bcc +
	adc #$06
+   
    jsr $ffd2
	rts

printCR
	lda #$0d
	jmp $ffd2

msgAdd  !text "ADD  : ",0
msgSub  !text "SUB  : ",0
msgMul  !text "MUL  : ",0
msgDiv  !text "DIV  : ",0
msgSqrt !text "SQRT : ",0
msgSqr  !text "SQR  : ",0
msgSqrtExpr !text "SQRT(",0
msgDivResult !text "THE RESULT OF THE DIVISION IS NOT PRECISE. SHOULD BE -1.555555556 ",0

!source "../FP77_Official.asm"
