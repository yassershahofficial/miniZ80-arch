; JP, CALL, RET, DJNZ test (numeric addresses)
    ld  sp, 0x0410
    ld  a, 0
    jp  0x000A
    ld  a, 0xFF
    nop
    call 0x0014
    ld  b, 3
    djnz -2
    halt
    nop
    inc a
    ret
