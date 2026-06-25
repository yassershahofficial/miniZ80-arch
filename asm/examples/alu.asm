; ALU register and immediate test
    ld  a, 0x10
    add a, 0x02
    ld  b, 0x03
    add a, b
    xor a, 0x15
    halt
