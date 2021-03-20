
;C256FOENIX_MONIKER     .dstruct MONIKER_ATTR, SS_MONIKER, 320, 64, 160, 64
;FMX_MONIKER            .dstruct MONIKER_ATTR, SS_FMX_TXT, 160, 80, 240, 140
;UPlus_MONIKER          .dstruct MONIKER_ATTR, SS_UPlus_TXT, 96, 64, 272, 272
;U_MONIKER              .dstruct MONIKER_ATTR, SS_U_TXT, 64, 64, 288, 140

C256Moniker_SizeX = 320
C256Moniker_SizeY = 64
C256Moniker_PosX = 160
C256Moniker_PosY = 48

FMXMoniker_SizeX = 160
FMXMoniker_SizeY = 80
FMXMoniker_PosX = 240
FMXMoniker_PosY = 110

UPlusMoniker_SizeX = 96
UPlusMoniker_SizeY = 64
UPlusMoniker_PosX = 272
UPlusMoniker_PosY = 110

UMoniker_SizeX = 64
UMoniker_SizeY = 64
UMoniker_PosX = 288
UMoniker_PosY = 110

Bitmap_X_Size  = 640
Bitmap_Y_Size  = 480

Splashscreen_BitMapSetup .proc

        setas
        setxl
        ; Setup Master Control
        LDA #( Mstr_Ctrl_Graph_Mode_En | Mstr_Ctrl_Bitmap_En | Mstr_Ctrl_Text_Mode_En | Mstr_Ctrl_Text_Overlay );
        STA @l MASTER_CTRL_REG_L
        LDA #$00
        STA @l MASTER_CTRL_REG_H
        LDA #$00
        STA @l BM0_CONTROL_REG

        LDA #( BM_Enable | BM_LUT7)
        STA @l BM1_CONTROL_REG
        LDA #$00
        STA @l BM1_START_ADDY_L
        LDA #$00
        STA @l BM1_START_ADDY_M
        STA @l BM1_START_ADDY_H

        ; Turn Off Border
        LDA #$01
        STA BORDER_CTRL_REG
        LDA #$08
        STA BORDER_X_SIZE
        STA BORDER_Y_SIZE

        LDA #$80
        STA BORDER_COLOR_G
        LDA #$00
        STA BORDER_COLOR_B
        STA BORDER_COLOR_R


        LDA #$A0
        STA @l VKY_TXT_CURSOR_CHAR_REG

        LDA #$10
        STA @l BACKGROUND_COLOR_G
        LDA #$10
        STA @l BACKGROUND_COLOR_R
        STA @l BACKGROUND_COLOR_B


        setas
        setxl
        LDX #$0000
