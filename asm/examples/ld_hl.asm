; LD A,(HL) — read 0x42 stored at address 8
    ld  h, 0
    ld  l, 8
    ld  a, (hl)
    halt
    nop
    nop
    .db 0x42
