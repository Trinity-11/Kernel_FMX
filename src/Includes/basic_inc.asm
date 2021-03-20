;;;
;;; Jump table to connect to BASIC816 and the machine language monitor
;;;
.if ( TARGET_SYS == SYS_C256_FMX ) || ( TARGET_SYS == SYS_C256_U_PLUS )
    BASIC = $3A0000
    MONITOR = BASIC + 4
.else
    BASIC = $1A0000
    MONITOR = BASIC + 4
.endif

