; just common defines for input

    SYS_INPUT_JUST   = 0xC2
    SYS_INPUT_RAW    = 0xC4
    ERAPI_KEY_A      = 0x0001
    ERAPI_KEY_B      = 0x0002
    ERAPI_KEY_SELECT = 0x0004
    ERAPI_KEY_START  = 0x0008
    ERAPI_KEY_RIGHT  = 0x0010
    ERAPI_KEY_LEFT   = 0x0020
    ERAPI_KEY_UP     = 0x0040
    ERAPI_KEY_DOWN   = 0x0080

    ;; L and R are on the high byte
    ;; but these masks are on the low byte
    ;; because only one input byte is loaded at a time
    ERAPI_KEY_R      = 0x0001
    ERAPI_KEY_L      = 0x0002