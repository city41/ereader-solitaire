    GAME_GRAB_CARD_SFX = 31
    GAME_DROP_CARD_SFX = 32
    GAME_ACE_PILE_SFX = 1

    GAME_GRAB_SOURCE_DEALT_PILE = 1
    GAME_GRAB_SOURCE_PLAYFIELD = 2

game_init:
    call cursor_gfx_init
    call deal_pile_load_cards

    call deck_gfx_render
    call cursor_gfx_render

    ret

game_frame:
    ld hl, (input_just_pressed)
    ld a, l
    and ERAPI_KEY_RIGHT
    call nz, _game_handle_right

    ld hl, (input_just_pressed)
    ld a, l
    and ERAPI_KEY_LEFT
    call nz, _game_handle_left

    ld hl, (input_just_pressed)
    ld a, l
    and ERAPI_KEY_DOWN
    call nz, _game_handle_down

    ld hl, (input_just_pressed)
    ld a, l
    and ERAPI_KEY_UP
    call nz, _game_handle_up

    ld hl, (input_just_pressed)
    ld a, l
    and ERAPI_KEY_A
    call nz, _game_handle_a

    ld hl, (input_just_pressed)
    ld a, l
    and ERAPI_KEY_B
    call nz, _game_handle_b

    ld hl, (input_just_pressed)
    ld a, h
    and ERAPI_KEY_L
    call nz, _game_handle_l

    ;; keep track of how long r has been pressed
    ;; if held long enough, will reset the game
    ld hl, (input_pressed)
    ld a, h
    and ERAPI_KEY_R
    jr z, _game_frame__clear_r_count
    ld a, (_game_r_count)
    inc a
    cp 90
    jr z, _game_exit
    ld (_game_r_count), a
    jr _game_frame__r_count_done

    _game_frame__clear_r_count:
    ld a, 0
    ld (_game_r_count), a

    _game_frame__r_count_done:

    ;; see if the game has been won
    ;; a=1 for win
    call _game_has_been_won
    cp 1
    call z, _game_handle_win

    ret

_game_has_been_won:
    ;; first if there was no input, then nothing happened this frame
    ;; so game can't possibly be won
    ld hl, (input_just_pressed)
    ld a, h
    ;; if h | l === 0, then both are zero, no input
    or l
    jr z, _game_has_been_won__nope

    ;; if there is a grabbed card, we are not done
    ld a, (deck_grabbed_cards)
    cp 0
    jr nz, _game_has_been_won__nope

    ;; is there a deal pile card?
    ld a, (_deal_pile_deal_pile_i)
    ;; -1 means the deal pile is empty
    cp -1
    ;; if there is a deal pile card, we are not done
    jr nz, _game_has_been_won__nope

    ;; is there a dealt card?
    ld a, (deal_pile_top_dealt_card)
    cp 0
    ;; if there is a dealt card, we are not done
    jr nz, _game_has_been_won__nope

    ;; finally, if there are no more back cards, the player has won
    ;; don't force them to meticulously put each card in the ace pile
    call deck_is_there_a_back_card
    cp 1
    ;; there is a back card, we are not done
    jr z, _game_has_been_won__nope

    _game_has_been_won__yep:
    ld a, 1
    ret

    _game_has_been_won__nope:
    ld a, 0
    ret

_game_handle_win:
    call sound_stop_music

    ;; hide the regular cursor sprite
    ; ERAPI_SpriteHide()
    ; hl = sprite data
    ld   hl, (_cursor_gfx_sprite_cursor_handle)
    rst  0
    .db  ERAPI_SpriteHide

    ;; hide the grab cursor sprite
    ; ERAPI_SpriteHide()
    ; hl = sprite data
    ld   hl, (_cursor_gfx_sprite_cursor_grab_handle)
    rst  0
    .db  ERAPI_SpriteHide

    ;; wait a bit before showing win message
    ld a, #30
    .db 0x76

    ; ERAPI_SpriteCreate()
    ; e  = pal#
    ; hl = sprite data
    ld  e, #0x08
    ld  hl, _game_sprite_you_win
    rst 0
    .db ERAPI_SpriteCreate

    ;; position it center x, a bit high for y
    ; ERAPI_SetSpritePos()
    ; hl = handle
    ; de = x
    ; bc = y
    ld de, 120
    ld bc, 53
    rst  0
    .db  ERAPI_SetSpritePos

    call sound_play_win_sfx

    ;; now wait for an a to come in
    _game_handle_win__loop:
    ld a, 1
    halt

    call input_read
    ld hl, (input_just_pressed)
    ld a, l
    and ERAPI_KEY_A
    jr z, _game_handle_win__loop

    ;; ok they have pressed a, time to reboot
    ;; wait a bit before resetting

    ld a, #30
    .db 0x76
    ;; purposely falling through to exit
    ;; that way holding r can use this code too
    ;; see game_frame

