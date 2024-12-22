;; deck_gfx
;; --------
;; all graphical related operations for the deck/cards

    DECK_GFX_BG = 1

    ; this is in tiles, not pixels
    DECK_GFX_PLAYFIELD_COLUMN_START_X = 5
    DECK_GFX_PLAYFIELD_COLUMN_START_Y = 8
    DECK_GFX_PLAYFIELD_LONG_FOCUSED_COLUMN_START_Y = 0
    ;; cards are two tiles wide
    DECK_GFX_CARD_WIDTH = 2
    ;; there is one tile between columns
    DECK_GFX_COLUMN_SPACING = 1
    DECK_GFX_COLUMN_SPAN = DECK_GFX_CARD_WIDTH + DECK_GFX_COLUMN_SPACING

    ;; position these just above the last four columns
    DECK_GFX_ACE_PILES_COLUMN_LEFT_X = DECK_GFX_PLAYFIELD_COLUMN_START_X + 9
    DECK_GFX_ACE_PILES_COLUMN_RIGHT_X = DECK_GFX_ACE_PILES_COLUMN_LEFT_X + DECK_GFX_COLUMN_SPAN * 3
    DECK_GFX_ACE_PILES_COLUMN_START_Y = 2

    DECK_GFX_DEAL_PILE_X = DECK_GFX_PLAYFIELD_COLUMN_START_X
    DECK_GFX_DEAL_PILE_Y = DECK_GFX_ACE_PILES_COLUMN_START_Y
    DECK_GFX_DEALT_PILE_X = DECK_GFX_DEAL_PILE_X + DECK_GFX_COLUMN_SPACING + DECK_GFX_CARD_WIDTH
    DECK_GFX_DEALT_PILE_Y = DECK_GFX_DEAL_PILE_Y

    DECK_GFX_BACK_CARD_FRAME = 53
    DECK_GFX_EMPTY_PILE_FRAME = 54
    DECK_GFX_DOTDOTDOT_FRAME = 55
    DECK_GFX_EMPTY_DIAMOND_PILE_FRAME = 56
    DECK_GFX_EMPTY_CLUB_PILE_FRAME = 57
    DECK_GFX_EMPTY_HEART_PILE_FRAME = 58
    DECK_GFX_EMPTY_SPADE_PILE_FRAME = 59
    DECK_GFX_EMPTY_DEAL_PILE_REFILL_FRAME = 60

    DECK_GFX_MAX_CARDS_IN_COL_TO_FIT_NORMALLY=10

;; this is just a regular render but with forced empty
;; deal and dealt piles. this is used during the intro
deck_gfx_render_with_empty_deal_dealt:
    call _deck_gfx_render_empty_deal_and_dealt_piles
    call _deck_gfx_render_ace_piles
    call _deck_gfx_render_playfield

    ; ERAPI_LoadCustomBackground()
    ; a  = bg#(0-3)
    ; de = pointer to backround struct
    ld  a, DECK_GFX_BG
    ld  de, deck_gfx_background
    rst 0
    .db ERAPI_LoadCustomBackground

    ret

deck_gfx_render:
    call _deck_gfx_clear
    call _deck_gfx_render_ace_piles
    call _deck_gfx_render_deal_pile
    ;; this needs to be last in case of a focused long column
    call _deck_gfx_render_playfield

    ; ERAPI_LoadCustomBackground()
    ; a  = bg#(0-3)
    ; de = pointer to backround struct
    ld  a, DECK_GFX_BG
    ld  de, deck_gfx_background
    rst 0
    .db ERAPI_LoadCustomBackground

    ret

