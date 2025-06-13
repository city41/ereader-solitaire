;; inspects the columns looking for a back card
;; if one is found, a=1, else a=0
;;
deck_is_there_a_back_card:
    ;; going to cheat and keep this simple, start at deck_mem_column_1
    ;; and just plow through, it means looking at a lot of zeros but that is fine

    ;; NOTE: we are starting at column 1 as a tiny optimization. column 0
    ;; can never have a back card in it

    ;; there are 120 bytes dedicated to the columns if you don't include column 0
    ;; (20 bytes per column)
    ld b, 120
    ld hl, deck_mem_column_1

    deck_is_there_a_back_card__loop:
    ld a, (hl)
    cp 0x80
    ;; is a >= 0x80, then it is a back card
    jr nc, deck_is_there_a_back_card__found_back_card
    ;; a is < 0x80, either not a card or a front card
    inc hl
    djnz deck_is_there_a_back_card__loop

    ;; we have examined all cards and didn't find a back card
    ld a, 0
    ret

    deck_is_there_a_back_card__found_back_card:
    ld a, 1
    ret


deck_deal_deck:
    .ifndef DEBUG
        call _deck_shuffle
    .endif

    ld d, 0
    ld e, 0
    ld b, 0
    ld c, 0

    _deck_deal_deck__row_loop:
    ld a, d
    ;; if we are on the seventh row we are done
    cp 7
    ret z

    ;; move to the start of the current row
    ;; this will do for b and c -> (0,0) then (1,1), (2,2)...
    ld a, b
    add d
    ;; move b forward
    ld b, a
    ld a, c
    add d
    ;; move c forward
    ld c, a

    _deck_deal_deck__col_loop:
    ;; load the current card into a
    ld hl, deck_mem_deck
    push de
    ld d, 0
    ;; e already is set to the proper card index
    ;; move the deck pointer forward e cards
    add hl, de
    pop de

    ld a, (hl)

    ;; now we probably need to flip the card
    ;; we don't flip the card if b == c

    push de
    ld e, a
    ld a, b
    cp c
    ld a, e
    pop de
    jr z, _deck_deal_deck__skip_flip
    add 0x80

    _deck_deal_deck__skip_flip:
    call _deck_deal_card

    push af
    push bc
    push de
    call deck_gfx_render_with_empty_deal_dealt
    ld a, 1
    halt
    pop de
    pop bc
    pop af

    inc b
    inc e
    ld a, b
    cp 7
    jr nz, _deck_deal_deck__col_loop
    ;; row is done, move onto next row
    inc d
    ld b, 0
    ld c, 0
    jr _deck_deal_deck__row_loop
    ;; no ret, the ret z above is the only exit

;;
;; places one card in the playfield
;;
;; parameters
;; a: card
;; b: col
;; c: row
;;
_deck_deal_card:
    push de
    push af
    ld a, b
    call deck_mem_get_pointer_to_column
    ld d, 0
    ld e, c
    add hl, de
    pop af
    ld (hl), a
    pop de

    ret

;; for a given column, gives the last index that
;; has a card in it. 
;;
;;
;; parameters
;; b: col
;; returns
;; a: final populated index, or -1 if column is empty
deck_get_final_populated_index:
    push bc
    push hl
    ;; move col into a
    ld a, b
    ;; get the pointer to that column
    call deck_mem_get_pointer_to_column
    ld b, 0

    deck_get_final_populated_index__loop:
    ld a, (hl)
    cp 0
    jr z, deck_get_final_populated_index__found
    ;; there is a card here, keep going
    inc hl
    inc b
    jr deck_get_final_populated_index__loop

    deck_get_final_populated_index__found:
    ;; we have gone off the end of the column
    ;; head back one and that is our answer
    ;; this will be -1 if the column is empty, and that is ok
    dec b
    ld a, b

    pop hl
    pop bc
    ret

;; loads the card at col/row into a, non destructive
;;
;; NOTE: this is not grabbing (see deck_grab_cards)
;; this is simply getting the card's value
;;
;; parameters
;; b: col
;; c: row
deck_get_card: 
    push bc
    push hl

    ;; move col into a
    ld a, b
    ;; get the pointer to that column
    call deck_mem_get_pointer_to_column

    ;; move into the column based on row
    ld b, 0
    ;; c is already all set
    ;; move pointer forward to correct card
    add hl, bc
    ;; load the card
    ld a, (hl)

    pop hl
    pop bc
    ret

