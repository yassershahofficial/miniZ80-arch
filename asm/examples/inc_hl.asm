; INC (HL) — memory read/modify/write in RAM
    ld  b, 0x05
    ld  hl, 0x0400
    ld  (hl), b
    inc (hl)
    ld  a, (hl)
    halt
