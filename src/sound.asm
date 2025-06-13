    ; ERAPI_PlaySystemSound()
    ; hl=sound number

    ;; casual
    SOUND_BGM1=34
    ;; slow and dramatic
    SOUND_BGM2=58
    ;; noble
    SOUND_BGM3=59

sound_play_bgm1:
    ld hl, SOUND_BGM1
    rst 8
    .db ERAPI_PlaySystemSound
    ret

sound_play_bgm2:
    ld hl, SOUND_BGM2
    rst 8
    .db ERAPI_PlaySystemSound
    ret

sound_play_bgm3:
    ld hl, SOUND_BGM3
    rst 8
    .db ERAPI_PlaySystemSound
    ret

sound_pause_bgm1:
    ld hl, SOUND_BGM1
    rst 8
    .db ERAPI_PauseSound
    ret

sound_pause_bgm2:
    ld hl, SOUND_BGM2
    rst 8
    .db ERAPI_PauseSound
    ret

sound_pause_bgm3:
    ld hl, SOUND_BGM3
    rst 8
    .db ERAPI_PauseSound
    ret

sound_resume_bgm1:
    ld hl, SOUND_BGM1
    rst 8
    .db ERAPI_ResumeSound
    ret

sound_resume_bgm2:
    ld hl, SOUND_BGM2
    rst 8
    .db ERAPI_ResumeSound
    ret

sound_resume_bgm3:
    ld hl, SOUND_BGM3
    rst 8
    .db ERAPI_ResumeSound
    ret

sound_play_error_sfx:
    ld hl, 80
    rst 8
    .db ERAPI_PlaySystemSound
    ret

sound_play_grab_sfx:
    ld hl, 31
    rst 8
    .db ERAPI_PlaySystemSound
    ret

sound_play_column_drop_sfx:
    ld hl, 32
    rst 8
    .db ERAPI_PlaySystemSound
    ret

sound_play_ace_drop_sfx:
    ld hl, 1
    rst 8
    .db ERAPI_PlaySystemSound
    ret

sound_play_cursor_move_sfx:
    ld hl, 24
    rst 8
    .db ERAPI_PlaySystemSound
    ret

sound_play_drum_roll_sfx:
    ld hl, 755
    rst 8
    .db ERAPI_PlaySystemSound
    ret

sound_play_cymbol_sfx:
    ld hl, 756
    rst 8
    .db ERAPI_PlaySystemSound
    ret

sound_play_refill_sfx:
    ld hl, 121
    rst 8
    .db ERAPI_PlaySystemSound
    ret

sound_play_win_sfx:
    ld hl, 84
    rst 8
    .db ERAPI_PlaySystemSound
    ret

sound_stop_music:
    ld hl, SOUND_BGM1
    rst 8
    .db ERAPI_PauseSound
    ld hl, SOUND_BGM2
    rst 8
    .db ERAPI_PauseSound
    ld hl, SOUND_BGM3
    rst 8
    .db ERAPI_PauseSound
    ret

sound_cycle_bgm:
    ld a, (_sound_cur_bgm)
    inc a
    cp 4
    jr nz, sound_cycle_bgm__skip_wrap
    ld a, 0

    sound_cycle_bgm__skip_wrap:

    ld (_sound_cur_bgm), a

    cp 0
    call z, sound_stop_music

    cp 1
    call z, sound_play_bgm1

    cp 2
    call z, sound_play_bgm2

    cp 3
    call z, sound_play_bgm3
    ret

sound_pause_bgm:
    ld a, (_sound_cur_bgm)

    cp 1
    call z, sound_pause_bgm1

    cp 2
    call z, sound_pause_bgm2

    cp 3
    call z, sound_pause_bgm3
    ret

sound_resume_bgm:
    ld a, (_sound_cur_bgm)

    cp 1
    call z, sound_resume_bgm1

    cp 2
    call z, sound_resume_bgm2

    cp 3
    call z, sound_resume_bgm3
    ret

_sound_cur_bgm:
    .db 1