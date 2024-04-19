; vim: ts=8:sw=8

		.export	OSRDCH   := $FFE0
		.export	OSASCI   := $FFE3
		.export	OSNEWL   := $FFE7
		.export	OSWRCH   := $FFEE
		.export	OSWORD   := $FFF1
		.export	OSBYTE   := $FFF4

.segment "STARTUP"

.segment "CODE"

.org		$8000

.scope		Header
		jmp		LangEntry		; language entry
		jmp		ServiceEntry		; service entry
		.byte		$c2			; ROM type
		.byte		<Copyright - 1		; (C) pointer
		.byte		$05			; major version
Title:		.asciiz		"Unix terminal emulator *UTE5"
		.asciiz		""
Copyright:	.asciiz		"(C) Clive D. Rodgers 1985"
.endscope

.proc		ServiceEntry
		pha
		cmp		#$09
		beq		L804C
		cmp		#$04
		beq		L805C
		pla
		rts
L804C:		ldx		#$ff
L804E:		inx
		lda		Header::Title,x
		jsr		OSASCI
		bne		L804E
		jsr		OSNEWL
		pla
		rts
L805C:   	tya
		pha
		txa
		pha
		ldx		#$ff
		dey
L8063:    	inx
		iny
		lda		L807B,X
		bmi		L8074
		cmp		($f2),Y
		beq		L8063
		pla
		tax
		pla
		tay
		pla
		rts
.endproc

L8074:		lda		#$8e
		ldx		$f4
		jsr		OSBYTE			; enter language ROM

L807B:		.byte		"UTE5", $ff

LangEntry:	cli
		ldx		#$FF
		txs
		lda		#$00
		sta		$70
		sta		$72
		sta		$73
		sta		$86
		sta		$88
		lda		#$07
		sta		$87
		lda		#$1F
		sta		$89
		lda		#$4F
		sta		$8A
L809C:		jsr		L85E3
		lda		#$E5
		ldx		#$01
		ldy		#$00
		jsr		OSBYTE
		lda		#$16
		jsr		OSWRCH
		lda		$88
		jsr		OSWRCH
		lda		#$0F
		ldx		#$00
		jsr		OSBYTE
		lda		#$CA
		ldx		#$30
		jsr		OSBYTE
		ldx		#$02
		lda		#$04
		jsr		OSBYTE
		ldy		#$00
		ldx		#$80
		lda		#$E1
		jsr		OSBYTE
		ldy		#$00
		ldx		#$90
		lda		#$E2
		jsr		OSBYTE
		ldy		#$00
		ldx		#$A0
		lda		#$E3
		jsr		OSBYTE
		ldy		#$00
		ldx		#$01
		lda		#$E4
		jsr		OSBYTE
		lda		#$14
		ldx		#$01
		jsr		OSBYTE
		jsr		L85F2
		ldx		#$0A
		ldy		#$00
L80F9:		lda		L8659,Y
		jsr		L85CB
		bne		L80F9
L8101:		jsr		L8120
		and		#$7F
		cmp		#$20
		bcs		L8110
		jsr		L82B9
		jmp		L8101
L8110:		ldx		$72
		bne		L811A
		jsr		OSWRCH
		jmp		L8101
L811A:		jsr		L81EC
		jmp		L8101

L8120:		lda		#$80
		ldx		#$FD
		ldy		#$FF
		jsr		OSBYTE
		cpx		#$02
		bcc		L8152
		lda		#$80
		ldx		#$FF
		ldy		#$FF
		jsr		OSBYTE
		cpx		#$01
		bcc		L8152
		lda		#$02
		ldx		#$02
		jsr		OSBYTE
		jsr		OSRDCH
		cmp		#$1B
		bne		L814B
		jsr		L826C
L814B:		jsr		L816F
		tay
		jsr		L8166
L8152:		jsr		L827E
		cpx		#$01
		bcc		L8120
		lda		#$02
		ldx		#$01
		jsr		OSBYTE
		jsr		OSRDCH
		sta		$75
		rts

L8166:		lda		#$8A
		ldx		L8634
		jsr		OSBYTE
		rts

L816F:		cmp		#$80
		bcc		L818B
		asl		A
		tax
		pha
		ldy		L818C,X
		beq		L8185
		ldy		#$1B
		jsr		L8166
		ldy		#$6F
		jsr		L8166
L8185:		pla
		tax
		inx
		lda		L818C,X
L818B:		rts

