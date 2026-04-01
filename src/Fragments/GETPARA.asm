        ;===============
        ;GETPARA
        ;COPIES THE VALUES AFTER THE JSR
        ;INTO THE SPECIFIED ZERO-PAGE ADDRESS
        ; DESTROYS:
        ; A X Y

GETP
        TSX
        LDY #$01
        LDA $0103,X
        STA GETPARA_Z
        LDA $0104,X
        STA GETPARA_Z+1
        LDA (GETPARA_Z),Y
        INY
        STA GETPARA_ZCNT
        CLC
        ADC GETPARA_Z
        STA $0103,X
        LDA GETPARA_Z+1
        ADC #$00
        STA $0104,X
        LDA (GETPARA_Z),Y
        TAX
-
        INY
        LDA (GETPARA_Z),Y
        STA $00,X
        INX
        CPY GETPARA_ZCNT
        BNE -
        RTS
