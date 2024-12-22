
; given the card in a, sets the turn over bit
cards_util_turn_card_to_back:
    ;; by turning to front first, we ensure the bit
    ;; is cleared
    call cards_util_turn_card_to_front
    ;; since the bit is cleared, this add is safe
    add a, CARD_TURNED_OVER_MASK
    ret

; given the card in a, unsets the turn over bit
cards_util_turn_card_to_front:
    push bc
    ld b, a
    ld a, 0x7f
    and b
    pop bc
    ret

; given the card in a, sets its rank in a
cards_util_get_rank:
    ;; is the card really a card?
    cp 0
    ;; not a card, bail early
    ;; leaving zero in a is a decent return for this
    ret z

    ;; set up for Erapi_Mod
    push de
    push hl
    ld d, 0
    ld e, #13
    ld h, 0
    ld l, a

    rst 8
    ;; hl = hl % de
    .db ERAPI_Mod

    ld a, l
    cp 0
    jr nz, cards_util_get_rank__skip_set_king
    ;; if it was zero, then it's actually 13
    ld a, #13

    cards_util_get_rank__skip_set_king:
    pop hl
    pop de
    ret

; given the card in a, sets its suit in a
cards_util_get_suit:
    ;; cards are one based, but we need them to be zero based for this
    dec a

    ;; set up for Erapi_Div
    push de
    push hl
    ld d, 0
    ld e, #13
    ld h, 0
    ld l, a

    rst 8
    ;; hl = hl / de
    .db ERAPI_Div

    ld a, l

    pop hl
    pop de
    ret

