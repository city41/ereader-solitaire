    DEAL_PILE_STARTING_SIZE = 24

deal_pile_grab_dealt_card:
    ld a, (deck_grabbed_cards)
    cp 0
    ;; already have a grabbed card? nothing to do here
    ret nz

    ld a, (deal_pile_top_dealt_card)
    cp 0
    ;; there is no card to grab? nothing to do here
    ret z

    push hl
    push bc
    push de

    ld a, (_deal_pile_dealt_pile_i)
    ;; -1 means the dealt pile is empty
    cp -1
    ;; if there is no card to grab, bail
    jr z, deal_pile_grab_dealt_card__done

    ld a, (_deal_pile_dealt_pile_i)
    ;; move the index to previous one
    dec a
    ;; save off the next index for next time
    ld (_deal_pile_dealt_pile_i), a
    ;; put it back as it's still needed for this time
    inc a

    ;; grab pointer to top of dealt pile
    ld hl, _deal_pile_dealt_pile
    ld b, 0
    ld c, a

    ;; move to correct index in dealt pile, ie dealt_pile[i]
    add hl, bc

    ;; grab the card
    ld a, (hl)
    ld (hl), 0

    ;; temp move to d
    ld d, a

    ;; now fix top dealt card
    dec hl

    ld a, (_deal_pile_dealt_pile_i)
    cp -1
    jr nz, deal_pile_grab_dealt_card__skip_zero_out_top_card
    ld a, 0
    jr deal_pile_grab_dealt_card__set_top_card

    deal_pile_grab_dealt_card__skip_zero_out_top_card:
    ld a, (hl)

    deal_pile_grab_dealt_card__set_top_card:
    ld (deal_pile_top_dealt_card), a

    ;; get the grabbed card back from d
    ld a, d

    ld (deck_grabbed_cards), a
    ld a, 0
    ld (deck_grabbed_cards+1), a

    deal_pile_grab_dealt_card__done:

    pop de
    pop bc
    pop hl

    call sound_play_grab_sfx
    ret

deal_pile_cancel_grab:
    push bc
    push hl

    ;; grab dealt pile's current index
    ld a, (_deal_pile_dealt_pile_i)
    ;; move the index to next one
    inc a
    ;; save off the index for next time
    ld (_deal_pile_dealt_pile_i), a

    ;; grab pointer to top of dealt pile
    ld hl, _deal_pile_dealt_pile
    ld b, 0
    ld c, a

    ;; move to correct index in dealt pile, ie dealt_pile[i]
    add hl, bc

    ;; grab the card
    ld a, (deck_grabbed_cards)
    ;; stick it in the dealt pile
    ld (hl), a
    ;; stick it here for convenience, the rest of the game will draw from this
    ld (deal_pile_top_dealt_card), a

    ;; clear out the grabbed card
    ld a, 0
    ld (deck_grabbed_cards), a
    ld (deck_grabbed_cards+1), a

    pop hl
    pop bc

    call sound_play_column_drop_sfx
    ret


