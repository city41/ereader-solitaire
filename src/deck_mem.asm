;; deck_mem
;; most things related to deck memory
;; are here. Both deck_logic and deck_gfx
;; draw from this

    ;; the most that can be in a column is the six unturned cards
    ;; in the last column plus K->A, ie 19
    DECK_MEM_MAX_CARDS_PER_COLUMN = 6 + 13

;; returns a column pointer
;; params
;; a: the column index
;;
;; returns
;; hl: the column's pointer
deck_mem_get_pointer_to_column:
    ;; save bc
    push bc
    ld hl, deck_mem_columns
    ld b, 0
    ld c, a
    ;; addresses are words, so add twice for *2
    add hl, bc
    add hl, bc

    ;; from pointer to pointer -> pointer
    ld c, (hl)
    inc hl
    ld b, (hl)
    push bc
    pop hl
    ;; restore saved bc
    pop bc
    ret

    .even
deck_mem_deck:
    ; start with a fully sorted deck
    ; deck_deal_shuffle will shuffle it
    .db S_A, S_2, S_3, S_4, S_5, S_6, S_7, S_8, S_9, S_10, S_J, S_Q, S_K
    .db H_A, H_2, H_3, H_4, H_5, H_6, H_7, H_8, H_9, H_10, H_J, H_Q, H_K
    .db C_A, C_2, C_3, C_4, C_5, C_6, C_7, C_8, C_9, C_10, C_J, C_Q, C_K
    .db D_A, D_2, D_3, D_4, D_5, D_6, D_7, D_8, D_9, D_10, D_J, D_Q, D_K


deck_mem_columns:
    .dw deck_mem_column_0
    .dw deck_mem_column_1
    .dw deck_mem_column_2
    .dw deck_mem_column_3
    .dw deck_mem_column_4
    .dw deck_mem_column_5
    .dw deck_mem_column_6
    .dw 0
deck_mem_column_0:
    .ds DECK_MEM_MAX_CARDS_PER_COLUMN
    .db 0
deck_mem_column_1:
    .ds DECK_MEM_MAX_CARDS_PER_COLUMN
    .db 0
deck_mem_column_2:
    .ds DECK_MEM_MAX_CARDS_PER_COLUMN
    .db 0
deck_mem_column_3:
    .ds DECK_MEM_MAX_CARDS_PER_COLUMN
    .db 0
deck_mem_column_4:
    .ds DECK_MEM_MAX_CARDS_PER_COLUMN
    .db 0
deck_mem_column_5:
    .ds DECK_MEM_MAX_CARDS_PER_COLUMN
    .db 0
deck_mem_column_6:
    .ds DECK_MEM_MAX_CARDS_PER_COLUMN
    .db 0