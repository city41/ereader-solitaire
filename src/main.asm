    .include "erapi.asm"
    .include "input.asm"
    .include "cards.asm"

    .area CODE (ABS)
    .org 0x100

    MAIN_BG = 2
    ; the rocky/mars like terrain
    MAIN_BG_ID = 19

main:
    rst 8
    .db ERAPI_SuppressStartPauseScreen

    call deck_gfx_random_back
    call main_init
    call cursor_gfx_init
    call mode_choose
    call title_intro

    call sound_play_bgm1

    call game_init

main_loop:
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

    ;; now randomly pick a bg
    ld a, _M_BG_COUNT
    rst 8
    .db ERAPI_RandMax

    ld hl, _m_bg_ids
    ld b, 0
    ld c, a
    add hl, bc
    ;; random bg id now in a
    ld a, (hl)

    ; ERAPI_LoadSystemBackground()
    ; a = index (1-101)
    ; e = bg# (0-3)
    ld  e, MAIN_BG
    rst 0
    .db ERAPI_LoadSystemBackground


    ; ERAPI_FadeIn()
    ; a = number of frames
    xor a
    rst 0
    .db ERAPI_FadeIn

    ret

_M_BG_COUNT = 4
_m_bg_ids:
    ; 19 twice on purpose, it should be picked most often
    .db 19 ; rocky mars terrain
    .db 19 ; rocky mars terrain
    .db 4 ; desert
    .db 2  ; starry night

    .even
    .include "mode.asm"
    .even
    .include "title.asm"
    .even
    .include "game.asm"
    .even
    .include "repeat_input.asm"