L818C:		.byte		$1B
		.byte		$41
		.byte		$1B
		.byte		$42
		.byte		$1B
		.byte		$43
		.byte		$1B
		.byte		$44
		.byte		$1B
		.byte		$45
		.byte		$1B
		.byte		$46
		.byte		$1B
		.byte		$47
		.byte		$1B
		.byte		$48
		.byte		$1B
		.byte		$49
		.byte		$1B
		.byte		$4A
		.byte		$00
		.byte		$00
		.byte		$1B
		.byte		$4B
		.byte		$00
		.byte		$02
		.byte		$00
		.byte		$06
		.byte		$00
		.byte		$0E
		.byte		$00
		.byte		$10
		.byte		$1B
		.byte		$61
		.byte		$1B
		.byte		$62
		.byte		$1B
		.byte		$63
		.byte		$1B
		.byte		$64
		.byte		$1B
		.byte		$65
		.byte		$1B
		.byte		$66
		.byte		$1B
		.byte		$67
		.byte		$1B
		.byte		$68
		.byte		$1B
		.byte		$69
		.byte		$1B
		.byte		$6A
		.byte		$00
		.byte		$00
		.byte		$1B
		.byte		$6B
		.byte		$1B
		.byte		$6C
		.byte		$1B
		.byte		$6D
		.byte		$1B
		.byte		$6E
		.byte		$1B
		.byte		$6F
		.byte		$1B
		.byte		$30
		.byte		$1B
		.byte		$31
		.byte		$1B
		.byte		$32
		.byte		$1B
		.byte		$33
		.byte		$1B
		.byte		$34
		.byte		$1B
		.byte		$35
		.byte		$1B
		.byte		$36
		.byte		$1B
		.byte		$37
		.byte		$1B
		.byte		$38
		.byte		$1B
		.byte		$39
		.byte		$00
		.byte		$00
		.byte		$1B
		.byte		$3A
		.byte		$1B
		.byte		$3B
		.byte		$1B
		.byte		$3C
		.byte		$1B
		.byte		$3D
		.byte		$1B
		.byte		$3E

L81EC:		lda		#$86
		jsr		OSBYTE
		stx		$76
		sty		$77
		clc
		lda		#$01
		adc		$8A
		sec
		sbc		$76
		sta		$74
		lda		$75
		cmp		#$7F
		beq		L822E
L8205:		lda		#$87
		jsr		OSBYTE
		txa
		bne		L820F
		lda		#$20
L820F:		pha
		lda		$75
		jsr		OSWRCH
		pla
		sta		$75
		dec		$74
		bne		L8205
		lda		#$1F
		jsr		OSWRCH
		inc		$76
		lda		$76
		jsr		OSWRCH
		lda		$77
		jsr		OSWRCH
		rts

L822E:		lda		$76
		bne		L8233
		rts
L8233:		lda		#$87
		jsr		OSBYTE
		txa
		bne		L823D
		lda		#$20
L823D:		pha
		lda		#$08
		jsr		OSWRCH
		pla
		jsr		OSWRCH
		lda		#$09
		jsr		OSWRCH
		dec		$74
		bne		L8233
		lda		#$08
		jsr		OSWRCH
		lda		#$20
		jsr		OSWRCH
		lda		#$1F
		jsr		OSWRCH
		dec		$76
		lda		$76
		jsr		OSWRCH
		lda		$77
		jsr		OSWRCH
		rts

L826C:		lda		#$81
		ldx		#$FE
		ldy		#$FF
		jsr		OSBYTE
		lda		#$1B
		inx
		beq		L827B
		rts
L827B:		jmp		L8663

L827E:		lda		#$02
		ldx		#$01
		jsr		OSBYTE
		lda		#$80
		ldx		#$FE
		ldy		#$FF
		jsr		OSBYTE
		lda		$86
		bne		L8293
		rts
L8293:		cpx		L8632
		bcc		L82A6
L8298:		lda		$70
		bne		L82B8
		lda		#$01
		sta		$70
		ldy		#$13
		jsr		L8166
		rts
L82A6:		cpx		L8633
		bcs		L82B8
		lda		$70
		beq		L82B8
		lda		#$00
		sta		$70
		ldy		#$11
		jsr		L8166
L82B8:		rts

L82B9:		asl		A
		tax
		lda		JmpTable1,X
		sta		$78
		inx
		lda		JmpTable1,X
		beq		L82CB
		sta		$79
		jmp		($0078)

