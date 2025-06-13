MODE_SINGLE = 1
MODE_TRIPLE = 3

_M_SINGLE_MODE_X = 80
_M_SINGLE_MODE_Y = 72

_M_TRIPLE_MODE_X = _M_SINGLE_MODE_X + 48
_M_TRIPLWE_MODE_Y = 72

mode_choose:
    ;; render the first card
    ld a, 10
    ld (_deck_gfx_cur_column_x), a
    ld a, 8
    ld (_deck_gfx_cur_card_y), a
    ld (_deck_gfx_cur_card_frame), a
    call _deck_gfx_render_card

    ;; now the triple cluster
    ld a, 16
    ld (_deck_gfx_cur_column_x), a
    ld (_deck_gfx_cur_card_frame), a
    call _deck_gfx_render_card

    ld a, 17
    ld (_deck_gfx_cur_column_x), a
    add 5
    ld (_deck_gfx_cur_card_frame), a
    call _deck_gfx_render_card

    ld a, 18
    ld (_deck_gfx_cur_column_x), a
    add 5
    add 5
    add 5
    add 5
    ld (_deck_gfx_cur_card_frame), a
    call _deck_gfx_render_card


    ; ERAPI_LoadCustomBackground()
    ; a  = bg#(0-3)
    ; de = pointer to backround struct
    ld  a, DECK_GFX_BG
    ld  de, deck_gfx_background
    rst 0
    .db ERAPI_LoadCustomBackground

    ;; starting pos for cursor
    ld de, _M_SINGLE_MODE_X
    call _m_toggle__render

_m_run:
    ld a, 1
    halt

    ld hl, (SYS_INPUT_JUST)
    ld a, l
    and ERAPI_KEY_LEFT
    call nz, _m_toggle

    ld hl, (SYS_INPUT_JUST)
    ld a, l
    and ERAPI_KEY_RIGHT
    call nz, _m_toggle

    ld hl, (SYS_INPUT_JUST)
    ld a, l
    and ERAPI_KEY_A
    jr nz, _m_run__choice_made

    jr _m_run

    _m_run__choice_made:
    call sound_play_ace_drop_sfx
    ld a, 20
    halt

    ld de, 300
    call _m_toggle__render

    call _deck_gfx_clear
    ; ERAPI_LoadCustomBackground()
    ; a  = bg#(0-3)
    ; de = pointer to backround struct
    ld  a, DECK_GFX_BG
    ld  de, deck_gfx_background
    rst 0
    .db ERAPI_LoadCustomBackground

    ld a, 1
    halt
    ret

_m_toggle:
    call sound_play_cursor_move_sfx
    ld a, (mode_chosen_mode)
    cp MODE_SINGLE
    jr nz, _m_toggle__go_to_single
    ;; we are already in single mode, so to triple mode
    ld a, MODE_TRIPLE
    ld (mode_chosen_mode), a
    ld de, _M_TRIPLE_MODE_X
    jr _m_toggle__render

    _m_toggle__go_to_single:
    ld a, MODE_SINGLE
    ld (mode_chosen_mode), a
    ld de, _M_SINGLE_MODE_X

    _m_toggle__render:
    ld hl, (_cursor_gfx_sprite_cursor_handle)
    ld bc, _M_SINGLE_MODE_Y
    rst  0
    .db  ERAPI_SetSpritePos
    ret

mode_chosen_mode:
    .db MODE_SINGLE