_deck_gfx_render_ace_piles:
    ;; since b decrements, this function will render from right to left
    ld b, 4
    ld hl, DECK_GFX_ACE_PILES_COLUMN_RIGHT_X
    ld de, -DECK_GFX_COLUMN_SPAN

    ld a, DECK_GFX_ACE_PILES_COLUMN_START_Y
    ld (_deck_gfx_cur_card_y), a

    _deck_gfx_render_ace_piles__loop:
    ld a, b
    dec a ; b is one based, the index is zero based
    ;; the ace pile's card is now in a
    call ace_piles_get_card
    cp 0
    jr nz, _deck_gfx_render_ace_piles__skip_adjust_to_empty_frame
    ;; this pile is currently empty, render the correct ace pile empty frame
    ld a, DECK_GFX_EMPTY_SPADE_PILE_FRAME
    ;; since b is one based, need to bump up by one
    inc a
    sub a, b
    _deck_gfx_render_ace_piles__skip_adjust_to_empty_frame:
    ld (_deck_gfx_cur_card_frame), a

    ld a, l
    ld (_deck_gfx_cur_column_x), a

    push bc
    push hl
    push de
    call _deck_gfx_render_card
    pop de
    pop hl
    pop bc

    add hl, de

    djnz _deck_gfx_render_ace_piles__loop

    ret

_deck_gfx_render_empty_deal_and_dealt_piles:
    ;; empty deal pile
    ld a, DECK_GFX_DEAL_PILE_X
    ld (_deck_gfx_cur_column_x), a
    ld a, DECK_GFX_DEAL_PILE_Y
    ld (_deck_gfx_cur_card_y), a
    ld a, DECK_GFX_EMPTY_PILE_FRAME
    ld (_deck_gfx_cur_card_frame), a
    call _deck_gfx_render_card

    ;; empty dealt pile
    ld a, DECK_GFX_DEALT_PILE_X
    ld (_deck_gfx_cur_column_x), a
    ld a, DECK_GFX_DEALT_PILE_Y
    ld (_deck_gfx_cur_card_y), a
    ld a, DECK_GFX_EMPTY_PILE_FRAME
    ld (_deck_gfx_cur_card_frame), a
    call _deck_gfx_render_card

    ret

_deck_gfx_render_deal_pile:
    ld a, DECK_GFX_DEAL_PILE_X
    ld (_deck_gfx_cur_column_x), a
    ld a, DECK_GFX_DEAL_PILE_Y
    ld (_deck_gfx_cur_card_y), a

    ld a, (_deal_pile_deal_pile_i)
    ;; -1 means the deal pile is empty
    cp -1
    jr nz, _deck_gfx_render_deal_pile__skip_deal_empty
    ld a, DECK_GFX_EMPTY_DEAL_PILE_REFILL_FRAME
    jr _deck_gfx_render_deal_pile__deal_done
    _deck_gfx_render_deal_pile__skip_deal_empty:
    ld a, DECK_GFX_BACK_CARD_FRAME
    _deck_gfx_render_deal_pile__deal_done:
    ld (_deck_gfx_cur_card_frame), a

    call _deck_gfx_render_card

    ;; the dealt pile
    ld a, DECK_GFX_DEALT_PILE_X
    ld (_deck_gfx_cur_column_x), a
    ld a, DECK_GFX_DEALT_PILE_Y
    ld (_deck_gfx_cur_card_y), a

    ;; ok now for the frame
    ;; if a card has been dealt, then that's the frame
    ld a, (deal_pile_top_dealt_card)
    ;; if a card has not been dealt, we need to use the empty frame
    cp a, 0
    jr nz, _deck_gfx_render_deal_pile__skip_dealt_empty
    ld a, DECK_GFX_EMPTY_PILE_FRAME

    _deck_gfx_render_deal_pile__skip_dealt_empty:
    ld (_deck_gfx_cur_card_frame), a

    call _deck_gfx_render_card

    ret