L82CB:		lda		$75
		and		#$1F
		jsr		OSWRCH
		lda		$78
		bne		L82D7
		rts

L82D7:		jsr		L8120
		jsr		OSWRCH
		dec		$71
		bne		L82D7
		rts

JmpTable1:
		.word		$0000
		.word		$0001
		.word		$0000
		.word		$0000
		.word		$0000
		.word		$0000
		.word		L859F
		.word		$0000
		.word		$0000
		.word		L858D
		.word		$0000
		.word		$0000
		.word		$0000
		.word		$0000
		.word		L8452
		.word		L846E
		.word		L848F
		.word		L83CC
		.word		L83DA
		.word		L849C
		.word		$0000
		.word		L84BD
		.word		L84F6
		.word		$0009
		.word		$0008
		.word		$0005
		.word		$0000
		.word		L8322
		.word		L85AD
		.word		$0004
		.word		$0000

		lda		$85
L8322:		jsr		L8120
		and		#$1F
		asl		A
		tax
		lda		JmpTable2,X
		sta		$78
		inx
		lda		JmpTable2,X
		sta		$79
		jmp		($0078)

JmpTable2:	.word		L8377
		.word		L8377
		.word		L8378
		.word		L8377
		.word		L8393
		.word		L8377
		.word		L8377
		.word		L8377
		.word		L8399
		.word		L83A1
		.word		L8377
		.word		L8377
		.word		L83B1
		.word		L8377
		.word		L8377
		.word		L83A6
		.word		L8377
		.word		L83BC
		.word		L83F0
		.word		L8408
		.word		L841D
		.word		L843D
		.word		L8432
		.word		L8377
		.word		L8522
		.word		L8534
		.word		L8548
		.word		L8377
		.word		L8377
		.word		L855E
		.word		L8377
		.word		L8377

L8377:		rts

L8378:		lda		#$1A
		jsr		OSWRCH
		lda		#$0C
		jsr		OSWRCH
		lda		#$E5
		ldx		#$00
		jsr		OSBYTE
		lda		#$BB
		jsr		OSBYTE
		lda		#$8E
		jmp		OSBYTE

L8393:		lda		#$04
		jsr		OSWRCH
		rts

L8399:		jsr		L8120
		and		#$01
		sta		$86
		rts

L83A1:		lda		#$01
		jmp		L83A8

L83A6:		lda		#$00
L83A8:		sta		$72
		lda		$D0
		eor		#$02
		sta		$D0
		rts

L83B1:		jsr		L8120
		and		#$0F
		sta		$87
		jsr		L85E3
		rts

L83BC:		lda		#$11
		jsr		OSWRCH
		jsr		L8120
		and		#$0F
		eor		#$80
		jsr		OSWRCH
		rts

L83CC:		lda		#$11
		jsr		OSWRCH
		jsr		L8120
		and		#$0F
		jsr		OSWRCH
		rts

L83DA:		lda		#$12
		jsr		OSWRCH
		jsr		L8120
		and		#$07
		jsr		OSWRCH
		jsr		L8120
		and		#$0F
		jsr		OSWRCH
		rts

L83F0:		lda		#$12
		jsr		OSWRCH
		jsr		L8120
		and		#$07
		jsr		OSWRCH
		jsr		L8120
		and		#$0F
		eor		#$80
		jsr		OSWRCH
		rts

L8408:		lda		#$11
		jsr		OSWRCH
		lda		#$00
		jsr		OSWRCH
		lda		#$11
		jsr		OSWRCH
		lda		#$87
		jsr		OSWRCH
		rts

L841D:		lda		#$11
		jsr		OSWRCH
		lda		#$07
		jsr		OSWRCH
		lda		#$11
		jsr		OSWRCH
		lda		#$80
		jsr		OSWRCH
		rts

L8432:		lda		#$07
		sta		$83
		lda		#$00
		sta		$84
		jmp		L8445

L843D:		lda		#$00
		sta		$83
		lda		#$07
		sta		$84
L8445:		ldx		#$0C
		ldy		#$00
L8449:		lda		L864D,Y
		jsr		L85CB
		bne		L8449
		rts

L8452:		lda		#$86
		jsr		OSBYTE
		stx		$7C
		sty		$7B
		sty		$7D
		lda		$89
		sta		$7A
		ldx		#$0B
		ldy		#$00
L8465:		lda		L8635,Y
		jsr		L85CB
		bne		L8465
		rts

