    TITLE_RETRO_X = 120
    TITLE_RETRO_Y = 150
    TITLE_RETRO_WIDTH = 64

title_intro:
    ; ERAPI_SpriteCreate()
    ; e  = pal#
    ; hl = sprite data
    ld  e, #0x06
    ld  hl, _title_sprite_retro
    rst 0
    .db ERAPI_SpriteCreate
    ld  (_title_sprite_retro_handle), hl

    ; ERAPI_SetSpritePos()
    ; hl = handle
    ; de = x
    ; bc = y
    ld de, TITLE_RETRO_X
    ld bc, TITLE_RETRO_Y
    rst  0
    .db  ERAPI_SetSpritePos

    call sound_play_drum_roll_sfx

    call deck_deal_deck

    call sound_play_cymbol_sfx

    ;; keep the title up just a little longer
    ld a, #30
    halt

    ;; and now tear it all down

    ;; free retro 
    ld hl, (_title_sprite_retro_handle)
    rst 0
    .db ERAPI_SpriteFree

    ret

    .even
_title_tiles_retro:
    .include "retro_logo.tiles.asm"

    .even
_title_palette_retro:
    .include "retro_logo.palette.asm"

    .even
_title_sprite_retro:
    .dw _title_tiles_retro  ; tiles
    .dw _title_palette_retro; palette
    .db 0x8          ; width
    .db 0x01          ; height
    .db 0x01          ; frames per bank
    .db 0x00          ; unknown
    .db 0x08          ; hitbox width
    .db 0x08          ; hitbox height
    .db 0x01          ; total frames

    .even
_title_sprite_retro_handle:
    .ds 2