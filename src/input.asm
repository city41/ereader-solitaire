;;
;; input.asm
;; reads the user's input and sets values accordingly
;;
    SYS_INPUT_RAW    = 0xC4
    ERAPI_KEY_A      = 0x0001
    ERAPI_KEY_B      = 0x0002
    ERAPI_KEY_SELECT = 0x0004
    ERAPI_KEY_START  = 0x0008
    ERAPI_KEY_RIGHT  = 0x0010
    ERAPI_KEY_LEFT   = 0x0020
    ERAPI_KEY_UP     = 0x0040
    ERAPI_KEY_DOWN   = 0x0080

    ;; L and R are on the high byte
    ;; but these masks are on the low byte
    ;; because only one input byte is loaded at a time
    ERAPI_KEY_R      = 0x0001
    ERAPI_KEY_L      = 0x0002

input_init:
    ld hl, 0
    ld (_input_cur_input), hl
    ld (input_pressed), hl
    ld (input_just_pressed), hl
    ret

input_read:
    ;;
    ;; NOTE:
    ;; loading to/from pointers to/from bc does not seem to work
    ;; even though general z80 documentation says it should. So this method
    ;; works with external memory through hl. This might be a limitation of
    ;; the ereader's emulator, or I might just be doing something wrong
    ;;

    ; stick last frame's cur into bc
    ; bc is now "_input_last_input"
    ld hl, (_input_cur_input)
    ld b, h
    ld c, l

    ; load this frame's input into hl
    ld hl, (SYS_INPUT_RAW)
    ld (_input_cur_input), hl ; save cur input for next frame comparison

    ;; hl is now cur
    ;; bc is last

    ;; handle lower byte first, which is A,B,Sel,Start,LRUD
    ld a, l ; cur low byte into l
    xor c   ; xor with previous to get just pressed, result is stored in a
    and l   ; and to filter out opposite last presses, result is stored in a
    ld c, a ; move final result over to c
    ;; final result: c is just pressed of lower byte

    ;; now upper byte, which is L,R
    ld a, h
    xor b
    and h
    ld b, a
    ;; final result: b is just pressed of upper byte

    ;; store the results in public variables for consumption
    ld (input_pressed), hl
    ld h, b
    ld l, c
    ld (input_just_pressed), hl

    ret

;; private variables
    .even
_input_cur_input:
    .ds 2

;; global variables
input_pressed:
    .ds 2
input_just_pressed:
    .ds 2
