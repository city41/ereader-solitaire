    ; RST 0
    ERAPI_FadeIn                   = 0x00
    ERAPI_FadeOut                  = 0x01
    ERAPI_LoadSystemBackground     = 0x10
    ERAPI_SetBackgroundOffset      = 0x11
    ERAPI_SetBackgroundAutoScroll  = 0x12
    ERAPI_BackgroundMirrorToggle   = 0x13
    ERAPI_SetBackgroundMode        = 0x19

    ;; can't get this to work, I am assuming it changes background priority
    ERAPI_LayerShow                = 0x20
    ERAPI_LayerHide                = 0x21
    ERAPI_LoadCustomBackground     = 0x2D
    ERAPI_CreateSystemSprite       = 0x30
    ERAPI_SpriteFree               = 0x31
    ERAPI_SetSpritePos             = 0x32
    ERAPI_SpriteFrameNext          = 0x34
    ERAPI_SetSpriteFrame           = 0x36
    ERAPI_SetSpriteFrameBank       = 0x37
    ERAPI_SpriteAutoMove           = 0x39
    ERAPI_SpriteAutoAnimate        = 0x3c 
    ERAPI_SpriteAutoRotateUntilAngle  = 0x3e
    ERAPI_SpriteAutoRotateByTime   = 0x40
    ERAPI_SpriteDrawOnBackground   = 0x45
    ERAPI_SpriteShow               = 0x46
    ERAPI_SpriteHide               = 0x47
    ERAPI_SpriteMirrorToggle       = 0x48
    ERAPI_GetSpritePos             = 0x4C
    ERAPI_SpriteCreate             = 0x4D
    ERAPI_SpriteMove               = 0x57
    ERAPI_SetSpriteHitBoxSize      = 0x58
    ERAPI_SpriteAutoScaleUntilSize = 0x5B
    ERAPI_SpriteAutoScaleWidthUntilSize = 0x5D
    ERAPI_SpriteAutoScaleHeightUntilSize = 0x5E
    ERAPI_SetSpriteType            = 0x68
    ERAPI_GetSpriteType            = 0x69
    ERAPI_DrawNumber               = 0x6b
    ERAPI_DrawNumberNewValue       = 0x6c
    ERAPI_DrawNumberDeltaValue     = 0x6d
    ERAPI_DrawNumberGetValue       = 0x6E
    ERAPI_DrawTime                 = 0x6F
    ERAPI_DrawTimeNewValue         = 0x70
    ERAPI_DrawTimeDeltaValue       = 0x71
    ERAPI_DrawNumberBlink          = 0x72
    ERAPI_SetBackgroundPalette     = 0x7E
    ERAPI_SetSpritePalette         = 0x80
    ERAPI_CreateRegion             = 0x90
    ERAPI_SetRegionColor           = 0x91
    ERAPI_ClearRegion              = 0x92
    ERAPI_SetPixel                 = 0x93
    ERAPI_DrawLine                 = 0x95
    ERAPI_DrawRect                 = 0x96
    ERAPI_ToggleSpriteVisibility   = 0x97
    ERAPI_SetTextColor             = 0x98
    ERAPI_DrawText                 = 0x99
    ERAPI_SetTextSize              = 0x9A
    ERAPI_FindClosestSprite        = 0xAA
    ERAPI_CalcDistanceBetweenSprites=0xAB
    ERAPI_GetTextWidth             = 0xC0
    ERAPI_ScanDotCode              = 0xC2
    ERAPI_SetSpritePosAnimatedSpeed= 0xDA
    ERAPI_SpriteFindCollisions     = 0xE5
    ERAPI_SetSpritePaletteIndex    = 0xE7
    ERAPI_SystemSpriteIdIsValid    = 0xF0
    ERAPI_RandomSeed               = 0xF1

    ; RST 8
    ERAPI_Exit                     = 0x00
    ;; hl=a*e
    ERAPI_Mul8                     = 0x01
    ;; hl=hl*de
    ERAPI_Mul16                    = 0x02
    ;; hl=hl/de
    ERAPI_Div                      = 0x03
    ;; hl=hl%de
    ERAPI_Mod                      = 0x04
    ERAPI_PlaySystemSound          = 0x05

    ; a is randomly populated 0-ff
    ERAPI_Rand                     = 0x07

    ; a=max
    ; a is randomly populated [0-a)
    ERAPI_RandMax                  = 0x12
    ERAPI_PauseSound               = 0x16
    ERAPI_ResumeSound              = 0x17
    ERAPI_PlaySystemSoundAtVolume  = 0x18
    ERAPI_IsSoundPlaying           = 0x19
    ERAPI_FlashLoadUserData        = 0x1B
    ERAPI_FlashSaveUserData        = 0x1C
    ERAPI_SuppressStartPauseScreen = 0x21
    ERAPI_ClearSpritesAndBackgrounds = 0x35




; #define ERAPI_SpriteSetPosAnimatedSpeed(a, b, c, d)                            \
;   ERAPI_FUNC_X5(0x2DA, a, b, c, d)
; //            a: u16 Sprite Handle
; //            b: u16 X Position
; //            c: u16 Y Position
; //            d: u16 Speed (fixed speed, variable duration, depends on distance)