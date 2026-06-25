; PUSH AF / POP AF test
    ld  a, 0x55
    scf
    ld  sp, 0x0410
    push af
    ld  a, 0x00
    pop af
    halt
