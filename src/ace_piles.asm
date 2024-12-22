;; adds a card to the proper ace pile
;;
;; parameters
;; a: the card
;;
;; returns
;; a=0, not a legal drop, 1 dropped into pile
ace_piles_drop_card:
    ;; copy the card into b
    ld b, a
    ;; suit is now in a
    call cards_util_get_suit ; suit is now in a

    ;; with suit in a, get the pointer to its pile
    call _ace_piles_get_pile_pointer ; pointer will be in hl

    ;; now we are well setup to see if this is even a legal drop
    ;; params, b=card, hl=pointer to pile
    call _ace_piles_is_legal_drop
    ;; a=1 if legal, 0 if not
    cp 1
    jr z, _ace_piles_drop_card__is_legal
    ;; this is not a legal drop
    ;; play error and bail
    call sound_play_error_sfx
    ret

    _ace_piles_drop_card__is_legal:
    ;; this is legal, put the card in the pile
    ;; restore the card back into a
    ld a, b
    ld (hl), a
    ld a, 1
    call sound_play_ace_drop_sfx
    ret

;;
;; returns the top card in an ace pile
;;
;; parameters
;; a: the ace pile index (aka suit)
ace_piles_get_card:
    ;; with suit in a, get the pointer to its pile
    push hl
    call _ace_piles_get_pile_pointer ; pointer will be in hl

    ld a, (hl)
    pop hl
    ret

;;
;; Determines if the requested drop is legal
;; A drop is only legal if its rank is exactly
;; one greater than the top of the pile
;;
;; parameters
;; b: the card requesting drop
;; hl: pointer to b's ace pile
;;
;; returns
;; a=0 if illegal, 1 if legal
_ace_piles_is_legal_drop:
    push bc
    ;; move the card where card_utils expects it
    ld a, b
    ;; get the rank into a
    call cards_util_get_rank
    ;; move the rank over to b
    ld b, a

    ;; load the ace pile card
    ld a, (hl)
    ;; now get the ace pile's card's rank
    call cards_util_get_rank

    ;; diff = acePileRank - requestedRank
    ;; a = a - b
    sub b

    ;; this is only legal if the diff is -1
    cp 0xff
    pop bc
    jr z, _ace_piles_is_legal_drop__legal
    ;; this is not a legal drop
    ld a, 0
    ret

    _ace_piles_is_legal_drop__legal:
    ;; this is a legal drop
    ld a, 1
    ret

;; get a pointer to an ace pile
;;
;; parameters
;; a: the ace pile index
;;
;; returns
;; hl: the pointer to the ace pile
_ace_piles_get_pile_pointer:
    cp 0
    jr nz, _ace_piles_get_pile_pointer__skip_spade
    ld hl, _ace_pile_spade_pile
    ret

    _ace_piles_get_pile_pointer__skip_spade:

    cp 1
    jr nz, _ace_piles_get_pile_pointer__skip_heart
    ld hl, _ace_pile_heart_pile
    ret

    _ace_piles_get_pile_pointer__skip_heart:

    cp 2
    jr nz, _ace_piles_get_pile_pointer__skip_club
    ld hl, _ace_pile_club_pile
    ret

    _ace_piles_get_pile_pointer__skip_club:

    ld hl, _ace_pile_diamond_pile
    ret


_ace_pile_spade_pile:
    .db 0
_ace_pile_heart_pile:
    .db 0
_ace_pile_club_pile:
    .db 0
_ace_pile_diamond_pile:
    .db 0