;;
;; grabs the next card in the deal pile and places it in the dealt pile
;; 
deal_pile_deal:
    ld a, (_deal_pile_deal_pile_i)
    ;; negative one? the deal pile is empty
    cp -1
    jr nz, _deal_pile_deal__skip_refill

    ;; but can we refill? are there any dealt cards?
    ld a, (deal_pile_top_dealt_card)
    cp 0
    ;; no cards to refill with. nothing we can do, just bail
    ret z

    call _deal_pile_refill

    call sound_play_refill_sfx
    ;; wait a bit to help the player understand what happened
    ;; it also seperates the refill and drop sfx's
    ld a, #20
    halt

    _deal_pile_deal__skip_refill:

    push hl
    push bc
    push de

    ;; move the top card of deal_pile to bottom of dealt_pile
    ;; TODO: if deal_pile is empty, move dealt_pile to deal_pile

    ;; grab current deal pile index
    ld a, (_deal_pile_deal_pile_i)
    ;; move the index down for next time
    dec a
    ld (_deal_pile_deal_pile_i), a
    ;; put it back as it's still needed for this time
    inc a

    ;; get pointer to top of deal pile
    ld hl, _deal_pile_deal_pile

    ld b, 0
    ld c, a

    ;; move to current deal pile location, ie deal_pile[i]
    add hl, bc

    ;; grab the card out of the deal pile
    ld a, (hl)
    ;; move the card over into d
    ld d, a

    ;; zero it out in the deal pile
    ld (hl), 0

    ;; now to stick it into the dealt pile

    ;; grab dealt pile's current index
    ld a, (_deal_pile_dealt_pile_i)
    ;; move the index to next one
    inc a
    ;; save off the index for next time
    ld (_deal_pile_dealt_pile_i), a

    ;; grab pointer to top of dealt pile
    ld hl, _deal_pile_dealt_pile
    ld b, 0
    ld c, a

    ;; move to correct index in dealt pile, ie dealt_pile[i]
    add hl, bc

    ;; grab the card
    ld a, d
    ;; stick it in the dealt pile
    ld (hl), a
    ;; stick it here for convenience, the rest of the game will draw from this
    ld (deal_pile_top_dealt_card), a

    call sound_play_column_drop_sfx

    pop de
    pop bc
    pop hl
    ret

;; takes the cards in dealt pile and puts them back into deal pile
_deal_pile_refill:
    ld a, (_deal_pile_dealt_pile_i)
    ld b, a
    ;; need to inc b as it is one based and pile indexes are zero based
    inc b
    ld d, 0

    _deal_pile_refill__loop:
    ;;
    ;; grab card off dealt pile
    ;;

    ;; get its current index
    ld a, (_deal_pile_dealt_pile_i)
    ;; move it down to the previous index for next time
    dec a
    ld (_deal_pile_dealt_pile_i), a
    ;; jump back as we still need the current index
    inc a
    ;; load pointer to pile
    ld hl, _deal_pile_dealt_pile
    ;; move pointer to right spot
    ld e, a
    add hl, de
    ;; copy the card off the dealt pile
    ld a, (hl)
    ;; zero it out on the dealt pile
    ld (hl), 0
    ;; move it to c for safe keeping
    ld c, a

    ;;
    ;; stick it on the deal pile
    ;;
    
    ld a, (_deal_pile_deal_pile_i)
    ;; move to spot where the card will go
    inc a
    ;; save it off for next time
    ld (_deal_pile_deal_pile_i), a
    ;; pointer to deal pile
    ld hl, _deal_pile_deal_pile
    ;; move it to right spot
    ld d, 0
    ld e, a
    add hl, de
    ;; grab the card again
    ld a, c
    ;; save it on the deal pile
    ld (hl), a
    djnz _deal_pile_refill__loop

    ret


;; copy cards 29-52 from the deck into deal_pile
deal_pile_load_cards:
    push bc
    push hl

    ld b, 0
    ld c, 0

    _deal_pile_load_cards__loop:
    ld hl, deck_mem_deck
    ;; move past cards that are already in the playfield
    ld de, 28
    add hl, de
    ;; move to current card
    add hl, bc
    ;; copy card from deck into a
    ld a, (hl)

    ld hl, _deal_pile_deal_pile
    ;; move forward to correct spot in deal pile
    add hl, bc
    ;; copy card into deal pile
    ld (hl), a

    ;; move onto next card
    inc c
    ld a, c
    ;; only getting so many cards
    cp DEAL_PILE_STARTING_SIZE
    jr z, _deal_pile_load_cards__done
    jr _deal_pile_load_cards__loop

    _deal_pile_load_cards__done:
    pop hl
    pop bc
    ret


deal_pile_top_dealt_card:
    .db 0
_deal_pile_deal_pile_i:
    .db (DEAL_PILE_STARTING_SIZE - 1)
_deal_pile_dealt_pile_i:
    .db -1
_deal_pile_deal_pile:
    .ds 24
    .db 0
_deal_pile_dealt_pile:
    .ds 24
    .db 0