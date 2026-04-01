

        ;---------------------------------------
        ;MEMFILL BEISPIEL
        ; FUELLT $1000 BYTE VON $D000 mit 0
        ; JSR MEMFILL
        ; !byte END-*,$02
        ; !word $D000
        ; !word $1000
        ; !byte 0
        ;END
        ; IN:
        ; Akku: value to fill
        ; DESTROYS:
        ; A X Y
;MEMFILL_LO=$02
;MEMFILL_HI=$03
;MEMFILL_LENLO=$04
;MEMFILL_LENHI=$05
;MEMFILL_DATA=$06

MEMFILL 
        JSR GETP
        LDY #0
        LDX MEMFILL_LENLO
        LDA MEMFILL_DATA
-
        STA (MEMFILL_LO),Y
        INY
        BNE +
        INC MEMFILL_HI
+
        DEX
        BNE -
        DEC MEMFILL_LENHI
        BPL -

        RTS
        