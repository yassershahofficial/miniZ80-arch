; INC 8-bit and 16-bit test
    ld  b, 2
    inc b
    ld  a, 0x0F
    inc a
    ld  bc, 0x0000
    inc bc
    halt
