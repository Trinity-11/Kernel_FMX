; GABE Internal SDCard Controller

SDC_VERSION_REG         = $AFEA00    ; Ought to read 12
SDC_CONTROL_REG         = $AFEA01    ; Bit0 1 = Reset core logic, and registers. Self clearing
SDC_TRANS_TYPE_REG      = $AFEA02  ; Bit[1:0]
SDC_TRANS_DIRECT      = $00   ; 00 = Direct Access
SDC_TRANS_INIT_SD     = $01   ; 01 = Init SD
SDC_TRANS_READ_BLK    = $02   ; 10 = RW_READ_BLOCK (512 Bytes)
SDC_TRANS_WRITE_BLK   = $03   ; 11 = RW_WRITE_SD_BLOCK

SDC_TRANS_CONTROL_REG   = $AFEA03
SDC_TRANS_START         = $01

SDC_TRANS_STATUS_REG    = $AFEA04
SDC_TRANS_BUSY          = $01     ;  1= Transaction Busy

SDC_TRANS_ERROR_REG     = $AFEA05
SDC_TRANS_INIT_NO_ERR   = $00   ; Init Error Report [1:0]
SDC_TRANS_INIT_CMD0_ERR = $01
SDC_TRANS_INIT_CMD1_ERR = $02

SDC_TRANS_RD_NO_ERR     = $00   ; Read Error Report [3:2]
SDC_TRANS_RD_CMD_ERR    = $04
SDC_TRANS_RD_TOKEN_ERR  = $08

SDC_TRANS_WR_NO_ERR     = $00   ; Write Report Error  [5:4]
SDC_TRANS_WR_CMD_ERR    = $10   ;
SDC_TRANS_WR_DATA_ERR   = $20
SDC_TRANS_WR_BUSY_ERR   = $30

SDC_DIRECT_ACCESS_REG   = $AFEA06 ; SPI Direct Read and Write - Set DATA before initiating direct Access Transaction

SDC_SD_ADDR_7_0_REG     = $AFEA07 ; Set the ADDR before a block read or block write
SDC_SD_ADDR_15_8_REG    = $AFEA08 ; Addr0 [8:0] Always should be 0, since each block is 512Bytes
SDC_SD_ADDR_23_16_REG   = $AFEA09
SDC_SD_ADDR_31_24_REG   = $AFEA0A

SDC_SPI_CLK_DEL_REG     = $AFEA0B
;...
SDC_RX_FIFO_DATA_REG    = $AFEA10 ; Data from the Block Read
SDC_RX_FIFO_DATA_CNT_HI = $AFEA12 ; How many Bytes in the FIFO HI
SDC_RX_FIFO_DATA_CNT_LO = $AFEA13 ; How many Bytes in the FIFO LO
SDC_RX_FIFO_CTRL_REG    = $AFEA14 ; Bit0  Force Empty - Set to 1 to clear FIFO, self clearing (the bit)
;...
SDC_TX_FIFO_DATA_REG    = $AFEA20 ; Write Data Block here
SDC_TX_FIFO_CTRL_REG    = $AFEA24 ; Bit0  Force Empty - Set to 1 to clear FIFO, self clearing (the bit)
