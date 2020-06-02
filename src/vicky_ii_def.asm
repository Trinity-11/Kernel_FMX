;
; Internal VICKY Registers and Internal Memory Locations (LUTs)
;

MASTER_CTRL_REG_L	      = $AF0000
;Control Bits Fields
Mstr_Ctrl_Text_Mode_En  = $01       ; Enable the Text Mode
Mstr_Ctrl_Text_Overlay  = $02       ; Enable the Overlay of the text mode on top of Graphic Mode (the Background Color is ignored)
Mstr_Ctrl_Graph_Mode_En = $04       ; Enable the Graphic Mode
Mstr_Ctrl_Bitmap_En     = $08       ; Enable the Bitmap Module In Vicky
Mstr_Ctrl_TileMap_En    = $10       ; Enable the Tile Module in Vicky
Mstr_Ctrl_Sprite_En     = $20       ; Enable the Sprite Module in Vicky
Mstr_Ctrl_GAMMA_En      = $40       ; this Enable the GAMMA correction - The Analog and DVI have different color value, the GAMMA is great to correct the difference
Mstr_Ctrl_Disable_Vid   = $80       ; This will disable the Scanning of the Video hence giving 100% bandwith to the CPU

MASTER_CTRL_REG_H       = $AF0001
Mstr_Ctrl_Video_Mode0   = $01       ; 0 - 640x480 (Clock @ 25.175Mhz), 1 - 800x600 (Clock @ 40Mhz)
Mstr_Ctrl_Video_Mode1   = $02       ; 0 - No Pixel Doubling, 1- Pixel Doubling (Reduce the Pixel Resolution by 2)

; Reserved - TBD
VKY_RESERVED_00         = $AF0002
VKY_RESERVED_01         = $AF0003
Border_Ctrl_Enable      = $01
BORDER_CTRL_REG         = $AF0004 ; Bit[0] - Enable (1 by default)  Bit[4..6]: X Scroll Offset ( Will scroll Left) (Acceptable Value: 0..7)
BORDER_COLOR_B          = $AF0005
BORDER_COLOR_G          = $AF0006
BORDER_COLOR_R          = $AF0007
BORDER_X_SIZE           = $AF0008; X-  Values: 0 - 32 (Default: 32)
BORDER_Y_SIZE           = $AF0009; Y- Values 0 -32 (Default: 32)

BACKGROUND_COLOR_B      = $AF000D ; When in Graphic Mode, if a pixel is "0" then the Background pixel is chosen
BACKGROUND_COLOR_G      = $AF000E
BACKGROUND_COLOR_R      = $AF000F ;

VKY_TXT_CURSOR_CTRL_REG = $AF0010   ;[0]  Enable Text Mode
Vky_Cursor_Enable       = $01
Vky_Cursor_Flash_Rate0  = $02
Vky_Cursor_Flash_Rate1  = $04
Vky_Cursor_FONT_Page0   = $08       ; Pick Font Page 0 or Font Page 1
Vky_Cursor_FONT_Page1   = $10       ; Pick Font Page 0 or Font Page 1
VKY_TXT_START_ADD_PTR   = $AF0011   ; This is an offset to change the Starting address of the Text Mode Buffer (in x)
VKY_TXT_CURSOR_CHAR_REG = $AF0012

VKY_TXT_CURSOR_COLR_REG = $AF0013
VKY_TXT_CURSOR_X_REG_L  = $AF0014
VKY_TXT_CURSOR_X_REG_H  = $AF0015
VKY_TXT_CURSOR_Y_REG_L  = $AF0016
VKY_TXT_CURSOR_Y_REG_H  = $AF0017


; Line Interrupt Registers
VKY_LINE_IRQ_CTRL_REG   = $AF001B ;[0] - Enable Line 0, [1] -Enable Line 1
VKY_LINE0_CMP_VALUE_LO  = $AF001C ;Write Only [7:0]
VKY_LINE0_CMP_VALUE_HI  = $AF001D ;Write Only [3:0]
VKY_LINE1_CMP_VALUE_LO  = $AF001E ;Write Only [7:0]
VKY_LINE1_CMP_VALUE_HI  = $AF001F ;Write Only [3:0]