L846E:		lda		#$86
		jsr		OSBYTE
		stx		$80
		sty		$7F
		sty		$82
		lda		$89
		sta		$7E
		sec
		sbc		$7F
		sta		$81
		ldx		#$0D
		ldy		#$00
L8486:		lda		L8640,Y
		jsr		L85CB
		bne		L8486
		rts

L848F:		lda		$86
		beq		L8496
		jsr		L8298
L8496:		lda		#$10
		jsr		OSWRCH
		rts

L849C:		lda		#$13
		jsr		OSWRCH
		jsr		L8120
		and		#$0F
		jsr		OSWRCH
		jsr		L8120
		and		#$0F
		jsr		OSWRCH
		lda		#$00
		jsr		OSWRCH
		jsr		OSWRCH
		jsr		OSWRCH
		rts

L84BD:		lda		#$86
		jsr		OSBYTE
		sty		$77
		stx		$76
		clc
		lda		#$01
		adc		$8A
		sec
		sbc		$76
		tax
		beq		L84EE
		jsr		L85DC
L84D4:		lda		#$20
		jsr		OSWRCH
		dex
		bne		L84D4
		jsr		L85DC
		lda		#$1F
		jsr		OSWRCH
		lda		$76
		jsr		OSWRCH
		lda		$77
		jsr		OSWRCH
L84EE:		lda		#$07
		ldx		$87
		jsr		OSBYTE
		rts

L84F6:		lda		#$16
		jsr		OSWRCH
		jsr		L8120
		and		#$07
		sta		$88
		jsr		OSWRCH
		ldx		$88
		lda		L851A,X
		sta		$8A
		lda		L8512,X
		sta		$89
		rts

		; screen mode rows - 1
L8512:		.byte		$1F
		.byte		$1F
		.byte		$1F
		.byte		$18
		.byte		$1F
		.byte		$1F
		.byte		$18
		.byte		$18

		; screen mode cols - 1
L851A:		.byte		$4F
		.byte		$27
		.byte		$13
		.byte		$4F
		.byte		$27
		.byte		$13
		.byte		$27
		.byte		$27

L8522:		lda		#$18
		jsr		OSWRCH
		jsr		L856A
		jsr		L856A
		jsr		L856A
		jsr		L856A
		rts

L8534:		lda		#$19
		jsr		OSWRCH
		jsr		L8120
		and		#$3F
		jsr		OSWRCH
		jsr		L856A
		jsr		L856A
		rts

L8548:		lda		#$19
		jsr		OSWRCH
		jsr		L8120
		and		#$3F
		eor		#$40
		jsr		OSWRCH
		jsr		L856A
		jsr		L856A
		rts

L855E:		lda		#$1D
		jsr		OSWRCH
		jsr		L856A
		jsr		L856A
		rts

L856A:		jsr		L8120
		and		#$3F
		pha
		lsr		A
		lsr		A
		lsr		A
		sta		$76
		pla
		asl		A
		asl		A
		asl		A
		asl		A
		asl		A
		sta		$77
		jsr		L8120
		and		#$1F
		eor		$77
		jsr		OSWRCH
		lda		$76
		jsr		OSWRCH
		rts

L858D:		lda		#$86
		jsr		OSBYTE
		txa
		ora		#$F8
		tax
		lda		#$09
L8598:		jsr		OSWRCH
		inx
		bne		L8598
		rts

L859F:		lda		#$09
		jsr		OSWRCH
		rts
		lda		#$1F
		jsr		OSWRCH
		jmp		L85B8

L85AD:		lda		#$1C
		jsr		OSWRCH
		jsr		L85BF
		jsr		L85BF
L85B8:		jsr		L85BF
		jsr		L85BF
		rts

L85BF:		jsr		L8120
		clc
		adc		#$E0
		and		#$7F
		jsr		OSWRCH
		rts

L85CB:		bpl		L85D6
		and		#$1F
		stx		$85
		tax
		lda		$70,X
		ldx		$85
L85D6:		jsr		OSWRCH
		iny
		dex
		rts

L85DC:		lda		$D0
		eor		#$02
		sta		$D0
		rts

L85E3:		lda		#$08
		ldx		$87
		jsr		OSBYTE
		lda		#$07
		ldx		$87
		jsr		OSBYTE
		rts

