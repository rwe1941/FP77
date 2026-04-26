; calculates a Mandelbrot Set and displays it in bitmap mode with 4 colors. The code is optimized for speed and uses fixed-point arithmetic.
!cpu 6502
!to "mandelbrot.prg",cbm

        *= $0801

        !byte $1E,$08,$95,$07,$9E
        !text "2080 RADWAR ENTERPRISES"
        !byte $00,$00,$00

!source "../FP77_Official_MACRODEFINITIONS.asm"

GETPARA_Z = $34 ;$35 Pointer GetPara
GETPARA_ZCNT = $36 ; Zýhler GetPara
MEMCOPY_FROMLO=$02
MEMCOPY_FROMHI=$03
MEMCOPY_TOLO=$04
MEMCOPY_TOHI=$05
MEMCOPY_LENLO=$06
MEMCOPY_LENHI=$07
MEMFILL_LO=$02
MEMFILL_HI=$03
MEMFILL_LENLO=$04
MEMFILL_LENHI=$05
MEMFILL_DATA=$06

xscr = $70
yscr = $71
iter = $72
xMan=  $73
xExp = $74
yMan=  $75
yExp = $76

z_real_Man=  $77
z_real_Exp = $78
z_img_Man=  $79
z_img_Exp = $7a

x2Man=  $7b
x2Exp = $7c
y2Man=  $7d
y2Exp = $7e

pixelByte= $7f

pMan=  $80
pExp = $81
qMan=  $82
qExp = $83

plot2HiresBitMap_loc =$fc
plot2HiresBitMap_GFX_MEM = $6000

MAX_ITERATIONS = 12


main

        sei
        lda #$35
        sta $01

        ;bitmap vic mem to $4000-$7fff
        lda $dd00
        and #$fc
        ora #$02
        sta $dd00

        inc $d020
        JSR MEMCOPY
        !byte .END4-*,MEMCOPY_FROMLO
        !word d000InitTab
        !word $d000
        !word $2f
.END4

     ; clear Bitmap
        JSR MEMFILL
        !byte .END3-*,MEMFILL_LO
        !word plot2HiresBitMap_GFX_MEM
        !word 8000
        !byte 0
.END3

    ; clear Bitmap Color 1
        JSR MEMFILL
        !byte .END3a-*,MEMFILL_LO
        !word $5c00
        !word 1000
        !byte $e6
.END3a

    ; clear Color 3
        JSR MEMFILL
        !byte .END3c-*,MEMFILL_LO
        !word $d800
        !word 1000
        !byte $03
.END3c

        jsr GeneratePlotTables
        +generateMultTables
        +generateAddTables

; ---- calculate Mandelbrot Set

        lda #0
        sta pixelByte

        lda #0
        sta yscr
        +loadFixedTo $c0, $c1, yMan

yLoop
        lda #0
        sta xscr
        +loadFixedTo $80, $c2, xMan

xLoop
        lda #0
        sta iter
        +move xMan, z_real_Man
        +move yMan, z_img_Man

iterloop
        +loadToA z_real_Man
        jsr Square  ;x^2
        +storeTo x2Man
        +storeToB

        +loadToA z_img_Man
        jsr Square ;y^2
        +storeTo y2Man
        +storeToA

        jsr addition ; x^2+y^2 < 4
        cpx #$43 ; 4 has exponent $43
        bcc +
        jmp escaped
+
        +loadToA x2Man      ;z_real^2 - z_imag^2 + c_real
        +loadToB y2Man
        jsr subtraction
        +storeToA

        +loadToB xMan
        jsr addition
        +storeTo x2Man ;temp

        lda z_real_Man        ;2 * z_real * z_imag + c_imag
        ldx z_real_Exp
        inx ; *2
        +storeToA

        +loadToB z_img_Man
        jsr Multiply
        +storeToA

        +loadToB yMan
        jsr addition
        +storeTo z_img_Man

        +move x2Man, z_real_Man

         inc iter
         lda iter
         cmp #MAX_ITERATIONS
         bcs escaped
         jmp iterloop

