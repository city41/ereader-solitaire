;;
;; repeat_input.asm
;; sets a variable for repeating inputs, mostly used for cursor movement
;;

    _I_COOLDOWN_DURATION_SLOW = 14
    _I_COOLDOWN_DURATION_FAST = 3

repeat_input_read:
    ;; process repeat presses
    ;; since the z80 emulator has virtually no support for bit level operations
    ;; just going to do it by hand

    ;; first, reset the repeat inputs
    ld a, 0
    ld (input_repeat_pressed), a

    ld hl, _i_cooldown_left
    ld b, ERAPI_KEY_LEFT
    call _i_process_repeat

    ld hl, _i_cooldown_right
    ld b, ERAPI_KEY_RIGHT
    call _i_process_repeat

    ld hl, _i_cooldown_up
    ld b, ERAPI_KEY_UP
    call _i_process_repeat

    ld hl, _i_cooldown_down
    ld b, ERAPI_KEY_DOWN
    call _i_process_repeat

    ret

;; processes repeat inputs for a given button
;;
;; parameters
;; hl: pointer to cooldown
;; b: button mask
_i_process_repeat:
    ;; this works as we only care about the low byte
    ld a, (SYS_INPUT_JUST)
    and b
    ;; input was just pressed, so count this as a repeat press too
    jr z, input_read__repeat__skip_just_pressed
    ;; input was just pressed, reset the repeat count
    inc hl
    ld (hl), 0
    dec hl
    jr input_read__repeat__set

    input_read__repeat__skip_just_pressed:

    ;; button wasn't just pressed, is it currently pressed?
    ld a, (SYS_INPUT_RAW)
    and b
    jr z, input_read__repeat__done
    ;; button is still being pressed, decrement the cooldown
    ld a, (hl)
    dec a
    ld (hl), a
    cp 0
    ;; cooldown hasnt finished, so bail on button till next frame
    jr nz, input_read__repeat__done

    ;; record a press and reset the cooldown
    input_read__repeat__set:
    ;; note how many repeats have happened
    inc hl ; move forward to repeat counter byte
    ld a, (hl)
    inc a
    ld (hl), a
    dec hl ; move back to cooldown byte

    ;; has there been 5 repeated movements? if so, move to fast speed
    cp 5
    jr nc, input_read__repeat__set_fast_duration ;; a >= 5
    ld a, _I_COOLDOWN_DURATION_SLOW
    jr input_read__repeat__done_set_duration

    input_read__repeat__set_fast_duration:
    ld a, _I_COOLDOWN_DURATION_FAST

    input_read__repeat__done_set_duration:
    ;; store the new cooldown duration
    ld (hl), a
    ld a, (input_repeat_pressed)
    add b
    ld (input_repeat_pressed), a

    input_read__repeat__done:
    ret


;; private variables
    .even
_i_cooldown_left:
    .db 0  ; cooldown counter
    .db 0  ; repeat counter
_i_cooldown_right:
    .db 0  ; cooldown counter
    .db 0  ; repeat counter
_i_cooldown_up:
    .db 0  ; cooldown counter
    .db 0  ; repeat counter
_i_cooldown_down:
    .db 0  ; cooldown counter
    .db 0  ; repeat counter

;; global variables
input_repeat_pressed:
    .dw 0
