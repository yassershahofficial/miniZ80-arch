; RLCA / RRCA / RLA / RRA / SCF / CCF test
    ld  a, 0x81
    rlca
    rlca
    rrca
    scf
    rla
    ccf
    rra
    halt