L85F2:		lda		#$08
		ldx		L8622
		ldy		L8623
		jsr		OSWORD
		lda		#$D3
		ldx		#$01
		ldy		#$00
		jsr		OSBYTE
		lda		#$D4
		ldx		#$00
		ldy		#$00
		jsr		OSBYTE
		lda		#$D5
		ldx		#$84
		ldy		#$00
		jsr		OSBYTE
		lda		#$D6
		ldx		#$0A
		ldy		#$00
		jsr		OSBYTE
		rts

L8622:		.byte		$24
L8623:		.byte		$86
		.byte		$01
		.byte		$01
		.byte		$00
		.byte		$00
		.byte		$00
		.byte		$00
		.byte		$00
		.byte		$00
		.byte		$64
		.byte		$FB
		.byte		$FD
		.byte		$FF
		.byte		$7D
		.byte		$5A
L8632:		.byte		$C8
L8633:		.byte		$32
L8634:		.byte		$02
L8635:		.byte		$1C
		.byte		$00
		.byte		$8A
		.byte		$9A
		.byte		$8B
		.byte		$1E
		.byte		$0B
		.byte		$1A
		.byte		$1F
		.byte		$8C
		.byte		$8D

L8640:		.byte		$1C
		.byte		$00
		.byte		$8E
		.byte		$9A
		.byte		$8F
		.byte		$1F
		.byte		$00
		.byte		$91
		.byte		$0A
		.byte		$1A
		.byte		$1F
		.byte		$90
		.byte		$92

L864D:		.byte		$13
		.byte		$00
		.byte		$93
		.byte		$00
		.byte		$00
		.byte		$00
		.byte		$13
		.byte		$07
		.byte		$94
		.byte		$00
		.byte		$00
		.byte		$00

L8659:		.byte		$17
		.byte		$60
		.byte		$30
		.byte		$18
		.byte		$0C
		.byte		$00
		.byte		$00
		.byte		$00
		.byte		$00
		.byte		$00

L8663:		ldx		#$00
		jsr		L86E3
L8668:		ldx		#$9E
		jsr		L86E3
		lda		$88
		clc
		adc		#$30
		jsr		OSWRCH
		ldx		#$A2
		jsr		L86E3
		lda		$87
		asl		A
		clc
		adc		$87
		asl		A
		clc
		adc		#$A0
		tax
		jsr		L86E3
		ldx		#$D6
		jsr		L86E3
		lda		$86
		beq		L8696
		ldx		#$E3
		jmp		L8698
L8696:		ldx		#$DA
L8698:		jsr		L86E3
L869B:		lda		#$02
		ldx		#$02
		jsr		OSBYTE
		jsr		OSRDCH
		and		#$5F
		cmp		#$4D
		beq		L86BE
		cmp		#$4C
		beq		L86C9
		cmp		#$48
		beq		L86D4
		cmp		#$42
		beq		L86DD
		cmp		#$1B
		beq		L86E0
		jmp		L869B
L86BE:		ldx		$88
		inx
		txa
		and		#$07
		sta		$88
		jmp		L8668
L86C9:		lda		$87
		and		#$07
		tax
		inx
		stx		$87
		jmp		L8668
L86D4:		lda		$86
		eor		#$01
		sta		$86
		jmp		L8668
L86DD:		jmp		L8378
L86E0:		jmp		L809C

L86E3:		lda		L86F0,X
		beq		L86EF
		jsr		OSWRCH
		inx
		jmp		L86E3
L86EF:		rts

L86F0:		.byte		22,7,31
		.byte		9,1
		.byte		"Unix Terminal Emulator"
		.byte		31,8,5
		.byte		"M   Screen Mode"
		.byte		31,8,7
		.byte		"L   Line Speed"
		.byte		31,8,9
		.byte		"H   Handshake"
		.byte		31,8,14
		.byte		"B   To BASIC"
		.byte		31,7,18
		.byte		"ESC   Return To Emulator"
		.byte		31,1,24
		.byte		"Use key indicated to toggle or act"
		.byte		0
		.byte		31,25,5,0
		.byte		31,25,7,0
		.byte		"75   ",0
		.byte		"150  ",0
		.byte		"300  ",0
		.byte		"1200 ",0
		.byte		"2400 ",0
		.byte		"4800 ",0
		.byte		"9600 ",0
		.byte		"19200",0
		.byte		31,25,9,0
		.byte		"hardware",0
		.byte		"xon/xoff",0

		.repeat		$8800 - *
		.byte		$00
		.endrep

		.repeat		$a000 - *
		.byte		$ff
		.endrep