SS_LUT_BRANCH:
        LDA @l SS_MONIKER_LUT, X
        NOP
        STA @l GRPH_LUT7_PTR, X
        INX
        CPX #1024
        BNE SS_LUT_BRANCH

        ; the LUT is somewhat incomplete, let's assign Black to Pixel 1 for the border of the text
        LDA #$00
        STA @l GRPH_LUT7_PTR + 4
        STA @l GRPH_LUT7_PTR + 5
        STA @l GRPH_LUT7_PTR + 6                

        ; Let's Go Clear the Bitmap Space
        JSL SS_VDMA_CLEAR_MEMORY_640_480;


        ; Init DMA Registers to Transfer C256 Foenix Moniker on the 640x480 Bitmap Page
        ; This is the Source Material
        setal
        LDA #<>SS_MONIKER      ; Set up the Source
        STA @l SDMA_SRC_ADDY_L
        LDA #<>( C256Moniker_SizeX * C256Moniker_SizeY )
        STA @l SDMA_SIZE_L
        LDA #$0000
        STA @l SDMA_SRC_STRIDE_L  ; Set the Source Stride in SDMA   

        LDA #<>( C256Moniker_PosY * Bitmap_X_Size + C256Moniker_PosX)    ; Set up the Source
        STA @l VDMA_DST_ADDY_L
        LDA #C256Moniker_SizeX
        STA @l VDMA_X_SIZE_L
        LDA #C256Moniker_SizeY
        STA @l VDMA_Y_SIZE_L
        ; There is a stride of 640 
        LDA #Bitmap_X_Size
        STA @l VDMA_DST_STRIDE_L  ; Set the Destination Stride in the VDMA

        setas
        LDA #`SS_MONIKER
        STA @l SDMA_SRC_ADDY_H
        LDA #`( C256Moniker_SizeX * C256Moniker_SizeY )
        STA @l SDMA_SIZE_H  
        LDA #$00
        STA @l SDMA_SIZE_H+1 ; Just making sure there is no spurious data in the next register
        LDA #`( C256Moniker_PosY * Bitmap_X_Size + C256Moniker_PosX)
        STA @l VDMA_DST_ADDY_H
        JSL SS_VDMA_SETUP_2_TRANSFER_IMAGE  ;VDMA Transfer from SRAM To VRAM to Transfer the Moniker 320x64
        ; THere will be a choice here to Make sure the Right one is displayed depending on the Model


        ; What Model do we Have? here is the point where the right Moniker will be displayed under the Computer Model

        setas 
        LDA @lMODEL 
        AND #$03
        CMP #$00 
        BEQ DMA_FMX_Moniker
        CMP #$01
        BEQ DMA_UPlus_Moniker
        CMP #$02 
        BNE BAD_MODEL_NUMBER
        BRL DMA_U_Moniker

 BAD_MODEL_NUMBER:       ;
        ; Here is the FMX Text
        ;
DMA_FMX_Moniker:        
        setal
        LDA #<>SS_FMX_TXT      ; Set up the Source
        STA @l SDMA_SRC_ADDY_L
        LDA #<>( FMXMoniker_SizeX * FMXMoniker_SizeY )
        STA @l SDMA_SIZE_L
        LDA #$0000
        STA @l SDMA_SRC_STRIDE_L  ; Set the Source Stride in SDMA   

        LDA #<>( FMXMoniker_PosY * Bitmap_X_Size + FMXMoniker_PosX)    ; Set up the Source
        STA @l VDMA_DST_ADDY_L
        LDA #FMXMoniker_SizeX
        STA @l VDMA_X_SIZE_L
        LDA #FMXMoniker_SizeY
        STA @l VDMA_Y_SIZE_L
        ; There is a stride of 640 
        LDA #Bitmap_X_Size
        STA @l VDMA_DST_STRIDE_L  ; Set the Destination Stride in the VDMA

        setas
        LDA #`SS_FMX_TXT
        STA @l SDMA_SRC_ADDY_H
        LDA #`( FMXMoniker_SizeX * FMXMoniker_SizeY )
        STA @l SDMA_SIZE_H  
        LDA #$00
        STA @l SDMA_SIZE_H+1 ; Just making sure there is no spurious data in the next register
        LDA #`( FMXMoniker_PosY * Bitmap_X_Size + FMXMoniker_PosX)
        STA @l VDMA_DST_ADDY_H
        JSL SS_VDMA_SETUP_2_TRANSFER_IMAGE  ;VDMA Transfer from SRAM To VRAM to Transfer the Moniker 320x64        
        JMP Done_DMA_Model_Moniker
        ;
        ; Here is the U+ Text
        ;
