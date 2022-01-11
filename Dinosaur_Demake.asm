    processor 6502     ;define processor as 6502

    ;include required files-------------------------------------
    include "vcs.h"
    include "macro.h"

    ;uninitialized segment for variables------------------------
    seg.u variables
    org $80

DinoXPos byte          ;dinosaur X position
DinoYPos byte          ;dinosaur Y position

    ;set constants----------------------------------------------
DINO_HEIGHT = 16

    seg code
    org $F000

reset:
    CLEAN_START

    ;initialize variables---------------------------------------
    lda #10
    sta DinoXPos

    ;start main display loop------------------------------------
StartFrame:
    lda #2              ;start VSYNC and VBLANK
    sta VSYNC
    sta VBLANK

    ;generate 3 lines of VSYNC----------------------------------
    REPEAT 3
        sta WSYNC
    REPEND
    lda #0
    sta VSYNC           ;turn off VSYNC

    ;set horizontal position while in VBLANK-------------------
    lda DinoXPos        ;load A with desired X position
    and #$7F            ;force bit 8 off to make a UINT
    sta WSYNC           ;wait for a new scanline
    sta HMCLR           ;clear any previous positioning
    jsr SetHorizontalPosition

    ;generate 35 lines of VBLANK-------------------------------
    REPEAT 35
        sta WSYNC
    REPEND
    lda #0
    sta VBLANK          ;turn off VBLANK

    ;clear TIA registers--------------------------------------
    lda #0
    sta PF0 
    sta PF1 
    sta PF2 
    sta GRP0 
    sta GRP1

    ;set background and playfield colours---------------------
    lda #$80           
    sta COLUBK         ;set background colour to blue
    lda #$C3
    sta COLUPF         ;set playfield colour to green

    ;Draw 192 visible scanlines-------------------------------
    REPEAT 160         ;wait 160 scanlines
        sta WSYNC
    REPEND

    ldy #DINO_HEIGHT   ;counter to draw dino sprite
DrawBitmap:
    lda DinoSprite,Y   ;load slice of sprite
    sta GRP0           ;set graphics for dino
    lda DinoColour,Y
    sta COLUP0         ;set colour for dino

    sta WSYNC          ;wait for a new scanline

    dey 
    bne DrawBitmap     ;repeat next scanline until finished

    lda #0
    sta GRP0           ;disable dino graphics

    lda #$FF           ;enable playfield
    sta PF0
    sta PF1
    sta PF2 

    REPEAT 17          ;wait remaining 17 scanlines
        sta WSYNC
    REPEND

    lda #0             ;disable playfield
    sta PF0 
    sta PF1
    sta PF2

    ;draw 30 lines of overscan-------------------------------
    lda #2
    sta VBLANK      ;enable VBLANK

    REPEAT 30
        sta WSYNC
    REPEND 

    lda #0
    sta VBLANK      ;turn off VBLANK

    ;Controls----------------------------------------------
DinoUp:
    lda #%00010000
    bit SWCHA
    bne DinoDown
    inc DinoXPos

DinoDown:
    lda #%00100000
    bit SWCHA
    bne DinoLeft
    dec DinoXPos

DinoLeft:
    lda #%01000000
    bit SWCHA
    bne DinoRight
    dec DinoXPos

DinoRight:
    lda #%10000000
    bit SWCHA
    bne NoInput
    inc DinoXPos

NoInput:
    ;Fallback if no input is detected

    ;loop to next frame-------------------------------------
    jmp StartFrame


    ;subroutine to set horizontal position------------------
SetHorizontalPosition subroutine
    sec             ;set carry flag
DivLoop:
    sbc #15         ;subtract 15 from A
    bcs DivLoop     ;loop while flag is still set

    eor #7          ;adjust remainder to a range of -8 to 7
    asl             ;shift left 4 bits
    asl
    asl
    asl
    sta HMP0        ;set fine position
    sta RESP0       ;set rough position
    sta WSYNC       ;wait for a new scanline
    sta HMOVE       ;apply new fine offset
    rts     





    ;---Graphics Data from PlayerPal 2600---

DinoSprite
    .byte #%00000000
    .byte #%00010100;$C8
    .byte #%00010100;$C8
    .byte #%00010100;$C8
    .byte #%00010100;$C8
    .byte #%01111100;$C8
    .byte #%01011100;$C8
    .byte #%01011100;$C8
    .byte #%11011100;$C8
    .byte #%10011100;$C8
    .byte #%10011100;$C8
    .byte #%00111111;$C8
    .byte #%00101110;$C8
    .byte #%00101111;$C8
    .byte #%00001101;$C8
    .byte #%00001111;$C8

DinoColour
    .byte #$00;
    .byte #$C8;
    .byte #$C8;
    .byte #$C8;
    .byte #$C8;
    .byte #$C8;
    .byte #$C8;
    .byte #$C8;
    .byte #$C8;
    .byte #$C8;
    .byte #$C8;
    .byte #$C8;
    .byte #$C8;
    .byte #$C8;
    .byte #$C8;
    .byte #$C8;

    ;end of ROM---------------------------------------------
    org $FFFC
    .word reset
    .word reset