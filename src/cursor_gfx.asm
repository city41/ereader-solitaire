    CURSOR_GFX_INITIAL_X_PX = 36
    CURSOR_GFX_INITIAL_Y_PX = 74

    CURSOR_GFX_SPAN_BETWEEN_COLUMNS_PX = 24
    CURSOR_GFX_SPAN_BETWEEN_CARDS_PX = 8

    CURSOR_GFX_DEAL_PILE_X = 36
    CURSOR_GFX_DEAL_PILE_Y = 26

    CURSOR_GFX_DEALT_PILE_X = 60
    CURSOR_GFX_DEALT_PILE_Y = 26

    CURSOR_GFX_ACE_PILE_START_X = 108
    CURSOR_GFX_ACE_PILE_Y = 26

cursor_gfx_init:
    ;; it is important to create these first
    ;; so the cursor is on top of all of them
    call _cursor_gfx_create_grabbed_card_sprites

    ; ERAPI_SpriteCreate()
    ; e  = pal#
    ; hl = sprite data
    ld  e, #0x02
    ld  hl, _cursor_gfx_sprite_cursor_grab
    rst 0
    .db ERAPI_SpriteCreate
    ld  (_cursor_gfx_sprite_cursor_grab_handle), hl

    ; ERAPI_SpriteCreate()
    ; e  = pal#
    ; hl = sprite data
    ld  e, #0x02
    ld  hl, _cursor_gfx_sprite_cursor
    rst 0
    .db ERAPI_SpriteCreate
    ld  (_cursor_gfx_sprite_cursor_handle), hl
    ld  (_cursor_gfx_sprite_cursor_current_handle), hl

    ;; auto animate the hand back and forth for a simple bob
    ;; hl = sprite handle
    ;; de = sprite frame duration in system frames
    ;; bc =
    ;; bc: 0 = Start Animating Forever
    ;;     1 = Stop Animation
    ;;     2 > Number of frames to animate for -2 (ex. 12 animates for 10 frames)
    ld de, 45
    ld bc, 0
    rst 0
    .db ERAPI_SpriteAutoAnimate
    ret

cursor_gfx_on_card_grab_canceled:
    call _cursor_gfx_hide_grabbed_card_sprites
    ret

cursor_gfx_on_grabbed_card_moved_to_ace_piles:
    call cursor_gfx_on_card_grab_canceled
    ret

cursor_gfx_render:
    call _cursor_gfx_set_cursor_sprites_based_on_grab

    ld a, (cursor_section)
    cp CURSOR_SECTION_PLAYFIELD
    call z, _cursor_gfx_render_in_playfield

    ld a, (cursor_section)
    cp CURSOR_SECTION_DEAL_PILE
    call z, _cursor_gfx_render_in_deal_pile

    ld a, (cursor_section)
    cp CURSOR_SECTION_DEALT_PILE
    call z, _cursor_gfx_render_in_dealt_pile

    ld a, (cursor_section)
    cp CURSOR_SECTION_ACE_PILES
    call z, _cursor_gfx_render_in_ace_piles
    ret

_cursor_gfx_set_cursor_sprites_based_on_grab:
    ld a, (deck_grabbed_cards)
    cp 0
    jr z, cursor_gfx_set_cursor_sprites_based_on_grab__skip_grab

    ;; there are grabbed cards, switch to grab cursor

    ;; hide the regular cursor sprite
    ; ERAPI_SpriteHide()
    ; hl = sprite data
    ld   hl, (_cursor_gfx_sprite_cursor_handle)
    rst  0
    .db  ERAPI_SpriteHide

    ;; show the grab cursor sprite
    ld   hl, (_cursor_gfx_sprite_cursor_grab_handle)
    rst  0
    .db  ERAPI_SpriteShow

    ;; set the current handle to grab
    ld (_cursor_gfx_sprite_cursor_current_handle), hl
    jr cursor_gfx_set_cursor_sprites_based_on_grab__done

    cursor_gfx_set_cursor_sprites_based_on_grab__skip_grab:

    ;; there are no grabbed cards, switch to regular cursor
    ;; hide the grab cursor sprite
    ; ERAPI_SpriteHide()
    ; hl = sprite data
    ld   hl, (_cursor_gfx_sprite_cursor_grab_handle)
    rst  0
    .db  ERAPI_SpriteHide

    ;; show the regular cursor sprite
    ld   hl, (_cursor_gfx_sprite_cursor_handle)
    rst  0
    .db  ERAPI_SpriteShow

    ;; set the current handle to regular
    ld (_cursor_gfx_sprite_cursor_current_handle), hl

    cursor_gfx_set_cursor_sprites_based_on_grab__done:
    ret

