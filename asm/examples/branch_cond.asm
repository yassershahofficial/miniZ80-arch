; Conditional JR / CALL / RET test
    ld  sp, 0x0410
    ld  a, 0
    add a, a
    jr  z, 2
    ld  a, 0xFF
    scf
    jr  c, 2
    ld  a, 0xFE
    call nz, 0x0015
    ld  a, 0xFD
    halt
    ld  a, 0x42
    ret nz
    ld  a, 0xFB
    halt
