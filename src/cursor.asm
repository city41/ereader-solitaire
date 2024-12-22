
    CURSOR_SECTION_PLAYFIELD  = 1
    CURSOR_SECTION_DEAL_PILE  = 2
    CURSOR_SECTION_DEALT_PILE = 3
    CURSOR_SECTION_ACE_PILES  = 4

cursor_on_card_grab_canceled:
    ;; if in ace piles, need to return to playfield
    ld a, (cursor_section)
    cp CURSOR_SECTION_ACE_PILES
    jr nz, cursor_on_card_grab_canceled__done

    ;; manually fully revert back to playfield
    ;; this ensures we go back exactly where we were
    ;; TODO: this digs into deck privates
    ld a, CURSOR_SECTION_PLAYFIELD
    ld (cursor_section), a
    ld a, (_deck_grabbed_col)
    ld (cursor_playfield_col), a
    ld a, (_deck_grabbed_row)
    ld (cursor_playfield_row), a

    cursor_on_card_grab_canceled__done:
    ;; and make sure we are in a safe row
    call _cursor_calc_row

    ret


;; 
;; moves the cursor right by one column,
;; wrapping if needed.
;;
;; If the column is empty, keeps going until
;; it finds one that is not, unless thre is a grabbed card.
;; If all columns are empty, this is an infinite loop.
;;
;; updates:
;; cursor_playfield_col: 0-6, which column the cursor ended up in
;; cursor_playfield_row: lands on nearest front card
;; 
cursor_go_right:
    ld a, (cursor_section)
    cp CURSOR_SECTION_PLAYFIELD
    jr nz, cursor_go_right__skip_playfield
    call _cursor_go_right_in_playfield
    jr cursor_go_right__done

    cursor_go_right__skip_playfield:

    cp CURSOR_SECTION_DEAL_PILE
    jr nz, cursor_go_right__skip_deal_pile
    call _cursor_toggle_deal_dealt
    jr cursor_go_right__done

    cursor_go_right__skip_deal_pile:

    cp CURSOR_SECTION_DEALT_PILE
    jr nz, cursor_go_right__skip_dealt_pile
    ;; is there a grabbed card? if so, go to ace piles
    ld a, (deck_grabbed_cards)
    cp 0
    jr z, cursor_go_right__go_to_toggle
    call _cursor_on_enter_ace_piles_from_playfield
    ret

    cursor_go_right__go_to_toggle:
    call _cursor_toggle_deal_dealt

    cursor_go_right__skip_dealt_pile:
    cursor_go_right__done:
    ret

_cursor_toggle_deal_dealt:
    ld a, (cursor_section)
    cp CURSOR_SECTION_DEAL_PILE
    jr nz, _cursor_toggle_deal_dealt__skip_deal
    ;; if in deal, go to dealt
    ld a, CURSOR_SECTION_DEALT_PILE
    jr _cursor_toggle_deal_dealt__done

    ;; if in dealt, go to deal
    _cursor_toggle_deal_dealt__skip_deal:
    ld a, CURSOR_SECTION_DEAL_PILE

    _cursor_toggle_deal_dealt__done:
    ld (cursor_section), a
    ret

_cursor_go_right_in_playfield:
    ld a, (cursor_playfield_col)

    inc a
    cp 7
    jr nz, cursor_go_right__skip_wrap
    ld a, 0
    cursor_go_right__skip_wrap:

    ;; a is now set to the new column
    ld (cursor_playfield_col), a

    call _cursor_calc_row
    ret

;; 
;; moves the cursor left by one column,
;; wrapping if needed.
;;
cursor_go_left:
    ld a, (cursor_section)
    cp CURSOR_SECTION_PLAYFIELD
    jr nz, cursor_go_left__skip_playfield
    call _cursor_go_left_in_playfield
    jr cursor_go_left__done

    cursor_go_left__skip_playfield:

    cp CURSOR_SECTION_DEAL_PILE
    jr nz, cursor_go_left__skip_deal_pile
    ;; is there a grabbed card? if so, go to ace piles
    ld a, (deck_grabbed_cards)
    cp 0
    jr z, cursor_go_left__go_to_toggle
    call _cursor_on_enter_ace_piles_from_playfield
    ret

    cursor_go_left__go_to_toggle:
    call _cursor_toggle_deal_dealt
    jr cursor_go_left__done

    cursor_go_left__skip_deal_pile:

    cp CURSOR_SECTION_DEALT_PILE
    jr nz, cursor_go_left__skip_dealt_pile
    call _cursor_toggle_deal_dealt

    cursor_go_left__skip_dealt_pile:
    cursor_go_left__done:
    ret

_cursor_go_left_in_playfield:
    ld a, (cursor_playfield_col)

    dec a
    cp -1
    jr nz, cursor_go_left__skip_wrap
    ld a, 6
    cursor_go_left__skip_wrap:

    ;; a is now set to the new column
    ld (cursor_playfield_col), a

    call _cursor_calc_row
    ret

