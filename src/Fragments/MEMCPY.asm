          
         ;---------------------------------------
        ;MEMCOPY EXAMPLE
        ; COPIES $1000 BYTES FROM $D000 TO
        ; $2000 AND TEMPORARILY SWITCHES $01
        ; JSR MEMCOPY
        ; !byte END-*,$01
        ; !byte $33
        ; !word $D000
        ; !word $2000
        ; !word $1000
        ;END
        ;18.2 BUG: COULD NOT COPY LENGTHS <$100
        ; FIXED (yyy) => MAXLEN $80FF !
        ; DESTROYS:
        ; A X Y

;MEMCOPY_FROMLO=$02
;MEMCOPY_FROMHI=$03
;MEMCOPY_TOLO=$04
;MEMCOPY_TOHI=$05
;MEMCOPY_LENLO=$06
;MEMCOPY_LENHI=$07

MEMCOPY ;LDA 1
        ;STA SAVE1
        JSR GETP

        LDY # $00
-
        LDA (MEMCOPY_FROMLO),Y
        STA (MEMCOPY_TOLO),Y
        INY
        BNE +
        INC MEMCOPY_FROMHI
        INC MEMCOPY_TOHI
+
        DEC MEMCOPY_LENLO
        BNE -
        DEC MEMCOPY_LENHI
        BPL -
        ;LDA SAVE1
        ;STA 1
        RTS

