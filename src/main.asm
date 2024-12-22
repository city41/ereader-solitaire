    .include "erapi.asm"
    .include "cards.asm"

    .area CODE (ABS)
    .org 0x100

    MAIN_BG = 2
    ; the rocky/mars like terrain
    MAIN_BG_ID = 19

main:
    call main_init
    call title_intro

    call sound_play_bgm1

    call game_init

main_loop:

    call input_read
    call game_frame

    ld a, #1
    halt
    jr main_loop

main_init:
    ; ERAPI_SetBackgroundMode()
    ; a = mode (0-2)
    ld a, #0
    rst 0
    .db ERAPI_SetBackgroundMode

    ; ERAPI_LoadSystemBackground()
    ; a = index (1-101)
    ; e = bg# (0-3)
    ld  a, MAIN_BG_ID
    ld  e, MAIN_BG
    rst 0
    .db ERAPI_LoadSystemBackground


    ; ERAPI_FadeIn()
    ; a = number of frames
    xor a
    rst 0
    .db ERAPI_FadeIn

    ret

    .even
    .include "input.asm"
    .even
    .include "title.asm"
    .even
    .include "game.asm"
