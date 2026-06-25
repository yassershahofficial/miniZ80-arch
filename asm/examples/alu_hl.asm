; ALU ADD A,(HL)
    ld  h, 0
    ld  l, 8
    ld  a, 0x10
    add a, (hl)
    halt
    .db 0x42
