    TITLE_RETRO_X = 120
    TITLE_RETRO_Y = 150
    TITLE_RETRO_WIDTH = 64

title_intro:
    call sound_play_drum_roll_sfx

    call deck_deal_deck

    call sound_play_cymbol_sfx

    ;; keep the title up just a little longer
    ld a, #30
    halt

    ret
