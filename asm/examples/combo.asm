; combo.asm — short mixed instruction smoke test
; Covers: LD, (HL), ALU, rotate, INC, CP, stack, flag ops
;
; Final state: A=17h  B=0Bh  C=0Ah  HL=0400h  DE=0201h  SP=0410h
;              RAM[0400h] = 09h

    ld  hl, 0x0400
    ld  (hl), 0x08

    ld  a, 0x81
    rlca                  ; A = 03h

    add a, (hl)           ; A = 0Bh
    ld  b, a

    sub a, 0x01           ; A = 0Ah
    ld  c, a

    inc (hl)              ; [HL] = 09h
    ld  a, (hl)

    xor a, b              ; A = 02h

    ld  sp, 0x0410
    push bc
    ld  bc, 0x1234
    pop  bc               ; restore B=0Bh, C=0Ah

    cp  a, c
    ld  a, b              ; A = 0Bh

    ld  de, 0x0200
    inc de                ; DE = 0201h

    scf
    rla                   ; A = 17h

    halt