_deck_gfx_render_playfield:
    ;; using c to index into the columns pointer array
    ld b, 0
    ld c, 0

    deck_gfx_render__loop:
    ld hl, deck_mem_columns
    add hl, bc

    ;; load the column pointer into de
    ld e, (hl)
    inc hl
    ld d, (hl)

    ;; check to see if the pointer is null
    ld a, e
    ;; if both d and e are zero, this will result in zero
    or d
    ;; if we hit zero, we are done
    ret z

    ;; move the pointer into our variable so other 
    ;; functions can use it
    ld h, d
    ld l, e
    ld (_deck_gfx_cur_column_addr), hl

    ;; ok now need to setup x
    push bc ; save c, our pointer counter
    ld a, c
    ;; c is incrementing by 2 due to addresses being words
    ;; so shift a down one bit to divide by 2
    rra
    ;; a is now the current column index, save it
    ld (_deck_gfx_cur_column_index), a
    ld bc, DECK_GFX_COLUMN_SPAN
    ld hl, DECK_GFX_PLAYFIELD_COLUMN_START_X

    deck_gfx_render__multiply_x:
    cp 0 ; is a, our x mulitiplier, done?
    ;; if a is zero, then we are done multiplying for x
    jr z, deck_gfx_render__done_multiplying_for_x

    ; add on one more offset for x
    ; ultimately hl will be startingOffset + c * 3
    add hl, bc
    dec a
    jr deck_gfx_render__multiply_x

    deck_gfx_render__done_multiplying_for_x:
    ;; at this point hl is our x value
    ;; push it in memory so render_column can grab it
    ld a, l
    ld (_deck_gfx_cur_column_x), a

    call _deck_gfx_render_column
    pop bc

    ;; move to the next word in our column pointers list
    inc c
    inc c

    jr deck_gfx_render__loop
    ret

;; renders one column of cards
;; 
;; _deck_gfx_cur_column: the column index to render, 0-6
;; _deck_gfx_cur_column_x: the x location, in tiles, for this column
;; 
;; TODO: if the column is focused and too long, render it starting at y=0
_deck_gfx_render_column:
    ;; this is the maximum number of cards we will render
    ld b, DECK_MEM_MAX_CARDS_PER_COLUMN
    ;; our card counter, used to get a pointer
    ;; to each card in the column
    ;; gets inc'd by 1 each loop
    ld c, 0

    deck_gfx_render_column__loop:
    ld hl, (_deck_gfx_cur_column_addr)  ; point hl to start of column
    ld d, 0                ; get de loaded with current offset
    ld e, c                ; get de loaded with current offset
    add hl, de             ; move hl foward to current card address
    ld a, (hl)             ; pull the byte of current card into a

    ;; is the frame zero? then this isn't a card, time to bail
    cp 0
    jr z, _deck_gfx_render_column__done

    ;; ok but is this a flipped over card?
    push bc    ; save our counters
    ;; clean out the entire byte except for the top bit
    ld c, a    ; need to save off a
    ld b, a
    ld a, 0x80 
    and b
    ld a, c
    ;; now if the and result was zero, the card is *not* flipped over
    ;; that also means the card is already its frame, as the flipped over bit
    ;; is zero, so it won't muck with the value
    jr z, deck_gfx_render_column__skip_flipping_card_over
    ;; ok this is a flipped over card, so use back of card frame
    ld a, DECK_GFX_BACK_CARD_FRAME

    deck_gfx_render_column__skip_flipping_card_over:

    ld (_deck_gfx_cur_card_frame), a

    ;; now to figure out y
    pop bc

    ;; loads into a the starting column y depending on this column's state
    ;; is it long? is it focused? 
    call _deck_gfx_determine_column_y
    ;; add onto a our current card index, to get to the final correct y
    add a, c

    ; at this point a is our y value
    ld (_deck_gfx_cur_card_y), a


    ;; at this point, we have
    ;; x in _deck_gfx_cur_column_x
    ;; y in _deck_gfx_cur_card_y
    ;; frame in _deck_gfx_cur_card_frame
    push bc

    call _deck_gfx_render_card

    pop bc

    ; move to next card
    inc c
    ; go do it again, unless we've hit the max card limit
    djnz deck_gfx_render_column__loop

    _deck_gfx_render_column__done:
    ;; we are done rendering the column. was it too long?
    ld a, b
    cp 9
    ret nc

    ;; ok this column was too long, do the dotdotdot
    call _deck_gfx_render_dotdotdot
    ret