; When you Read the Register
VKY_INFO_CHIP_NUM_L     = $AF001C
VKY_INFO_CHIP_NUM_H     = $AF001D
VKY_INFO_CHIP_VER_L     = $AF001E
VKY_INFO_CHIP_VER_H     = $AF001F

;

SPRITE_Enable             = $01
SPRITE_LUT0               = $02 ; This is the LUT that the Sprite will use
SPRITE_LUT1               = $04
SPRITE_LUT2               = $08 ; Only 4 LUT for Now, So this bit is not used.
SPRITE_DEPTH0             = $10 ; This is the Layer the Sprite will be Displayed in
SPRITE_DEPTH1             = $20
SPRITE_DEPTH2             = $40

; Sprite 0 (Highest Priority)
SP00_CONTROL_REG        = $AF0200
SP00_ADDY_PTR_L         = $AF0201
SP00_ADDY_PTR_M         = $AF0202
SP00_ADDY_PTR_H         = $AF0203
SP00_X_POS_L            = $AF0204
SP00_X_POS_H            = $AF0205
SP00_Y_POS_L            = $AF0206
SP00_Y_POS_H            = $AF0207
; Sprite 1
SP01_CONTROL_REG        = $AF0208
SP01_ADDY_PTR_L         = $AF0209
SP01_ADDY_PTR_M         = $AF020A
SP01_ADDY_PTR_H         = $AF020B
SP01_X_POS_L            = $AF020C
SP01_X_POS_H            = $AF020D
SP01_Y_POS_L            = $AF020E
SP01_Y_POS_H            = $AF020F

; Sprite 2
SP02_CONTROL_REG        = $AF0210
SP02_ADDY_PTR_L         = $AF0211
SP02_ADDY_PTR_M         = $AF0212
SP02_ADDY_PTR_H         = $AF0213
SP02_X_POS_L            = $AF0214
SP02_X_POS_H            = $AF0215
SP02_Y_POS_L            = $AF0216
SP02_Y_POS_H            = $AF0217

; Sprite 3
SP03_CONTROL_REG        = $AF0218
SP03_ADDY_PTR_L         = $AF0219
SP03_ADDY_PTR_M         = $AF021A
SP03_ADDY_PTR_H         = $AF021B
SP03_X_POS_L            = $AF021C
SP03_X_POS_H            = $AF021D
SP03_Y_POS_L            = $AF021E
SP03_Y_POS_H            = $AF021F

; Sprite 4
SP04_CONTROL_REG        = $AF0220
SP04_ADDY_PTR_L         = $AF0221
SP04_ADDY_PTR_M         = $AF0222
SP04_ADDY_PTR_H         = $AF0223
SP04_X_POS_L            = $AF0224
SP04_X_POS_H            = $AF0225
SP04_Y_POS_L            = $AF0226
SP04_Y_POS_H            = $AF0227

; Sprite 5
SP05_CONTROL_REG        = $AF0228
SP05_ADDY_PTR_L         = $AF0229
SP05_ADDY_PTR_M         = $AF022A
SP05_ADDY_PTR_H         = $AF022B
SP05_X_POS_L            = $AF022C
SP05_X_POS_H            = $AF022D
SP05_Y_POS_L            = $AF022E
SP05_Y_POS_H            = $AF022F

; Sprite 6
SP06_CONTROL_REG        = $AF0230
SP06_ADDY_PTR_L         = $AF0231
SP06_ADDY_PTR_M         = $AF0232
SP06_ADDY_PTR_H         = $AF0233
SP06_X_POS_L            = $AF0234
SP06_X_POS_H            = $AF0235
SP06_Y_POS_L            = $AF0236
SP06_Y_POS_H            = $AF0237

; Sprite 7
SP07_CONTROL_REG        = $AF0238
SP07_ADDY_PTR_L         = $AF0239
SP07_ADDY_PTR_M         = $AF023A
SP07_ADDY_PTR_H         = $AF023B
SP07_X_POS_L            = $AF023C
SP07_X_POS_H            = $AF023D
SP07_Y_POS_L            = $AF023E
SP07_Y_POS_H            = $AF023F