;; sets the card at col/row to zero
;; effectively truncating that column from that point on
;;
;; parameters
;; b: col
;; c: row
deck_empty_column_at:
    ;; move col into a
    ld a, b
    ;; get the pointer to that column
    call deck_mem_get_pointer_to_column

    ;; move into the column based on row
    ld b, 0
    ;; c is already all set
    ;; move pointer forward to correct card
    add hl, bc
    ;; clear the card
    ld a, 0
    ld (hl), a

    ;; now make sure the card just above this is front
    dec hl
    ld a, (hl)
    call cards_util_turn_card_to_front
    ld (hl), a

    ret

;; Places deck_grabbed_cards in col
;;
;; parameters
;; b: col
deck_drop_grabbed_cards_in_column:
    call _deck_is_legal_column_drop
    ;; a=1 if legal, 0 if not
    cp 1
    jr z, _deck_drop_grabbed_cards_in_column__is_legal
    ;; this is not a legal drop
    ;; play error and bail
    call sound_play_error_sfx
    ret

    _deck_drop_grabbed_cards_in_column__is_legal:
    call sound_play_column_drop_sfx

    ld a, b
    ;; load column pointer into hl
    call deck_mem_get_pointer_to_column

    ;; look for the end of the column
    drop_grabbed_cards_in_column__loop:
    ld a, (hl)
    cp 0
    jr z, drop_grabbed_cards_in_column__found_end
    inc hl
    jr drop_grabbed_cards_in_column__loop

    drop_grabbed_cards_in_column__found_end:
    ;; at this point, hl points to where we should start placing the cards

    ;; using this to index into the two arrays
    ld de, 0

    deck_drop_grabbed_cards_in_column__loop:
    ;; load up the grabbed card
    ;; save the column pointer
    push hl
    ld hl, deck_grabbed_cards
    ;; index into the array, ie deck_grabbed_cards[de]
    add hl, de
    ;; load the grabbed card into a
    ld a, (hl)

    ;; if it is zero, there are no more grabbed cards
    cp 0
    jr z, deck_drop_grabbed_cards_in_column__done

    ;; stick it in the column
    ;; get the column pointer back into hl
    pop hl
    ;; and save it again, we still need it
    push hl
    ;; move forward in the column
    add hl, de
    ;; move the grabbed card into the column
    ld (hl), a
    ;; move to next card index
    inc de
    ;; restore the original column pointer
    pop hl
    jr deck_drop_grabbed_cards_in_column__loop

    deck_drop_grabbed_cards_in_column__done:
    ;; clean up the stack
    pop hl
    ;; move to the end of the column
    add hl, de
    ;; null terminate it, just in case
    ld (hl), 0

    ;; wipe out the first grabbed card, which effectively truncates the list
    ld hl, deck_grabbed_cards
    ld (hl), 0
    ;; and the second card too, as cursor sometimes looks at the second card to see if
    ;; only one card is grabbed for ace pile drops
    inc hl
    ld (hl), 0

    ;; if the cards were dropped back onto the same column it came from
    ;; then we are done
    ld a, (_deck_grabbed_col)
    cp b
    ret z

    ;; if the cards came from the dealt pile, we are done
    ld a, (_game_grabbed_source)
    cp GAME_GRAB_SOURCE_DEALT_PILE
    ret z

    ;; now make sure the end of the column the grabbed
    ;; cards came from has a front card
    ;; get the grabbed column 
    ld a, (_deck_grabbed_col)
    ;; get the pointer to that column
    call deck_mem_get_pointer_to_column
    ;; index into the grabbed row
    ld b, 0
    ld a, (_deck_grabbed_row)
    ld c, a
    add hl, bc
    ;; the grabbed row is one too far
    dec hl
    ;; load the card
    ld a, (hl)
    ;; ensure it is facing front
    call cards_util_turn_card_to_front
    ;; and put it back
    ld (hl), a

    ret