;; determines y for a card column based on:
;; - is the column focused?
;; - is the column too long to fit on the screen?
;;   -- if yes to both, pushes the column up higher
;;   -- otherwise, regular starting y
_deck_gfx_determine_column_y:
    push bc

    ;; if they are not in the playfield, no column needs to bump up
    ld a, (cursor_section)
    cp CURSOR_SECTION_PLAYFIELD
    jr nz, _deck_gfx_determine_column_y__regular_y

    ;; first is this the focused column?
    ;; get cur rendering column and cur focused column indexes
    ;; into b and a to perform a comparison
    ld c, a
    ld a, (cursor_playfield_col)
    ld b, a
    ld a, (_deck_gfx_cur_column_index)
    cp b
    ;; not focused? just regular y then
    jr nz, _deck_gfx_determine_column_y__regular_y

    ;; ok this column is focused. Is it soo long it needs the bump?
    ld b, a
    call deck_get_final_populated_index
    cp DECK_GFX_MAX_CARDS_IN_COL_TO_FIT_NORMALLY
    ;; not too long? just regular y then
    jr c, _deck_gfx_determine_column_y__regular_y

    ;; ok it's too long and focused, need to bump it up
    ld a, DECK_GFX_PLAYFIELD_LONG_FOCUSED_COLUMN_START_Y
    jr _deck_gfx_determine_column_y__done

    _deck_gfx_determine_column_y__regular_y:
    ld a, DECK_GFX_PLAYFIELD_COLUMN_START_Y

    _deck_gfx_determine_column_y__done:
    pop bc
    ret

;; if the column is not the current focus and is too long
;; this will add a '...'
_deck_gfx_render_dotdotdot:
    ld a, (cursor_section)
    cp CURSOR_SECTION_PLAYFIELD
    jr nz, _deck_gfx_render_dotdotdot__not_in_playfield

    ld a, (_deck_gfx_cur_column_index)
    ld b, a
    ld a, (cursor_playfield_col)
    cp b
    ;; if this column is currently focused, bail
    jr z, _deck_gfx_render_dotdotdot__done

    _deck_gfx_render_dotdotdot__not_in_playfield:
    ;; ok the column is too long and not focused, add the dotdotdot

    ;; first render the dotdotdot at the second to last card spot on the screen
    ;; _deck_gfx_cur_column_x is already figured out
    ;; y is just hardcoded to bottom of screen
    ld a, 16
    ld (_deck_gfx_cur_card_y), a
    ld a, DECK_GFX_DOTDOTDOT_FRAME
    ld (_deck_gfx_cur_card_frame), a

    call _deck_gfx_render_card

    ;; get the card value for its frame
    ;; params, b=col, which it already is
    ld a, (_deck_gfx_cur_column_index)
    ld b, a
    call deck_get_final_populated_index
    ld c, a
    call deck_get_card
    ld (_deck_gfx_cur_card_frame), a

    ;; _deck_gfx_cur_column_x is already figured out
    ;; y is just hardcoded to bottom of screen
    ld a, 17
    ld (_deck_gfx_cur_card_y), a

    call _deck_gfx_render_card

    ;; then the final card in the row
    ;; TODO

    _deck_gfx_render_dotdotdot__done:
    ret

; to draw one card, c, at x,y
; hl = map_deck + (y * 64) + (x*2)

; // starting tile
; ti = c *6
; // first row
; *hl = ti++
;  hl += 2
; *hl = ti++
; // move to second row
; hl += 62
; // second row
; *hl = ti++
;  hl += 2
; *hl = ti++
; // move to third row
; hl += 62
; // third row
; *hl = ti++
;  hl += 2
; *hl = ti