; Sprite 8
SP08_CONTROL_REG        = $AF0240
SP08_ADDY_PTR_L         = $AF0241
SP08_ADDY_PTR_M         = $AF0242
SP08_ADDY_PTR_H         = $AF0243
SP08_X_POS_L            = $AF0244
SP08_X_POS_H            = $AF0245
SP08_Y_POS_L            = $AF0246
SP08_Y_POS_H            = $AF0247

; Sprite 9
SP09_CONTROL_REG        = $AF0248
SP09_ADDY_PTR_L         = $AF0249
SP09_ADDY_PTR_M         = $AF024A
SP09_ADDY_PTR_H         = $AF024B
SP09_X_POS_L            = $AF024C
SP09_X_POS_H            = $AF024D
SP09_Y_POS_L            = $AF024E
SP09_Y_POS_H            = $AF024F

; Sprite 10
SP10_CONTROL_REG        = $AF0250
SP10_ADDY_PTR_L         = $AF0251
SP10_ADDY_PTR_M         = $AF0252
SP10_ADDY_PTR_H         = $AF0253
SP10_X_POS_L            = $AF0254
SP10_X_POS_H            = $AF0255
SP10_Y_POS_L            = $AF0256
SP10_Y_POS_H            = $AF0257

; Sprite 11
SP11_CONTROL_REG        = $AF0258
SP11_ADDY_PTR_L         = $AF0259
SP11_ADDY_PTR_M         = $AF025A
SP11_ADDY_PTR_H         = $AF025B
SP11_X_POS_L            = $AF025C
SP11_X_POS_H            = $AF025D
SP11_Y_POS_L            = $AF025E
SP11_Y_POS_H            = $AF025F

; Sprite 12
SP12_CONTROL_REG        = $AF0260
SP12_ADDY_PTR_L         = $AF0261
SP12_ADDY_PTR_M         = $AF0262
SP12_ADDY_PTR_H         = $AF0263
SP12_X_POS_L            = $AF0264
SP12_X_POS_H            = $AF0265
SP12_Y_POS_L            = $AF0266
SP12_Y_POS_H            = $AF0267

; Sprite 13
SP13_CONTROL_REG        = $AF0268
SP13_ADDY_PTR_L         = $AF0269
SP13_ADDY_PTR_M         = $AF026A
SP13_ADDY_PTR_H         = $AF026B
SP13_X_POS_L            = $AF026C
SP13_X_POS_H            = $AF026D
SP13_Y_POS_L            = $AF026E
SP13_Y_POS_H            = $AF026F

; Sprite 14
SP14_CONTROL_REG        = $AF0270
SP14_ADDY_PTR_L         = $AF0271
SP14_ADDY_PTR_M         = $AF0272
SP14_ADDY_PTR_H         = $AF0273
SP14_X_POS_L            = $AF0274
SP14_X_POS_H            = $AF0275
SP14_Y_POS_L            = $AF0276
SP14_Y_POS_H            = $AF0277

; Sprite 15
SP15_CONTROL_REG        = $AF0278
SP15_ADDY_PTR_L         = $AF0279
SP15_ADDY_PTR_M         = $AF027A
SP15_ADDY_PTR_H         = $AF027B
SP15_X_POS_L            = $AF027C
SP15_X_POS_H            = $AF027D
SP15_Y_POS_L            = $AF027E
SP15_Y_POS_H            = $AF027F

; Sprite 16
SP16_CONTROL_REG        = $AF0280
SP16_ADDY_PTR_L         = $AF0281
SP16_ADDY_PTR_M         = $AF0282
SP16_ADDY_PTR_H         = $AF0283
SP16_X_POS_L            = $AF0284
SP16_X_POS_H            = $AF0285
SP16_Y_POS_L            = $AF0286
SP16_Y_POS_H            = $AF0287