;; Checks if the grabbed cards can legally
;; be dropped into col
;;
;; parameters
;; b: col
;;
;; returns
;; a: 0 if not legal, 1 if legal
_deck_is_legal_column_drop:
    ;; first is the drop column same as the grab column?
    ;; if it is, then it's always legal. it's effectively a manual cancel

    ;; this is only true if the grab came from a column
    ;; if it was a dealt pile grab, this is never true
    ld a, (_game_grabbed_source)
    cp GAME_GRAB_SOURCE_DEALT_PILE
    jr z, _deck_is_legal_column_drop__skip_cancel

    ;; ok this was a grab from the columns, let's see if it's
    ;; a manual cancel

    ld a, (_deck_grabbed_col)
    ;; b is the drop col
    cp b
    jr nz, _deck_is_legal_column_drop__skip_cancel
    ;; ok this was a cancel, it's ok
    ld a, 1
    ret

    _deck_is_legal_column_drop__skip_cancel:
    ld a, b

    ;; get the last populated row index into a
    call deck_get_final_populated_index
    ;; if -1 was returned, the column is empty
    cp -1
    jr nz, _deck_is_legal_column_drop__skip_king_check
    ;; if the column was empty, then this drop is only legal
    ;; if the top grabbed card is a king
    ld a, (deck_grabbed_cards)
    call cards_util_get_rank
    cp 13
    jr nz, _deck_is_legal_column_drop__empty_column_but_no_king
    ;; this is a king, and empty column, we have a match
    ld a, 1
    ret
    _deck_is_legal_column_drop__empty_column_but_no_king:
    ;; this is not a king, we have a mismatch
    ld a, 0
    ret

    _deck_is_legal_column_drop__skip_king_check:
    ;; if we get here, then the column was not empty
    ;; the final populated row index is still in a
    push bc
    ld c, a
    ld a, b
    ;; get the tail card of the column
    ;; params, b=col, c=row
    call deck_get_card
    ;; convert from raw value to rank
    call cards_util_get_rank
    ld b, a ; move it to b
    ld a, (deck_grabbed_cards)
    ;; convert the other card from raw value to rank
    call cards_util_get_rank
    ;; a = a - b
    ;; a needs to be exactly one less than b, otherwise illegal
    sub b
    cp -1
    pop bc
    jr z, _deck_is_legal_column_drop__rank_is_ok
    ;; rank is not ok, the tail of the column is not 1 higher than the head
    ;; of the grabbed cards
    ld a, 0
    ret

    _deck_is_legal_column_drop__rank_is_ok:
    ;; ok this drop is legal, rank wise, what about suit?
    push bc
    ;; need to get the final index again
    ;; move column into a
    ld a, b
    call deck_get_final_populated_index
    ;; a is now the final row, move it to c
    ld c, a
    ;; get the tail card of the column
    ;; params, b=col, c=row
    call deck_get_card
    ;; convert from raw value to suit
    call cards_util_get_suit
    ld b, a ; move it to b
    ld a, (deck_grabbed_cards)
    ;; convert the other card from raw value to suit
    call cards_util_get_suit
    ;; now add the suits together
    add b
    ;; if the result is odd, then the two suits were opposite colors
    and 0x1
    jr z, _deck_is_legal_column_drop__suits_were_same_color
    ;; these are opposite colored suits, we are good
    ld a, 1
    jr _deck_is_legal_column_drop__done
    _deck_is_legal_column_drop__suits_were_same_color:
    ;; doh, same color suits, no good
    ld a, 0

    _deck_is_legal_column_drop__done:
    pop bc
    ret

;; grabs the cards starting at col/row
;; places them into deck_grabbed_cards
;; and zeroes them out in the column
;; b: column
;; c: row
deck_grab_cards:
    ;; save where the card was grabbed from in case of cancel
    ld a, b
    ld (_deck_grabbed_col), a
    ld a, c ; copy row into a so we can save it
    ;; save where the card was grabbed from in case of cancel
    ld (_deck_grabbed_row), a

    ;; restore the column
    ld a, (_deck_grabbed_col)

    ;; pull the column pointer into hl
    call deck_mem_get_pointer_to_column

    ; at this point
    ; a = column
    ; c = row

    ; need to get row into bc for indexing into the column
    ld b, 0 
    ;; c is already row
    ;; now bc is the row

    ;; move forward to the card the cursor is pointing at
    add hl, bc

    ;; de will be used to move our array pointers forward
    ld de, 0

    _deck_grab_cards__loop:
    push hl ; save the starting column pointer
    ;; move forward into the column
    add hl, de
    ;; load the card into a
    ld a, (hl)

    ;; if the value is zero that's it, no more cards
    cp 0
    jr z, _deck_grab_cards__done

    ;; remove the card from the column
    ld (hl), 0
    ;; now go to the other array
    ld hl, deck_grabbed_cards
    ;; move forward into that array
    add hl, de
    ;; store the grabbed card into deck_grabbed_cards[de]
    ld (hl), a
    ;; go back to the column
    pop hl 
    inc de
    jr _deck_grab_cards__loop

    _deck_grab_cards__done:
    pop hl ; need to clean up the stack
    ;; need to null terminate deck_grabbed_cards
    ld hl, deck_grabbed_cards
    add hl, de
    ld (hl), 0
    ret

