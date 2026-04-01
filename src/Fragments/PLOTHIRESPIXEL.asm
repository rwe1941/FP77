; --------------------
        ; plot to Hires Bitmap
        ; IN :
        ; x: x-coord
        ; carry: x-coord largeer than 256
        ; y: y-coord
        ; DESTROYS:
        ; A Y


plot2HiresBitMap

    lda plot2HiresBitMap_ytablehigh,y
    adc #$00      ; Adds Carry (256 pixels) to HiByte
    sta plot2HiresBitMap_loc+1
    lda plot2HiresBitMap_ytablelow,y
    sta plot2HiresBitMap_loc
    ldy plot2HiresBitMap_xtable,x
    lda plot2HiresBitMap_bitmask,x
    ora (plot2HiresBitMap_loc),y
    sta (plot2HiresBitMap_loc),y
    rts

plot2HiresBitMapByte
    sta byteSave
    lda plot2HiresBitMap_ytablehigh,y
    adc #$00      ; Adds Carry (256 pixels) to HiByte
    sta plot2HiresBitMap_loc+1
    lda plot2HiresBitMap_ytablelow,y
    sta plot2HiresBitMap_loc
    ldy plot2HiresBitMap_xtable,x
byteSave = *+1
    lda #0
    sta (plot2HiresBitMap_loc),y
    rts


GeneratePlotTables
ldx #$00
    lda #$80
Loop1:
    sta plot2HiresBitMap_bitmask,x
    lsr
    bne Skip1
    lda #$80
Skip1:
    tay
    txa
    and #%11111000
    sta plot2HiresBitMap_xtable,x
    tya
    inx
    bne Loop1

Loop200:
    ldy #$07
LoopY8:
    txa
    and #7
    clc
lo320:
    adc #0
    sta plot2HiresBitMap_ytablelow,x
GFXHi:
    lda #>plot2HiresBitMap_GFX_MEM
    sta plot2HiresBitMap_ytablehigh,x
    inx
    dey
    bpl LoopY8
    inc GFXHi+1
    ;clc
    lda lo320+1
    adc #$40
    sta lo320+1
    bcc Skip
    inc GFXHi+1
Skip:
    cpx #200
    bne Loop200


rts
;screenLo !byte 0,40,80,120,160,200,240,<280,<320,<360,<400,<440,<480,<520,<560,<600,<640,<680,<720,<760,<800,<840,<880,<920,<960
;screenHi !byte >0,>40,>80,>120,>160,>200,>240,>280,>320,>360,>400,>440,>480,>520,>560,>600,>640,>680,>720,>760,>800,>840,>880,>920,>960