escaped

        lda iter
        ror
        rol pixelByte
        ror
        rol pixelByte

        lda xscr
        and #3
        CMP #3
        bne nopaintescaped

        lda xscr
        ASL
        tax
        lda pixelByte
        ldy yscr
        clc
        jsr plot2HiresBitMapByte

        sec
        lda #127
        sbc yscr
        tay
        lda xscr
        ASL
        tax
        lda pixelByte
        clc
        jsr plot2HiresBitMapByte

        lda #0
        sta pixelByte
nopaintescaped

        +loadToA xMan
        +loadFixedTo $c1, 60, B_MANTISSA ; 0,03125*2
        jsr addition
        +storeTo xMan

        inc xscr
        bit xscr
        bvs +
        jmp xLoop
+
        +loadToA yMan
        +loadFixedTo $c0, 59, B_MANTISSA ; 0,03125
        jsr addition
        +storeTo yMan

        inc yscr
        bit yscr ;check for 64
        bvs end
        jmp yLoop

end
-       jmp -

!source "../Fragments/GETPARA.asm"
!source "../Fragments/MEMCPY.asm"
!source "../Fragments/MEMFILL.asm"
!source "../Fragments/PLOTHIRESPIXEL.asm"

        !align 255,0

plot2HiresBitMap_xtable:
        !fill 256,0
plot2HiresBitMap_ytablehigh:
        !fill 256,0
plot2HiresBitMap_ytablelow:
        !fill 256,0
plot2HiresBitMap_bitmask:
        !fill 256,0

d000InitTab
        !byte 0,0 ;Sprite 0 : x,y
        !byte 0,0 ;Sprite 1 : x,y
        !byte 0,0 ;Sprite 2 : x,y
        !byte 0,0 ;Sprite 3 : x,y
        !byte 0,0 ;Sprite 4 : x,y
        !byte 0,0 ;Sprite 5 : x,y
        !byte 0,0 ;Sprite 6 : x,y
        !byte 0,0 ;Sprite 7 : x,y
        !byte 0       ;Sprite X 9th Bit  ; Sprite 6 & 7 !
        !byte $3b     ;$d011 |RST8| ECM| BMM| DEN|RSEL|    YSCROLL
        !byte 0       ;$d012 Raster counter
        !byte 0       ;lightpenX
        !byte 0       ;lightpenY
        !byte 0       ;Sprite enabled
        !byte $18     ; $d016 |  - |  - | RES| MCM|CSEL|    XSCROLL
        !byte 0       ; Sprite Y expansion
        !byte $78     ; $d018 |VM13|VM12|VM11|VM10|CB13|CB12|CB11|  - | Memory pointers
        !byte 0       ; $d019 | IRQ|  - |  - |  - | ILP|IMMC|IMBC|IRST| Interrupt register
        !byte 0       ; $d01a |  - |  - |  - |  - | ELP|EMMC|EMBC|ERST| Interrupt enabled
        !byte 0       ; $d01b |M7DP|M6DP|M5DP|M4DP|M3DP|M2DP|M1DP|M0DP| Sprite data priority
        !byte 0       ; $d01c |M7MC|M6MC|M5MC|M4MC|M3MC|M2MC|M1MC|M0MC| Sprite multicolor
        !byte 0       ; $d01d |M7XE|M6XE|M5XE|M4XE|M3XE|M2XE|M1XE|M0XE| Sprite X expansion
        !byte 0       ; $d01e | M7M| M6M| M5M| M4M| M3M| M2M| M1M| M0M| Sprite-sprite collision
        !byte 0       ; $d01f | M7D| M6D| M5D| M4D| M3D| M2D| M1D| M0D| Sprite-data collision
        !byte 0       ; $d020 |  - |  - |  - |  - |         EC        | Border color
        !byte 0       ; $d021 |  - |  - |  - |  - |        B0C        | Background color 0
        !byte 0       ; $d022 |  - |  - |  - |  - |        B1C        | Background color 1
        !byte 0       ; $d023 |  - |  - |  - |  - |        B2C        | Background color 2
        !byte 0       ; $d024 |  - |  - |  - |  - |        B3C        | Background color 3
        !byte 0       ; $d025 |  - |  - |  - |  - |        MM0        | Sprite multicolor 0
        !byte 0       ; $d026 |  - |  - |  - |  - |        MM1        | Sprite multicolor 1
        !byte 0       ; $d027 |  - |  - |  - |  - |        M0C        | Color sprite 0

!source "../FP77_Official.asm"