;; 
;; moves the cursor down in a column,
;; wrapping if needed
;;
cursor_go_down:
    ;; special case, if there is more than one grabbed card
    ;; then vertical movement is not allowed
    ld a, (deck_grabbed_cards+1)
    cp 0
    ret nz

    ld a, (cursor_section)
    cp CURSOR_SECTION_PLAYFIELD
    jr nz, cursor_go_down__skip_playfield
    call _cursor_go_down_in_playfield
    ret

    cursor_go_down__skip_playfield:
    ;; either we are in deal, dealt or ace
    ;; all three behave the same in this context
    call _cursor_go_down_to_playfield
    ret

;; goes from deal/dealt/ace to playfield
_cursor_go_down_to_playfield:
    ;; now go back to the very top of the column
    ;; since cursor_playfield_col has been maintained, will return
    ;; to the column the user came from
    ld a, 0
    ld (cursor_playfield_row), a
    ;; and have cursor_calc_row figure out safety
    call _cursor_calc_row

    ld a, CURSOR_SECTION_PLAYFIELD
    ld (cursor_section), a

    call sound_play_cursor_move_sfx

    ret

_cursor_go_down_in_playfield:
    ld a, (cursor_playfield_row)
    inc a
    ld (cursor_playfield_row), a

    ld c, a
    ld a, (cursor_playfield_col)
    ld b, a

    ;; load card we are now on into a
    call deck_get_card
    ;; did we land on a card?
    cp 0
    ;; if we land on a card, nothing more to do
    jr nz, _cursor_go_down_in_playfield__landed_on_a_card
    ;; we did not land on a card, we have gone off the edge of the column
    ;; head back and stay in the column (don't allow wrapping)
    ;; restore a
    ld a, (cursor_playfield_row)
    ;; head back to where we were
    dec a
    ;; and save it
    ld (cursor_playfield_row), a
    jr _cursor_go_down_in_playfield__done

    _cursor_go_down_in_playfield__landed_on_a_card:
    ;; they made a movement, play the sfx
    call sound_play_cursor_move_sfx

    _cursor_go_down_in_playfield__done:
    ret

cursor_go_up:
    ;; special case, if there is more than one grabbed card
    ;; then vertical movement is not allowed
    ld a, (deck_grabbed_cards+1)
    cp 0
    ret nz

    ld a, (cursor_section)
    cp CURSOR_SECTION_PLAYFIELD
    jr nz, cursor_go_up__skip_playfield
    call _cursor_go_up_in_playfield
    ret

    cursor_go_up__skip_playfield:
    cp CURSOR_SECTION_DEAL_PILE
    jr nz, cursor_go_up__skip_deal_pile
    call _cursor_go_up_in_deal_pile
    ret

    cursor_go_up__skip_deal_pile:
    call _cursor_go_up_in_ace_piles
    ret

_cursor_go_up_in_ace_piles:
    ;; now go back to the verrrrrrry bottom of the column
    ;; since cursor_playfield_col has been maintained, will return
    ;; to the column the user came from
    ld a, DECK_MEM_MAX_CARDS_PER_COLUMN
    ld (cursor_playfield_row), a
    ;; and have cursor_calc_row figure out safety
    call _cursor_calc_row
    ld a, CURSOR_SECTION_PLAYFIELD
    ld (cursor_section), a
    call _cursor_on_exit_deal_pile_to_playfield
    ret

_cursor_go_up_in_deal_pile:
    ;; now go back to the verrrrrrry bottom of the column
    ;; since cursor_playfield_col has been maintained, will return
    ;; to the column the user came from
    ld a, DECK_MEM_MAX_CARDS_PER_COLUMN
    ld (cursor_playfield_row), a
    ;; and have cursor_calc_row figure out safety
    call _cursor_calc_row
    call _cursor_on_exit_deal_pile_to_playfield
    ret

_cursor_go_up_in_playfield:
    ;; special case, if a card has been grabbed, go straight to ace pile
    ld a, (deck_grabbed_cards)
    cp 0
    jr z, _cursor_go_up_in_playfield__skip_grab_to_ace_pile
    ;; there is a grabbed card, straight to ace pile
    call _cursor_on_enter_ace_piles_from_playfield
    ret
    

    _cursor_go_up_in_playfield__skip_grab_to_ace_pile:
    ;; get the current row
    ld a, (cursor_playfield_row)
    ;; move it up one
    dec a
    ;; did we go up off the column? then onto deal pile
    ;; if there is a grab, the off to ace pile case was checked first thing
    cp -1
    jr z, cursor_go_up__go_to_deal_pile

    ;; save where we landed
    ld (cursor_playfield_row), a

    ;; well we didn't leave the playfield. But is the current card a back?
    ld c, a
    ld a, (cursor_playfield_col)
    ld b, a
    call deck_get_card
    cp 0x80
    ;; if it is less than 0x80, this is not a back card, stay in playfield
    jr c, cursor_go_up__stay_in_playfield
    ;; ok this is a back card, off to deal pile
    ;; if there is a grab, the off to ace pile case was checked first thing
    jr cursor_go_up__go_to_deal_pile

    cursor_go_up__stay_in_playfield:
    ;; ok we should stay in the playfield, just make sure the row we are in is safe
    call _cursor_calc_row
    ret

    cursor_go_up__go_to_deal_pile:
    call _cursor_on_enter_deal_pile_from_playfield
    ret


_cursor_on_enter_deal_pile_from_playfield:
    ;; since we went to deal, make sure they return to playfield at column 0
    ld a, 0
    ld (cursor_playfield_col), a
    ld a, CURSOR_SECTION_DEAL_PILE
    ld (cursor_section), a
    ret

_cursor_on_enter_ace_piles_from_playfield:
    ;; if the user hasn't grabbed a card, deny entry into ace piles
    ld a, (deck_grabbed_cards)
    cp 0
    ret z

    ;; ok, but which ace pile? depends on the suit of grabbed card
    call cards_util_get_suit
    ;; now a has the suit, which is also the ace pile index
    ld (cursor_ace_piles_col), a

    ;; now set cursor_playfield_col based on which ace pile we went into
    ;; that way if the user presses up/down, they go to the column just
    ;; below the current ace pile.
    ;; cursor_ace_piless_col + 3 = cursor_playfield_col
    add a,3
    ld (cursor_playfield_col), a

    ld a, CURSOR_SECTION_ACE_PILES
    ld (cursor_section), a

    ret

_cursor_on_exit_deal_pile_to_playfield:
    ld a, CURSOR_SECTION_PLAYFIELD
    ld (cursor_section), a
    ret

cursor_on_grabbed_card_moved_to_ace_piles:
    call cursor_on_card_grab_canceled

    ;; move right then left again, this will
    ;; fix if the current column is now empty,
    ;; and cal a proper row as a bonus
    call cursor_go_right
    call cursor_go_left

    ret
;;
;; Figures out what row
;; should be based on the current column
;;
;; tries to maintain column_row and only moves if
;; if lands on a back card or off the end of the column
_cursor_calc_row:
    ;; if this is an empty column, just choose zero
    ld a, (cursor_playfield_col)
    ld b, a
    call deck_get_final_populated_index
    cp -1
    jr nz, _cursor_calc_row__skip_empty_row
    ld a, 0
    ld (cursor_playfield_row), a
    ret

    _cursor_calc_row__skip_empty_row:

    ;; does the user have a grabbed card? in that case the answer is always
    ;; "last populated row", no matter what
    ld a, (deck_grabbed_cards)
    cp 0
    jr z, _cursor_calc_row__skip_grabbed
    ld a, (cursor_playfield_col)
    ld b, a
    call deck_get_final_populated_index
    ;; if the column is empty, this will return -1
    ;; in that case, choose zero
    cp -1
    jr z, _cursor_calc_row__grabbed_choose_zero
    ld (cursor_playfield_row), a
    ret
    _cursor_calc_row__grabbed_choose_zero:
    ld a, 0
    ld (cursor_playfield_row), a
    ret

    _cursor_calc_row__skip_grabbed:
    _cursor_calc_row__check_row:
    ld a, (cursor_playfield_col)
    ld b, a
    ld a, (cursor_playfield_row)
    ld c, a
    
    call deck_get_card
    cp 0
    jr nz, _cursor_calc_row__skip_off_end
    ;; card is off the end of the column
    ld a, (cursor_playfield_row)
    ;; move up one
    dec a
    ;; save it
    ld (cursor_playfield_row), a
    ;; go back and see if this is a valid spot
    jr _cursor_calc_row__check_row

    _cursor_calc_row__skip_off_end:
    ;; ok it is not off the end, is it on a back card?
    cp 0x80
    ;; if it is greater than 0x80, this is a back card
    jr c, _cursor_calc_row__skip_back
    ;; ok this is a back card
    ld a, (cursor_playfield_row)
    ;; move down one
    inc a
    ;; save it
    ld (cursor_playfield_row), a
    ;; go back and see if this is a valid spot
    jr _cursor_calc_row__check_row

    _cursor_calc_row__skip_back:
    ;; this spot is neither off the end or on a back
    ;; we are good!
    ret

    call deck_mem_get_pointer_to_column
    ld b, 0 ; this is our index counter
    _cursor_calc_row__find_first_front_card_loop:
    ;; grab the card in the column
    ld a, (hl)
    ;; is its value less than 0x80? 
    cp 0x80
    ;; if it is, it is front facing
    jr c, _cursor_calc_row__found_first_front_card
    ;; move to next card
    inc hl
    ;; increase our index counter
    inc b
    jr _cursor_calc_row__find_first_front_card_loop

    _cursor_calc_row__found_first_front_card:
    ;; b holds the index of the first front card in the column
    ld a, b
    ld (cursor_playfield_row), a
    ret


cursor_playfield_col:
    .db 0
cursor_playfield_row:
    .db 0
cursor_ace_piles_col:
    .db 0
;; see CURSOR_SECTION_* at top of file
cursor_section:
    .db CURSOR_SECTION_PLAYFIELD