DMA_UPlus_Moniker:        
        setal
        LDA #<>SS_UPlus_TXT      ; Set up the Source
        STA @l SDMA_SRC_ADDY_L
        LDA #<>( UPlusMoniker_SizeX * UPlusMoniker_SizeY )
        STA @l SDMA_SIZE_L
        LDA #$0000
        STA @l SDMA_SRC_STRIDE_L  ; Set the Source Stride in SDMA   

        LDA #<>( UPlusMoniker_PosY * Bitmap_X_Size + UPlusMoniker_PosX)    ; Set up the Source
        STA @l VDMA_DST_ADDY_L
        LDA #UPlusMoniker_SizeX
        STA @l VDMA_X_SIZE_L
        LDA #UPlusMoniker_SizeY
        STA @l VDMA_Y_SIZE_L
        ; There is a stride of 640 
        LDA #Bitmap_X_Size
        STA @l VDMA_DST_STRIDE_L  ; Set the Destination Stride in the VDMA

        setas
        LDA #`SS_UPlus_TXT
        STA @l SDMA_SRC_ADDY_H
        LDA #`( UPlusMoniker_SizeX * UPlusMoniker_SizeY )
        STA @l SDMA_SIZE_H  
        LDA #$00
        STA @l SDMA_SIZE_H+1 ; Just making sure there is no spurious data in the next register
        LDA #`( UPlusMoniker_PosY * Bitmap_X_Size + UPlusMoniker_PosX)
        STA @l VDMA_DST_ADDY_H
        JSL SS_VDMA_SETUP_2_TRANSFER_IMAGE  ;VDMA Transfer from SRAM To VRAM to Transfer the Moniker 320x64        
        JMP Done_DMA_Model_Moniker
        ;
        ; Here is the U+ Text
        ;
DMA_U_Moniker:        
        setal
        LDA #<>SS_U_TXT      ; Set up the Source
        STA @l SDMA_SRC_ADDY_L
        LDA #<>( UMoniker_SizeX *UMoniker_SizeY )
        STA @l SDMA_SIZE_L
        LDA #$0000
        STA @l SDMA_SRC_STRIDE_L  ; Set the Source Stride in SDMA   

        LDA #<>( UMoniker_PosY * Bitmap_X_Size + UMoniker_PosX)    ; Set up the Source
        STA @l VDMA_DST_ADDY_L
        LDA #UMoniker_SizeX
        STA @l VDMA_X_SIZE_L
        LDA #UMoniker_SizeY
        STA @l VDMA_Y_SIZE_L
        ; There is a stride of 640 
        LDA #Bitmap_X_Size
        STA @l VDMA_DST_STRIDE_L  ; Set the Destination Stride in the VDMA

        setas
        LDA #`SS_U_TXT
        STA @l SDMA_SRC_ADDY_H
        LDA #`( UMoniker_SizeX * UMoniker_SizeY )
        STA @l SDMA_SIZE_H  
        LDA #$00
        STA @l SDMA_SIZE_H+1 ; Just making sure there is no spurious data in the next register
        LDA #`( UMoniker_PosY * Bitmap_X_Size + UMoniker_PosX)
        STA @l VDMA_DST_ADDY_H
        JSL SS_VDMA_SETUP_2_TRANSFER_IMAGE  ;VDMA Transfer from SRAM To VRAM to Transfer the Moniker 320x64        
        JMP Done_DMA_Model_Moniker


Done_DMA_Model_Moniker
        RTL
        .pend



SS_VDMA_SETUP_2_TRANSFER_IMAGE .proc
        ;; This is the Source Address of the Data inside the SRAM Mem (this CPU offset)
        setas
        ; SDMA Master Control
        ; Source
        LDA #( SDMA_CTRL0_Enable | SDMA_CTRL0_SysRAM_Src )
        STA @l SDMA_CTRL_REG0
        ; VDMA Master Control
        ; Destination
        LDA #( VDMA_CTRL_Enable |  VDMA_CTRL_SysRAM_Src | VDMA_CTRL_1D_2D )
        ;LDA #( VDMA_CTRL_Enable |  VDMA_CTRL_SysRAM_Src  )
        STA @l VDMA_CONTROL_REG
        setas
        ; Begin Transfer
        ; Start the VDMA Controller First
        LDA @l VDMA_CONTROL_REG
        ORA #VDMA_CTRL_Start_TRF
        STA @l VDMA_CONTROL_REG
        ; Then, Start the SDMA Controller Second (Since the SDMA will lock the CPU while it is doing its job)
        LDA @l SDMA_CTRL_REG0
        ORA #SDMA_CTRL0_Start_TRF
        STA @l SDMA_CTRL_REG0
        NOP ; When the transfer is started the CPU will be put on Hold (RDYn)...
        NOP ; Before it actually gets to stop it will execute a couple more instructions
        NOP ; From that point on, the CPU is halted (keep that in mind) No IRQ will be processed either during that time
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP                
        LDA #$00
        STA @l SDMA_CTRL_REG0