;; Undoes a grab. Returns all cards that were in the grab
;; to the column they came from.
deck_cancel_grab:
    ;; get the pointer to the column the card was
    ;; grabbed from
    ld a, (_deck_grabbed_col)
    ld b, a
    ;; just put the cards back, easy peasy
    call deck_drop_grabbed_cards_in_column
    ret

deck_on_grabbed_card_moved_to_ace_piles:
    ;; clear out the grabbed card
    ld a, 0
    ld (deck_grabbed_cards), a

    ;; was the grab source the playfield? then we need to flip a card
    ld a, (_game_grabbed_source)
    cp GAME_GRAB_SOURCE_DEALT_PILE
    ;; it came from the dealt pile, nothing to flip, bail
    ret z

    ;; now a back card is exposed, flip it
    ld a, (_deck_grabbed_col)

    ;; get a pointer to the exposed card
    call deck_mem_get_pointer_to_column
    ;; now check if the column is empty, if so, nothing to flip
    ld a, (hl)
    cp 0
    ret z

    ld a, (_deck_grabbed_row)
    ld b, 0
    ld c, a
    add hl, bc
    ;; this is actually pointing one past because
    ;; we track the location of the grabbed card
    dec hl

    ;; load the exposed card
    ld a, (hl)
    ;; flip it over
    call cards_util_turn_card_to_front
    ;; and put back
    ld (hl), a

    ret

;; adds a card to a column
;;
;; a = the card to add
;; hl = pointer to column
_deck_place_card_in_column:
    ;; move the card over to b
    ld b, a


    _deck_place_card_in_column__loop:
    ld a, (hl)
    cp 0
    jr z, _deck_place_card_in_column__found_end
    inc hl
    jr _deck_place_card_in_column__loop

    _deck_place_card_in_column__found_end:
    ;; hl now points to the end of the column
    ;; just stick the card there
    ld a, b
    ;; make sure it is turned front
    call cards_util_turn_card_to_front
    ld (hl), a

    ret

_deck_shuffle:
    ld b, 100

    _deck_shuffle__loop:
    ld a, 52
    rst 8
    .db ERAPI_RandMax
    ld d, a

    ld a, 52
    rst 8
    .db ERAPI_RandMax
    ld e, a

    ;; one card index is in d, other in e

    call _deck_swap_card_bytes

    djnz _deck_shuffle__loop
    ret


;; swaps two bytes in memory, offset off deck_mem_deck
;; d = an offset into deck_deck
;; e = an offset into deck_deck
;;
;; this results in
;; tmp = deck_deck[d]
;; deck_deck[d] = deck_deck[b]
;; deck_deck[b] = tmp
_deck_swap_card_bytes:
    ; get hl pointed to one index
    push bc
    push de
    push de
    ld b, 0
    ld c, d
    ld hl, deck_mem_deck
    add hl, bc

    ; pull the byte pointed to by d, into d
    ld d, (hl)

    ; get hl pointed at the other index
    ld b, 0
    ld c, e
    ld hl, deck_mem_deck
    add hl, bc

    ; pull the byte pointed to by e, into e
    ld e, (hl)

    ; pop the original values for de into bc
    pop bc ; bc <- original de

    ; get hl pointed at d again
    ld a, b ; d is now in b
    ld b, 0
    ld c, a ; d is now in c
    ld hl, deck_mem_deck
    add hl, bc ; hl now points at d again
    ld (hl), e ; move the e value into d

    ; do it again for the other one
    pop bc  ; bc <- original de
    ld b, 0 ; clear out b, so now c is e
    ld hl, deck_mem_deck
    add hl, bc ; hl now points at e again
    ld (hl), d ; move the d value into e

    pop bc
    ret

    .even
_deck_cur_deck_index:
    .dw 0
_deck_grabbed_col:
    .db 0
_deck_grabbed_row:
    .db 0
deck_grabbed_cards:
    .dw 0,0,0,0,0,0,0