_cursor_gfx_render_in_playfield:
    ;; determine x based on cursor_playfield_col
    ld a, (cursor_playfield_col)
    ld e, CURSOR_GFX_SPAN_BETWEEN_COLUMNS_PX
    rst 8
    ;; hl=a*e
    .db ERAPI_Mul8
    ;; hl is now col*spanBetweenCols
    ld bc, CURSOR_GFX_INITIAL_X_PX
    ;; hl is now initialX + col*spanBetweenCols
    add hl, bc

    ;; hl now holds x
    push hl ; save on stack

    ;; determine y based on cursor_playfield_row
    ld a, (cursor_playfield_row)
    ld e, CURSOR_GFX_SPAN_BETWEEN_CARDS_PX
    rst 8
    ;; hl=a*e
    .db ERAPI_Mul8
    ;; hl is now cardIndex*spanBetweenCards
    ld bc, CURSOR_GFX_INITIAL_Y_PX
    ;; hl is now initialY+cardIndex*spanBetweenCards
    add hl, bc

    ;; is this column too long? then we need to push y up
    ;; to match the column being pushed up by deck_gfx
    ld a, (cursor_playfield_col)
    ld b, a
    call deck_get_final_populated_index
    ;; if this column is empty, the answer will be -1, which is really ff
    ;; which will be considered "too long", so it needs a special check
    cp -1
    jr z, _cursor_gfx_render_in_playfield__skip_y_too_long_adjusment
    cp DECK_GFX_MAX_CARDS_IN_COL_TO_FIT_NORMALLY
    jr c, _cursor_gfx_render_in_playfield__skip_y_too_long_adjusment

    ;; need to adjust y due to column being rendered starting at y=0
    ;; due to it being so long
    push hl
    ld hl, -64
    push hl
    pop bc
    pop hl
    add hl, bc

    _cursor_gfx_render_in_playfield__skip_y_too_long_adjusment:
    ;; hl now holds y
    push hl

    pop bc ; load up y
    pop de ; load up x
    ;; by using current, this could either be the regular
    ;; pointing cursor or the grab cursor
    ;; this function doesn't care
    ld hl, (_cursor_gfx_sprite_cursor_current_handle)

    ; move the cursor
    ; ERAPI_SetSpritePos()
    ; hl = handle
    ; de = x
    ; bc = y
    rst  0
    .db  ERAPI_SetSpritePos

    call _cursor_gfx_render_grabbed_cards_at_cursor
    ret

;;
;; renders the grabbed cards where the cursor is
;; if there are no grabbed cards, bails early
;;
;; parameters
;; de: cursor's x
;; bc: cursor's y
;;
_cursor_gfx_render_grabbed_cards_at_cursor:
    ; save cursor's x onto the stack
    push de
    ; save cursor's y onto the stack
    push bc
    ;; our card index
    ld a, 0

    _cursor_gfx_render_grabbed_cards_at_cursor__loop:
    ;; _cursor_gfx_render_grabbed_card needs this
    ld (_cursor_gfx_grabbed_card_render_index), a

    ld d, 0
    ld e, a
    ld hl, deck_grabbed_cards
    ;; hl is now pointed at the grabbed card we are currently working on
    add hl, de

    ;; a is about to be clobbered, so save it
    push af

    ;; pull the card's value into a
    ld a, (hl)

    ;; is the value of the card zero? then we are done
    cp 0
    jr z, _cursor_gfx_render_grabbed_cards_at_cursor__done

    ;; move the value (ie frame) into the memory parameter
    ld (_cursor_gfx_grabbed_card_render_frame), a

    ;; now to get the sprite handle
    ;; load the array's start
    ld hl, _cursor_gfx_sprite_grabbed_card_handles
    ;; index into the array, de is already what we need here
    add hl, de
    ;; add twice since handles are words
    add hl, de

    ;; load handle into bc
    ld a, (hl)
    ld c, a
    inc hl
    ld a, (hl)
    ld b, a

    ;; get our card index back
    pop af
    
    ;; copy handle over to hl
    push bc
    pop hl

    ; load y back into bc
    pop bc
    ; load x back into de
    pop de

    ; put them back on the stack, as we will need them next iteration
    push de
    push bc

    ;; have all parameters set, finally call out to render the card
    push af
    call _cursor_gfx_render_grabbed_card_at_cursor
    ;; move onto next card index
    pop af
    inc a
    jr _cursor_gfx_render_grabbed_cards_at_cursor__loop

    _cursor_gfx_render_grabbed_cards_at_cursor__done:
    pop af
    pop bc
    pop de
    ret