NOTFINISHED:
        LDA @l VDMA_STATUS_REG
        AND #$80
        CMP #$80
        BEQ NOTFINISHED

        LDA #$00
        STA @l VDMA_CONTROL_REG
        RTL

        .pend
;
SS_VDMA_CLEAR_MEMORY_640_480 .proc
        ;; This is the Source Address of the Data inside the SRAM Mem (this CPU offset)
        setas
        LDA #( VDMA_CTRL_Enable | VDMA_CTRL_TRF_Fill )
        STA @l VDMA_CONTROL_REG
        ; This is the Address of Destination inside VRAM (this VICKY II offset)
        LDA #$00
        STA @l VDMA_BYTE_2_WRITE

        setal
        LDA #$0000      ; Set up the Source
        STA @l VDMA_DST_ADDY_L
        setas
        LDA #$00
        STA @l VDMA_DST_ADDY_H

        ; This is the Size of the Transfer
        setal
        LDA #<>(640*480)
        STA @l VDMA_SIZE_L
        setas
        LDA #`(640*480)
        STA @l VDMA_SIZE_H
        LDA #$00
        STA @l VDMA_SIZE_H+1 ; Just making sure there is no spurious data in the next register

        ; Begin Transfer
        LDA VDMA_CONTROL_REG
        ORA #VDMA_CTRL_Start_TRF
        STA @l VDMA_CONTROL_REG
         NOP ; When the transfer is started the CPU will be put on Hold (RDYn)...
        NOP ; Before it actually gets to stop it will execute a couple more instructions
        NOP ; From that point on, the CPU is halted (keep that in mind) No IRQ will be processed either during that time
        NOP
        NOP
        NOP
        NOP
        NOP

SS_VDMA_CLR_LOOPA:
        LDA @l VDMA_STATUS_REG
        AND #$80
        CMP #$80  ; Check if bit $80 is cleared to indicate that the VDMA is done.
        BEQ SS_VDMA_CLR_LOOPA
        NOP
        LDA #$00
        STA @l VDMA_CONTROL_REG
        RTL
        .pend

;
SS_VDMA_TRANSFER_VRAM_2_VRAM .proc
        ;; This is the Source Address of the Data inside the SRAM Mem (this CPU offset)
        setas
        LDA #( VDMA_CTRL_Enable )
        STA @l VDMA_CONTROL_REG
        ; This is the Address of Destination inside VRAM (this VICKY II offset)
        LDA #$00
        STA @l VDMA_BYTE_2_WRITE
        setal
        LDA #$9600      ; Set up the Source
        STA @l VDMA_SRC_ADDY_L
        setas
        LDA #$00
        STA @l VDMA_SRC_ADDY_H

        setal
        LDA #$0000      ; Set up the Source
        STA @l VDMA_DST_ADDY_L
        setas
        LDA #$00
        STA @l VDMA_DST_ADDY_H

        ; This is the Size of the Transfer
        setal
        LDA #<>(320*16)
        STA @l VDMA_SIZE_L
        setas
        LDA #`(320*16)
        STA @l VDMA_SIZE_H
        LDA #$00
        STA @l VDMA_SIZE_H+1 ; Just making sure there is no spurious data in the next register

        ; Begin Transfer
        LDA VDMA_CONTROL_REG
        ORA #VDMA_CTRL_Start_TRF
        STA @l VDMA_CONTROL_REG
        NOP
        NOP
        NOP

SS_VDMA_CLR_LOOPB:
        LDA @l VDMA_STATUS_REG
        AND #$80
        CMP #$80  ; Check if bit $80 is cleared to indicate that the VDMA is done.
        BEQ SS_VDMA_CLR_LOOPB
        NOP
        LDA #$00
        STA @l VDMA_CONTROL_REG
        RTL
        .pend


