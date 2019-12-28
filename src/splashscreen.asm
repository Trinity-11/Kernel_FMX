


SPLASHSCREEN_MAIN
        setaxl
        LDA #$0000
        LDX #$0000
        LDY #$0000
        setaxs

        LDA #$10    ; Set the Color of the Graphic Mode Color with a Dark Grey
        STA @lBACKGROUND_COLOR_B
        STA @lBACKGROUND_COLOR_G
        STA @lBACKGROUND_COLOR_R
        LDA #$01    ; Enable Border
        STA @lBORDER_CTRL_RER
        ;Set The Color of the Border with the Foenix Purple
        LDA #$20
        STA @lBORDER_COLOR_B
        STA @lBORDER_COLOR_R
        LDA #$00
        STA @lBORDER_COLOR_G
        ;
        LDA #$Mstr_Ctrl_Disable_Vid ; Turn Off Video Access for 100% Memory Bandwidth
        STA @lMASTER_CTRL_REG_L
        JSR CLEAR_BM_MEMORY   ; Go Clear the Bitmap Region $B0:0000
        JSR SET_BITMAP_MODE_PARAMETERS ;
        JSR SET_GRAPHIC_MODE

        RTL

SET_GRAPHIC_MODE
        LDA @lMASTER_CTRL_REG_L
        AND #$~Mstr_Ctrl_Text_Mode_En ; Disable the Text Mode
        ORA #$ (Mstr_Ctrl_Graph_Mode_En | Mstr_Ctrl_Bitmap_En | Mstr_Ctrl_TileMap_En | Mstr_Ctrl_Sprite_En) ; Enabling Graphic Mode, BM, Tile & Sprites
        STA @lMASTER_CTRL_REG_L
        RTS

SET_BITMAP_MODE_PARAMETERS
        LDA #$01                    ; Enable the BitMap and Set LUT0
        STA @lBM_CONTROL_REG
        ; Set the Start Address of the bitmap @ $B0:0000 (CPU Pointer) == $00:0000 (VICKY Pointer)
        LDA #$00
        STA @lBM_START_ADDY_L
        STA @lBM_START_ADDY_M
        STA @lBM_START_ADDY_H       ; All the Pointer in VICKY pointing to Video memory are always from $00:0000 beginning of the 4Meg VideoRAM
        RTS

CLEAR_BM_MEMORY
        setal
        LDA #640
        STA BM_CLEAR_SCRN_X
        LDA #480
        STA BM_CLEAR_SCRN_Y
        LDA #$C000
        STA BMP_PRSE_DST_PTR
        LDA #$00B0
        STA BMP_PRSE_DST_PTR+2
        JSL IBM_FILL_SCREEN
        setaxs
        RTS