;; renders one grabbed card
;;
;; parameters
;; _cursor_gfx_grabbed_card_render_index: the index of the grabbed card
;; _cursor_gfx_grabbed_card_render_frame: the rank/suit of the card 
;; de: cursor's x
;; bc: cursor's y
;; hl: sprite handle
;;
;; this is not a general function, only _cursor_gfx_render_grabbed_cards_at_cursor
;; should be calling it
;;
_cursor_gfx_render_grabbed_card_at_cursor:
    ;; save the sprite handle
    push hl

    ;; move the grabbed card in lockstep with the cursor
    ;; need to offset it a bit

    ;; copy de into hl
    ex de, hl
    ld d, 0
    ld e, 6
    ;; hl = cursorX+6
    add hl, de

    ;; now save off the final x result
    push hl

    ;; figure out the y offset, it is startingY + 6 + index*8
    ld a, (_cursor_gfx_grabbed_card_render_index)
    ld e, 8
    ;; ERAPI_Mul8
    rst 8
    ;; hl = a*e
    .db ERAPI_Mul8
    ld d, 0
    ld e, 6
    add hl, de
    ;; hl is now 6 + index*8, but it needs the starting y offset

    ;; copy starting y offset into de
    push bc
    pop de

    ;; add it to hl
    ;; hl is now startingY + 6 + index*8
    add hl, de
    push hl

    pop bc ; pull y off stack into bc
    pop de ; pull x off stack into de
    pop hl ; pull sprite handle off stack

    ;; first, set the correct frame
    ld a, (_cursor_gfx_grabbed_card_render_frame)

    push de
    ld e, a
    ; ERAPI_SetSpriteFrame
    ; hl = handle
    ; e = frame
    rst 0
    .db ERAPI_SetSpriteFrame
    pop de

    ;; now set the position

    ; ERAPI_SetSpritePos()
    ; hl = handle
    ; de = x
    ; bc = y
    rst  0
    .db  ERAPI_SetSpritePos

    ;; finally, make sure the sprite is visible

    ; ERAPI_SpriteShow()
    ; hl = sprite handle
    rst  0
    .db  ERAPI_SpriteShow

    ret

_cursor_gfx_render_in_deal_pile:
    call _cursor_gfx_hide_grabbed_card_sprites

    ld hl, (_cursor_gfx_sprite_cursor_current_handle)

    ld de, CURSOR_GFX_DEAL_PILE_X
    ld bc, CURSOR_GFX_DEAL_PILE_Y

    ; move the cursor
    ; ERAPI_SetSpritePos()
    ; hl = handle
    ; de = x
    ; bc = y
    rst  0
    .db  ERAPI_SetSpritePos

    call _cursor_gfx_render_grabbed_cards_at_cursor
    ret

_cursor_gfx_render_in_dealt_pile:
    call _cursor_gfx_hide_grabbed_card_sprites


    ld de, CURSOR_GFX_DEALT_PILE_X
    ld bc, CURSOR_GFX_DEALT_PILE_Y

    ld a, (mode_chosen_mode)
    cp MODE_SINGLE
    jr z, _cursor_gfx_render_in_dealt_pile__render

    ;; this is triple mode, need to move the cursor based on how many cards have been dealt
    call deal_pile_get_second_top_dealt_card
    cp 0
    ;; only one card? we are good to go
    jr z, _cursor_gfx_render_in_dealt_pile__render

    call deal_pile_get_third_top_dealt_card
    cp 0
    jr z, _cursor_gfx_render_in_dealt_pile__two_cards
    ;; there are three cards, need to move x over
    ld h, d
    ld l, e
    ld de, 16
    add hl, de
    ld d, h
    ld e, l
    jr _cursor_gfx_render_in_dealt_pile__render



    _cursor_gfx_render_in_dealt_pile__two_cards:
    ;; there are two cards, need to move x over
    ld h, d
    ld l, e
    ld de, 8
    add hl, de
    ld d, h
    ld e, l


    _cursor_gfx_render_in_dealt_pile__render:
    ; move the cursor
    ; ERAPI_SetSpritePos()
    ; hl = handle
    ; de = x
    ; bc = y
    ld hl, (_cursor_gfx_sprite_cursor_current_handle)
    rst  0
    .db  ERAPI_SetSpritePos

    call _cursor_gfx_render_grabbed_cards_at_cursor
    ret

