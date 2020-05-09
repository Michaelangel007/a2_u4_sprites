; Ultima 4 Tilesheet for Apple ][
; by Michaelangel007
; Copyleft (C) 2020
;
; 1. Start AppleWin
; 2. Mount Ultima 4 disk
; 3. Boot game
; 4. At the main main press F7 to enter the debugger
; 5. At the debugger
;        bload "dump_sprites",100
;        r pc 100
;        bpx 173
;        g
;
; NOTE: If you are already playing the game you can set a breakpoint at $AC8:    BPX AC8
;       If you are at the main menu you can set a breakpoint at $6B0B: BPX 6B0B
;
; To assemble:
;     merlin32 . dump_sprites.s

TILE_COLS       EQU  16 ; Fullscreen = 280/14 = 20
TILE_ROWS       EQU   8 ; Fullscreen = 12

END_Y           EQU TILE_ROWS * 16      ; Max is 12 tiles * 16 px/tile = 192 px

zDst        EQU $B4     ; Re-use keyboard buffer!
zY          EQU $F2     ; scanline y counter

; Sprites are 14x16 px
; LC Bank1 = Sprite Odd  Columns (Left  half of tile)
; LC Bank2 = Sprite Even Columns (Right half of tile)
; $D000 = Sprite Scanline 0
; $D100 = Sprite Scanline 1
; $D200 = Sprite Scanline 2
; $D300 = Sprite Scanline 3
; $D400 = Sprite Scanline 4
; $D500 = Sprite Scanline 5
; $D600 = Sprite Scanline 6
; $D700 = Sprite Scanline 7
; $D800 = Sprite Scanline 8
; $D900 = Sprite Scanline 9
; $DA00 = Sprite Scanline A
; $DB00 = Sprite Scanline B
; $DC00 = Sprite Scanline C
; $DD00 = Sprite Scanline D
; $DE00 = Sprite Scanline E
; $DF00 = Sprite Scanline F
SPRITES     EQU $D000

HGR_Y_LO    EQU $E000
HGR_Y_HI    EQU $E0C0

LCBANK1     EQU $C08B
LCBANK2     EQU $C083

KEYBOARD    EQU $C000   ; Last key pressed
KEYSTROBE   EQU $C010   ; Acknowledge last key so we can read next one

                ORG $100    ; Yup, the stack! Hey, it wasn't being used ... :-)

DumpSprites
                LDX #0
                STX Glyph+1
DumpNextPage
                STX zY

NextScanLine
                LDA HGR_Y_LO,X
                STA zDst
                LDA HGR_Y_HI,X
                STA zDst+1

UpdateSource
                TXA
                AND #$0F
                ORA #>SPRITES
                STA GetEvenSprite+2
                STA GetOddSprite +2

Glyph           LDX #0              ; ***SELF-MODIDFIED***
                LDY #0              ; Add border byte on left side as ...
                TYA
                STA (zDst),Y        ; ... tile bits (colors) are designed to start in odd column!
                INY

CopyScanLine
GetEvenTile     BIT LCBANK1
GetEvenSprite   LDA SPRITES,X       ; ***SELF-MODIFIED***
                STA (zDst),Y
                INY

GetOddTile      BIT LCBANK2
GetOddSprite    LDA SPRITES,X       ; ***SELF-MODIFIED***
                STA (zDst),Y
                INY

                INX                 ; next glyph
                CPY #TILE_COLS*2    ; end of tiles for this scanline?
                BCC CopyScanLine
                JSR ClearEOL

                INC zY

                LDX zY
                CPX #END_Y          ; Done all tile scanlines?
                BEQ NextPage
                TXA
                AND #$0F            ; Done all 16 scanlines for this tile?
                BNE NextScanLine
                JSR NextGlyphRow
                BNE NextScanLine    ; Always

NextPage                            ; Clear rest of screen
                LDX zY
                CPX #192            ; Done all 192 scanlines?
                BEQ WaitInput
                JSR GetNextScanLine
                LDY #0
                JSR ClearEOL
                INC zY
                BNE NextPage        ; Always

WaitInput
                LDA KEYBOARD
                BPL WaitInput
                STA KEYSTROBE

                LDX #0              ; Reset y=0
                JSR NextGlyphRow    ; We skipped updating Glyphs += TILE_COLS 
                CMP #0
                BNE DumpNextPage
Done
                RTS

GetNextScanLine
                LDA HGR_Y_LO,X
                STA zDst
                LDA HGR_Y_HI,X
                STA zDst+1
                RTS

ClearEOL
                LDA #0              ; Add border byte on right side
ClearEOL2
                STA (zDst),Y
                INY
                CPY #40
                BCC ClearEOL2
                RTS

NextGlyphRow
                LDA Glyph+1
                CLC
                ADC #TILE_COLS
                STA Glyph+1
                RTS
