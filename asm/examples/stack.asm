; PUSH / POP test
    ld  bc, 0x1234
    ld  sp, 0x0410
    push bc
    ld  bc, 0x0000
    pop bc
    halt