;; renders one card into the map
;;
;; parameters
;; x (in tiles): _deck_gfx_cur_column_x
;; y (in tiles): _deck_gfx_cur_card_y
;; frame       : _deck_gfx_cur_card_frame
_deck_gfx_render_card:
    ;; get the starting tile index
    ;; which is frame * 6
    ld a, (_deck_gfx_cur_card_frame)
    ;; hl = frame
    ld h, 0
    ld l, a
    ld de, 6
    rst 8
    ;; hl = hl*de
    .db ERAPI_Mul16

    ;; the starting tile index is now in hl
    ;; move it to de
    ld d, h
    ld e, l

    ;; get the starting pointer
    ;; hl = map_deck + (y * 64) + (x*2)
    push de
    ld de, 64
    ld a, (_deck_gfx_cur_card_y)
    ld h, 0
    ld l, a
    rst 8
    ;; hl = hl*de
    .db ERAPI_Mul16
    ;; hl is now the starting y value
    ;; now add on the x
    ld a, (_deck_gfx_cur_column_x)
    ;; de = x
    ld d, 0
    ld e, a
    ;; hl += x*2
    add hl, de
    add hl, de

    ;; de = hl
    ld d, h
    ld e, l
    ld hl, map_deck
    ;; hl is finally pointed at the first tile address
    add hl, de

    ;; we'll use this to move the hl pointer 30 tiles
    ;; forward to get to the next row in the map
    ld bc, 60

    ;; now drop the tiles into the map
    pop de ;; restore the starting tile index
    ;; first row
    ld (hl), e
    inc hl
    ld (hl), d
    inc hl
    inc de ; move to next tile
    ld (hl), e
    inc hl
    ld (hl), d
    inc hl
    inc de ; move to next tile
    ;; move to the right spot in the next row
    add hl, bc
    ;; second row
    ld (hl), e
    inc hl
    ld (hl), d
    inc hl
    inc de ; move to next tile
    ld (hl), e
    inc hl
    ld (hl), d
    inc hl
    inc de ; move to next tile
    ;; move to the right spot in the next row
    add hl, bc
    ;; third row
    ld (hl), e
    inc hl
    ld (hl), d
    inc hl
    inc de ;move to next tile
    ld (hl), e
    inc hl
    ld (hl), d

    ;; phew!
    ret

_deck_gfx_clear:
    ld hl, map_deck
    ;; unrolling the loop
    ;; clearing 10 bytes per iteration
    ld a, 128

    _deck_gfx_clear__loop:
    ld (hl), 0
    inc hl
    ld (hl), 0
    inc hl
    ld (hl), 0
    inc hl
    ld (hl), 0
    inc hl
    ld (hl), 0
    inc hl
    ld (hl), 0
    inc hl
    ld (hl), 0
    inc hl
    ld (hl), 0
    inc hl
    ld (hl), 0
    inc hl
    ld (hl), 0
    inc hl
    
    dec a
    cp 0
    jp nz, _deck_gfx_clear__loop
    ret

    .even
tiles_deck:
    .include "deck.tiles.asm"
tiles_deck_end:
    tiles_deck_size = (tiles_deck_end - tiles_deck)

    .even
palette_deck:
    .include "deck.palette.asm"
palette_deck_end:
    palette_deck_size = (palette_deck_end - palette_deck)

deck_gfx_background:
    .dw tiles_deck
    .dw palette_deck
    .dw map_deck
    .dw (tiles_deck_size / 0x20)   ; number of tiles
    .dw (palette_deck_size / 0x20) ; number of palettes

    .even
map_deck:
    .ds 2048
_deck_gfx_cur_column_index:
    .ds 1
_deck_gfx_cur_column_addr:
    .ds 2
_deck_gfx_cur_column_x:
    .ds 1
_deck_gfx_cur_card_frame:
    .ds 1
_deck_gfx_cur_card_y:
    .ds 1