_game_exit:
    call sound_stop_music
    ; ERAPI_Exit()
    ; a = return value (1=restart 2=exit)
    ld  a, #1
    rst 8
    .db ERAPI_Exit

_game_handle_right:
    call cursor_go_right
    call cursor_gfx_render
    call deck_gfx_render
    call sound_play_cursor_move_sfx
    ret

_game_handle_left:
    call cursor_go_left
    call cursor_gfx_render
    call deck_gfx_render
    call sound_play_cursor_move_sfx
    ret

_game_handle_down:
    call cursor_go_down
    call cursor_gfx_render
    call deck_gfx_render
    ret

_game_handle_up:
    call cursor_go_up
    call cursor_gfx_render
    call deck_gfx_render
    call sound_play_cursor_move_sfx
    ret

_game_handle_a:
    ld a, (cursor_section)
    cp CURSOR_SECTION_DEAL_PILE
    jr nz, _game_handle_a__skip_deal_pile
    ;; in the deal pile?
    ;; if they have a grabbed card, do nothing
    ld a, (deck_grabbed_cards)
    cp 0
    jr nz, _game_handle_a__done
    ;; otherwise, deal a card
    call deal_pile_deal
    call deck_gfx_render
    call cursor_gfx_render
    jr _game_handle_a__done

    _game_handle_a__skip_deal_pile:
    cp CURSOR_SECTION_DEALT_PILE
    jr nz, _game_handle_a__skip_dealt_pile
    ;; they are in the dealt pile
    ;; do they have a grabbed card? call handle_b to put it back
    ld a, (deck_grabbed_cards)
    cp 0
    jr z, _game_handle_a__skip_dealt_cancel
    call _game_handle_b
    jr _game_handle_a__done

    _game_handle_a__skip_dealt_cancel:
    ;; no grabbed card, pick one up

    call deal_pile_grab_dealt_card
    ld a, GAME_GRAB_SOURCE_DEALT_PILE
    ld (_game_grabbed_source), a
    call deck_gfx_render
    call cursor_gfx_render
    jr _game_handle_a__done

    _game_handle_a__skip_dealt_pile:
    ;; does the user already have a grabbed card?
    ld a, (deck_grabbed_cards)
    cp 0
    jr z, _game_handle_a__skip_drop
    call _game_drop_grabbed_cards
    jr _game_handle_a__done

    _game_handle_a__skip_drop:
    ld a, GAME_GRAB_SOURCE_PLAYFIELD
    ld (_game_grabbed_source), a
    call _game_grab_cards_from_playfield

    _game_handle_a__done:
    ret

;; assumption, deck_grabbed_cards[0] == 0
_game_grab_cards_from_playfield:
    ;; only allow grabbing
    ;; when in the playfield
    ld a, (cursor_section)
    cp CURSOR_SECTION_PLAYFIELD
    ret nz

    ;; load the card's location
    ld a, (cursor_playfield_row)
    ld c, a
    ld a, (cursor_playfield_col)
    ld b, a
    ;; tell the deck to grab the cards
    call deck_grab_cards
    ;; need to rerender the playing field
    ;; to erase the card that was in the column
    call deck_gfx_render
    call cursor_gfx_render
    call sound_play_grab_sfx

    ret