; Sprite 17
SP17_CONTROL_REG        = $AF0288
SP17_ADDY_PTR_L         = $AF0289
SP17_ADDY_PTR_M         = $AF028A
SP17_ADDY_PTR_H         = $AF028B
SP17_X_POS_L            = $AF028C
SP17_X_POS_H            = $AF028D
SP17_Y_POS_L            = $AF028E
SP17_Y_POS_H            = $AF028F

; Mouse Pointer Graphic Memory
MOUSE_PTR_GRAP0_START    = $AF0500 ; 16 x 16 = 256 Pixels (Grey Scale) 0 = Transparent, 1 = Black , 255 = White
MOUSE_PTR_GRAP0_END      = $AF05FF ; Pointer 0
MOUSE_PTR_GRAP1_START    = $AF0600 ;
MOUSE_PTR_GRAP1_END      = $AF06FF ; Pointer 1

MOUSE_PTR_CTRL_REG_L    = $AF0700 ; Bit[0] Enable, Bit[1] = 0  ( 0 = Pointer0, 1 = Pointer1)
MOUSE_PTR_CTRL_REG_H    = $AF0701 ;
MOUSE_PTR_X_POS_L       = $AF0702 ; X Position (0 - 639) (Can only read now) Writing will have no effect
MOUSE_PTR_X_POS_H       = $AF0703 ;
MOUSE_PTR_Y_POS_L       = $AF0704 ; Y Position (0 - 479) (Can only read now) Writing will have no effect
MOUSE_PTR_Y_POS_H       = $AF0705 ;
MOUSE_PTR_BYTE0         = $AF0706 ; Byte 0 of Mouse Packet (you must write 3 Bytes)
MOUSE_PTR_BYTE1         = $AF0707 ; Byte 1 of Mouse Packet (if you don't, then )
MOUSE_PTR_BYTE2         = $AF0708 ; Byte 2 of Mouse Packet (state Machine will be jammed in 1 state)
                                  ; (And the mouse won't work)
C256F_MODEL_MAJOR       = $AF070B ;
C256F_MODEL_MINOR       = $AF070C ;
FPGA_DOR                = $AF070D ;
FPGA_MOR                = $AF070E ;
FPGA_YOR                = $AF070F ;

;                       = $AF0800 ; the RTC is Here
;                       = $AF1000 ; The SuperIO Start is Here
;                       = $AF13FF ; The SuperIO Start is Here

FG_CHAR_LUT_PTR         = $AF1F40
BG_CHAR_LUT_PTR		      = $AF1F80

GRPH_LUT0_PTR		        = $AF2000
GRPH_LUT1_PTR		        = $AF2400
GRPH_LUT2_PTR		        = $AF2800
GRPH_LUT3_PTR		        = $AF2C00
GRPH_LUT4_PTR		        = $AF3000
GRPH_LUT5_PTR		        = $AF3400
GRPH_LUT6_PTR		        = $AF3800
GRPH_LUT7_PTR		        = $AF3C00

GAMMA_B_LUT_PTR		      = $AF4000
GAMMA_G_LUT_PTR		      = $AF4100
GAMMA_R_LUT_PTR		      = $AF4200

TILE_MAP0       		    = $AF5000     ;$AF5000 - $AF57FF
TILE_MAP1               = $AF5800     ;$AF5800 - $AF5FFF
TILE_MAP2               = $AF6000     ;$AF6000 - $AF67FF
TILE_MAP3               = $AF6800     ;$AF6800 - $AF6FFF

FONT_MEMORY_BANK0       = $AF8000     ;$AF8000 - $AF87FF
FONT_MEMORY_BANK1       = $AF8800     ;$AF8800 - $AF8FFF
CS_TEXT_MEM_PTR         = $AFA000
CS_COLOR_MEM_PTR        = $AFC000


BTX_START               = $AFE000     ; BEATRIX Registers
BTX_END                 = $AFFFFF

.include "VKYII_CFP9553_BITMAP_def.asm"
.include "VKYII_CFP9553_TILEMAP_def.asm"
.include "VKYII_CFP9553_VDMA_def.asm"