_cursor_gfx_render_in_ace_piles:
    ;; need to determine x, based on which ace pile we are in
    ld a, (cursor_ace_piles_col)
    ld e, CURSOR_GFX_SPAN_BETWEEN_COLUMNS_PX
    rst 8
    ;; hl=a*e
    .db ERAPI_Mul8
    ;; hl is now spanBetweenCols*col
    ld bc, CURSOR_GFX_ACE_PILE_START_X
    add hl, bc
    ;; hl is now startAceX+spanBetweenCols*col

    ;; move x into de
    push hl
    pop de
    ld bc, CURSOR_GFX_ACE_PILE_Y
    ld hl, (_cursor_gfx_sprite_cursor_current_handle)

    ; move the cursor
    ; ERAPI_SetSpritePos()
    ; hl = handle
    ; de = x
    ; bc = y
    rst  0
    .db  ERAPI_SetSpritePos

    call _cursor_gfx_render_grabbed_cards_at_cursor
    ret

;; creates 13 sprites for the grabbed cards
_cursor_gfx_create_grabbed_card_sprites:
    ld a, 0
    
    _cursor_gfx_create_grabbed_card_sprites__loop:
    ; ERAPI_SpriteCreate()
    ; e  = pal#
    ; hl = sprite data
    ld  e, #0x03
    ld  hl, _cursor_gfx_sprite_grabbed_card
    rst 0
    .db ERAPI_SpriteCreate

    ;; move the sprite handle into bc
    push hl
    pop bc

    ld hl, _cursor_gfx_sprite_grabbed_card_handles
    ld d, 0
    ld e, a
    ;; move forward into the handle array
    add hl, de
    add hl, de ; twice since the array is words
    ;; save the handle into the array
    ld (hl), c
    inc hl
    ld (hl), b
    inc a
    cp 13
    ret z
    jr _cursor_gfx_create_grabbed_card_sprites__loop

;; walks through the grabbed card sprite handles and hides them as it goes
_cursor_gfx_hide_grabbed_card_sprites:
    ;; there are 13 grabbed card sprites
    ld b, 13

    _cursor_gfx_hide_grabbed_card_sprites__loop:
    ;; get pointer to first sprite handle
    ld hl, _cursor_gfx_sprite_grabbed_card_handles
    ;; move forward to current sprite
    ld d, 0
    ld e, b
    ;; djnz requires b to be one based
    ;; but our index needs to be zero based
    dec e
    ;; hl now points at the handle we care about
    add hl, de
    ;; twice since handles are words
    add hl, de
    ;; save our counter
    push bc
    ld a, (hl)
    ld c, a
    inc hl
    ld a, (hl)
    ld b, a
    ;; bc now holds the sprite handle
    push bc
    pop hl ; move it to hl

    ;; ERAPI_SpriteHide
    ;; hl = handle to sprite
    rst 0
    .db ERAPI_SpriteHide
    pop bc
    djnz _cursor_gfx_hide_grabbed_card_sprites__loop
    ret

    .even
_cursor_gfx_tiles_cursor:
    .include "cursor.tiles.asm"

    .even
_cursor_gfx_tiles_cursor_grab:
    .include "cursor_grab.tiles.asm"

    .even
_cursor_gfx_sprite_cursor:
    .dw _cursor_gfx_tiles_cursor  ; tiles
    .dw palette_deck; palette
    .db 0x02          ; width
    .db 0x02          ; height
    .db 0x02          ; frames
    .db 0x02          ; ?
    .db 0x08          ; ?
    .db 0x08          ; ?
    .db 0x02          ; ?

    .even
_cursor_gfx_sprite_cursor_grab:
    .dw _cursor_gfx_tiles_cursor_grab  ; tiles
    .dw palette_deck; palette
    .db 0x02          ; width
    .db 0x02          ; height
    .db 0x01          ; frames
    .db 0x01          ; ?
    .db 0x08          ; ?
    .db 0x08          ; ?
    .db 0x01          ; ?

    .even
_cursor_gfx_sprite_grabbed_card:
    .dw tiles_deck  ; tiles
    .dw palette_deck; palette
    .db 0x02          ; width
    .db 0x03          ; height
    .db 61          ; frames
    .db 61          ; ?
    .db 0x08          ; ?
    .db 0x08          ; ?
    .db 61         ; ?

    .even
_cursor_gfx_sprite_cursor_handle:
    .ds 2
_cursor_gfx_sprite_cursor_grab_handle:
    .ds 2
;; this will be either cursor or cursor_gfx_grab's
;; handle, depending on if the user has grabbed a card or not
;; that way cursor_gfx_move_sprites can just blindly move them
_cursor_gfx_sprite_cursor_current_handle:
    .ds 2
_cursor_gfx_sprite_grabbed_card_handles:
    ;; at most you can grab 13 cards at once
    .ds (2*13)
;; used by the render grabbed card functions
_cursor_gfx_grabbed_card_render_index:
    .ds 1
_cursor_gfx_grabbed_card_render_frame:
    .ds 1