;; assumption, deck_grabbed_cards[0] != 0
;; this should only be called from ace piles or playfield
;; if the user is on the deck, then calling this is a bug
_game_drop_grabbed_cards:
    ;; see if we are dropping on playfield or ace pile
    ld a, (cursor_section)
    cp CURSOR_SECTION_ACE_PILES
    jr z, _game_drop_grabbed_card__in_ace_piles

    ;; we are in the playfield
    ld a, (cursor_playfield_col)
    ld b, a
    call deck_drop_grabbed_cards_in_column
    jr _game_drop_grabbed_cards__finish

    _game_drop_grabbed_card__in_ace_piles:
    ;; we are in an ace pile
    ld a, (deck_grabbed_cards)
    call ace_piles_drop_card
    ;; was the drop legal? ace_piles_drop_card will set a=1 if so
    ;; we should only proceed if it did
    cp 1
    ;; not a legal drop, bail
    ret nz

    call deck_on_grabbed_card_moved_to_ace_piles

    ;; did the player do dealt->ace pile?
    ;; if so, go back to dealt
    ld a, (_game_grabbed_source)
    cp GAME_GRAB_SOURCE_DEALT_PILE
    jr nz, _game_drop_grabbed_cards__skip_return_to_dealt
    ld a, CURSOR_SECTION_DEALT_PILE
    ld (cursor_section), a
    ;; reset playfield_col to 0 as we are now in dealt
    ;; so if user presses up/down, they will go to col 0
    ld a, 0
    ld (cursor_playfield_col), a

    _game_drop_grabbed_cards__skip_return_to_dealt:
    _game_drop_grabbed_cards__finish:
    ;; this is not truly a cancel, but it is to cursor
    ;; in this context


    call cursor_on_card_grab_canceled
    call cursor_gfx_on_card_grab_canceled
    call cursor_gfx_render
    ;; need to rerender the playing field
    ;; to put the dropped card back in the column
     call deck_gfx_render

     ret

_game_handle_b:
    ;; does the user have a grabbed card?
    ld a, (deck_grabbed_cards)
    ;; if the grabbed card is zero, then there is no grabbed card
    ;; so instead, use this cancel to head back to deal pile
    cp 0
    jr nz, _game_handle_b__skip_return_to_deal_pile
    ld a, CURSOR_SECTION_DEAL_PILE
    ld (cursor_section), a
    ld a, 0
    ;; since they went back to deal, make playfield_col=0 too
    ;; that way if user presses up/down, they will head to col 0
    ld (cursor_playfield_col), a
    call cursor_gfx_render
    ;; in case there was a too big column rendered at y=0, this will
    ;; make it go back down after the cancel
    call deck_gfx_render
    ret

    _game_handle_b__skip_return_to_deal_pile:

    ld a, (_game_grabbed_source)
    cp GAME_GRAB_SOURCE_DEALT_PILE
    jr nz, _game_handle_b__skip_dealt_pile
    ;; the grab came from the dealt pile
    call deal_pile_cancel_grab
    jr _game_handle_b__done

    _game_handle_b__skip_dealt_pile:
    ;; the grab came from the playfield
    call deck_cancel_grab

    _game_handle_b__done:
    call cursor_on_card_grab_canceled
    call cursor_gfx_on_card_grab_canceled
    call cursor_gfx_render
    ;; need to rerender the playing field
    ;; to put the canceled card back in the column
     call deck_gfx_render
    ret

_game_handle_l:
    call sound_cycle_bgm
    ret

_game_grabbed_source:
    .db 0
_game_r_count:
    .db 0

    .even
_game_tiles_you_win:
    .include "you_win.tiles.asm"
    .even
_game_palette_you_win:
    .include "you_win.palette.asm"

    .even
_game_sprite_you_win:
    .dw _game_tiles_you_win  ; tiles
    .dw _game_palette_you_win; palette
    .db 0x06          ; width
    .db 0x03          ; height
    .db 0x01          ; frames
    .db 0x01          ; ?
    .db 0x08          ; ?
    .db 0x08          ; ?
    .db 0x01          ; ?

    .even
    .include "cards_util.asm"
    .even
    .include "deck_mem.asm"
    .even
    .include "deck.asm"
    .even
    .include "deck_gfx.asm"
    .even
    .include "cursor.asm"
    .even
    .include "cursor_gfx.asm"
    .even
    .include "ace_piles.asm"
    .even
    .include "sound.asm"
    .even
    .include "deal_pile.asm"

