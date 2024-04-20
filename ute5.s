; vim: ts=8:sw=8

;
; BBC MOS Entry Points
;
		OSRDCH  	:= $FFE0
		OSASCI		:= $FFE3
		OSNEWL		:= $FFE7
		OSWRCH		:= $FFEE
		OSWORD		:= $FFF1
		OSBYTE		:= $FFF4

;
; Zero page variables
;
		_cursor_x	:= $76
		_cursor_y	:= $77
		_jmp_vec	:= $78
		_baud		:= $87
		_mode		:= $88
		_rows		:= $89
		_cols		:= $8A

;
; Other constants
;
		ESC		= $1B

		VDU_RIGHT	= 9
		VDU_MODE	= 22
		VDU_GVIEWPORT	= 24
		VDU_PLOT	= 25
		VDU_ORIGIN	= 29
		VDU_TAB_XY	= 31

		BAUD_9600	= 7

.segment "STARTUP"

.segment "CODE"

.org		$8000

.scope		Header

		jmp		LangEntry		; language entry
		jmp		ServiceEntry		; service entry

		.byte		$c2			; ROM type
		.byte		<Copyright - 1		; (C) pointer
		.byte		$05			; major version

Title:		.byte		"Unix terminal emulator *UTE5",0,0
Copyright:	.byte		"(C) Clive D. Rodgers 1985",0

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

		; enter language ROM
L8074:		lda		#$8e
		ldx		$f4
		jsr		OSBYTE

.endproc

L807B:		.byte		"UTE5", $ff

.proc		LangEntry

		cli

		; initialise stack
		ldx		#$FF
		txs

		; set default parameters
		lda		#$00
		sta		$70
		sta		$72
		sta		$73
		sta		$86
		sta		_mode

		; set initial baud rate
		lda		#BAUD_9600
		sta		_baud

		; set screen size
		lda		#32 - 1
		sta		_rows
		lda		#80 - 1
		sta		_cols

L809C:		jsr		SetSerialRate

		lda		#$E5
		ldx		#$01
		ldy		#$00
		jsr		OSBYTE

		; set display mode
		lda		#VDU_MODE
		jsr		OSWRCH
		lda		_mode
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
		jsr		SetupBell
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
.endproc

L8120:		; read serial output buffer status
		lda		#$80
		ldx		#$FD
		ldy		#$FF
		jsr		OSBYTE
		cpx		#$02
		bcc		L8152

		; read keyboard buffer status
		lda		#$80
		ldx		#$FF
		ldy		#$FF
		jsr		OSBYTE
		cpx		#$01
		bcc		L8152

		; enable keyboard and serial and read character
		lda		#$02
		ldx		#$02
		jsr		OSBYTE
		jsr		OSRDCH

		cmp		#ESC
		bne		L814B
		jsr		L826C
L814B:		jsr		L816F
		tay
		jsr		WriteBuffer

L8152:		jsr		L827E
		cpx		#$01
		bcc		L8120

		; enable serial and read character
		lda		#$02
		ldx		#$01
		jsr		OSBYTE
		jsr		OSRDCH
		sta		$75

		rts

.proc		WriteBuffer

		lda		#$8A
		ldx		_buffer_num
		jsr		OSBYTE
		rts

.endproc

L816F:		cmp		#$80
		bcc		L818B
		asl		A
		tax
		pha
		ldy		L818C,X
		beq		L8185

		ldy		#ESC
		jsr		WriteBuffer
		ldy		#'o'
		jsr		WriteBuffer

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

L81EC:		; get cursor position
		lda		#$86
		jsr		OSBYTE
		stx		_cursor_x
		sty		_cursor_y

		clc
		lda		#$01
		adc		_cols
		sec
		sbc		_cursor_x
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

		; move cursor right
		lda		#VDU_TAB_XY
		jsr		OSWRCH
		inc		_cursor_x
		lda		_cursor_x
		jsr		OSWRCH
		lda		_cursor_y
		jsr		OSWRCH
		rts

L822E:		lda		_cursor_x
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

		; move cursor left
		lda		#VDU_TAB_XY
		jsr		OSWRCH
		dec		_cursor_x
		lda		_cursor_x
		jsr		OSWRCH
		lda		_cursor_y
		jsr		OSWRCH
		rts

.proc		L826C

		; test CTRL key
		lda		#$81
		ldx		#$FE
		ldy		#$FF
		jsr		OSBYTE

		lda		#$1B
		inx
		beq		L827B
		rts
L827B:		jmp		L8663

.endproc

L827E:		; enable serial input
		lda		#$02
		ldx		#$01
		jsr		OSBYTE

		; check for control key
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
		jsr		WriteBuffer
		rts
L82A6:		cpx		L8633
		bcs		L82B8
		lda		$70
		beq		L82B8
		lda		#$00
		sta		$70
		ldy		#$11
		jsr		WriteBuffer
L82B8:		rts

.proc		L82B9
		asl		A
		tax
		lda		_jmp_table1,X
		sta		_jmp_vec
		inx
		lda		_jmp_table1,X
		beq		L82CB
		sta		_jmp_vec + 1
		jmp		(_jmp_vec)

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
.endproc

_jmp_table1:
		.word		$0000
		.word		$0001
		.word		$0000
		.word		$0000
		.word		$0000
		.word		$0000
		.word		L859F
		.word		$0000
		.word		$0000
		.word		Tabstop
		.word		$0000
		.word		$0000
		.word		$0000
		.word		$0000
		.word		L8452
		.word		L846E
		.word		L848F
		.word		SetForeground
		.word		L83DA
		.word		SetPalette
		.word		$0000
		.word		L84BD
		.word		SetMode
		.word		$0009
		.word		$0008
		.word		$0005
		.word		$0000
		.word		L8322
		.word		L85AD
		.word		$0004
		.word		$0000
		.word		L85A5

L8322:		jsr		L8120
		and		#$1F
		asl		A
		tax
		lda		_jmp_table_2,X
		sta		_jmp_vec
		inx
		lda		_jmp_table_2,X
		sta		_jmp_vec + 1
		jmp		(_jmp_vec)

_jmp_table_2:	.word		L8377
		.word		L8377
		.word		StartBASIC
		.word		L8377
		.word		SetTextMode
		.word		L8377
		.word		L8377
		.word		L8377
		.word		L8399
		.word		L83A1
		.word		L8377
		.word		L8377
		.word		SetBaud
		.word		L8377
		.word		L8377
		.word		L83A6
		.word		L8377
		.word		SetBackground
		.word		L83F0
		.word		SetTextInverse
		.word		SetTextDefault
		.word		L843D
		.word		L8432
		.word		L8377
		.word		SetGViewport
		.word		PlotLine
		.word		PlotPoint
		.word		L8377
		.word		L8377
		.word		SetOrigin
		.word		L8377
		.word		L8377

L8377:		rts

.proc		StartBASIC

		; reset viewports
		lda		#$1A
		jsr		OSWRCH

		; clear screen
		lda		#$0C
		jsr		OSWRCH

		; set escape
		lda		#$E5
		ldx		#$00
		jsr		OSBYTE

		; get BASIC ROM slot number
		lda		#$BB
		jsr		OSBYTE

		; start the BASIC ROM
		lda		#$8E
		jmp		OSBYTE

.endproc

.proc		SetTextMode

		lda		#$04
		jsr		OSWRCH
		rts

.endproc

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

.proc		SetBaud

		jsr		L8120
		and		#$0F
		sta		_baud
		jsr		SetSerialRate
		rts

.endproc

.proc		SetBackground

		lda		#$11
		jsr		OSWRCH
		jsr		L8120
		and		#$0F
		eor		#$80
		jsr		OSWRCH
		rts

.endproc

.proc		SetForeground

		lda		#$11
		jsr		OSWRCH
		jsr		L8120
		and		#$0F
		jsr		OSWRCH
		rts

.endproc

		; gcol foreground
L83DA:		lda		#$12
		jsr		OSWRCH
		jsr		L8120
		and		#$07
		jsr		OSWRCH
		jsr		L8120
		and		#$0F
		jsr		OSWRCH
		rts

		; gcol background
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

.proc		SetTextInverse
		lda		#$11
		jsr		OSWRCH
		lda		#$00
		jsr		OSWRCH
		lda		#$11
		jsr		OSWRCH
		lda		#$87
		jsr		OSWRCH
		rts
.endproc

.proc		SetTextDefault

		lda		#$11
		jsr		OSWRCH
		lda		#$07
		jsr		OSWRCH
		lda		#$11
		jsr		OSWRCH
		lda		#$80
		jsr		OSWRCH
		rts

.endproc

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

L8452:		; get cursor position
		lda		#$86
		jsr		OSBYTE
		stx		$7C
		sty		$7B

		sty		$7D
		lda		_rows
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
		lda		_rows
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

.proc		SetPalette

		lda		#$13
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

.endproc

L84BD:		; get current cursor position
		lda		#$86
		jsr		OSBYTE
		sty		_cursor_y
		stx		_cursor_x

		clc
		lda		#$01
		adc		_cols
		sec
		sbc		_cursor_x
		tax
		beq		L84EE
		jsr		L85DC
L84D4:		lda		#' '
		jsr		OSWRCH
		dex
		bne		L84D4
		jsr		L85DC

		; reset cursor position
		lda		#VDU_TAB_XY
		jsr		OSWRCH
		lda		_cursor_x
		jsr		OSWRCH
		lda		_cursor_y
		jsr		OSWRCH

L84EE:		; set serial receive rate
		lda		#$07
		ldx		_baud
		jsr		OSBYTE
		rts

.proc		SetMode

		lda		#VDU_MODE
		jsr		OSWRCH

		jsr		L8120
		and		#$07
		sta		_mode
		jsr		OSWRCH

		ldx		_mode
		lda		_mode_cols,X
		sta		_cols
		lda		_mode_rows,X
		sta		_rows
		rts

.endproc

		; screen mode rows - 1
_mode_rows:	.byte		32 - 1
		.byte		32 - 1
		.byte		32 - 1
		.byte		25 - 1
		.byte		32 - 1
		.byte		32 - 1
		.byte		25 - 1
		.byte		25 - 1

		; screen mode cols - 1
_mode_cols:	.byte		80 - 1
		.byte		40 - 1
		.byte		20 - 1
		.byte		80 - 1
		.byte		40 - 1
		.byte		20 - 1
		.byte		40 - 1
		.byte		40 - 1

.proc		SetGViewport

		lda		#VDU_GVIEWPORT
		jsr		OSWRCH
		jsr		ReadCoord
		jsr		ReadCoord
		jsr		ReadCoord
		jsr		ReadCoord
		rts

.endproc

.proc		PlotLine

		lda		#VDU_PLOT
		jsr		OSWRCH
		jsr		L8120
		and		#$3F
		jsr		OSWRCH
		jsr		ReadCoord
		jsr		ReadCoord
		rts

.endproc

.proc		PlotPoint

		lda		#VDU_PLOT
		jsr		OSWRCH
		jsr		L8120
		and		#$3F
		eor		#$40
		jsr		OSWRCH
		jsr		ReadCoord
		jsr		ReadCoord
		rts

.endproc

.proc		SetOrigin

		lda		#VDU_ORIGIN
		jsr		OSWRCH
		jsr		ReadCoord
		jsr		ReadCoord
		rts

.endproc

.proc		ReadCoord

		jsr		L8120
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

.endproc

.proc		Tabstop

		lda		#$86
		jsr		OSBYTE
		txa
		ora		#$F8
		tax
		lda		#VDU_RIGHT
@loop:		jsr		OSWRCH
		inx
		bne		@loop
		rts

.endproc

L859F:		lda		#$09
		jsr		OSWRCH
		rts

L85A5:		lda		#VDU_TAB_XY
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

.proc		SetSerialRate

		; set serial transmit rate
		lda		#$08
		ldx		_baud
		jsr		OSBYTE

		; set serial receive rate
		lda		#$07
		ldx		_baud
		jsr		OSBYTE
		rts

.endproc

.proc		SetupBell

		; set envelope
		lda		#$08
		ldx		_env_ptr
		ldy		_env_ptr + 1
		jsr		OSWORD

		; set bell to channel 1
		lda		#$D3
		ldx		#$01
		ldy		#$00
		jsr		OSBYTE

		; select envelope 1 for bell
		lda		#$D4
		ldx		#$00
		ldy		#$00
		jsr		OSBYTE

		; set bell frequency
		lda		#$D5
		ldx		#$84
		ldy		#$00
		jsr		OSBYTE

		; set bell duration
		lda		#$D6
		ldx		#$0A
		ldy		#$00
		jsr		OSBYTE
		rts

.endproc

_env_ptr:	.word		* + 2
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
_buffer_num:	.byte		$02

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

L8663:		ldx		#(_strings - _strings)
		jsr		OutString

L8668:		; tab to 25, 5
		ldx		#(_s_tab_25_5 - _strings)
		jsr		OutString

		; show the screen mode
		lda		_mode
		clc
		adc		#'0'
		jsr		OSWRCH

		; tab to 25, 7
		ldx		#(_s_tab_25_7 - _strings)
		jsr		OutString

		; display baud rate
		lda		_baud
		asl		A
		clc
		adc		_baud
		asl		A
		clc
		adc		#(_s_baud_table - _strings) - 6
		tax
		jsr		OutString

		; tab to 25, 9
		ldx		#(_s_tab_25_9 - _strings)
		jsr		OutString

		; show flow control
		lda		$86
		beq		@hardware
		ldx		#(_s_xon_xoff - _strings)
		jmp		@handshake
@hardware:	ldx		#(_s_hardware - _strings)
@handshake:	jsr		OutString

@loop:		; enable keyboard and serial input and read a keyboard character
		lda		#$02
		ldx		#$02
		jsr		OSBYTE
		jsr		OSRDCH

		; mask off 0x20 (lower case)
		and		#$5F

		cmp		#'M'
		beq		@set_mode

		cmp		#'L'
		beq		@set_speed

		cmp		#'H'
		beq		@set_handshake

		cmp		#'B'
		beq		@basic

		cmp		#ESC
		beq		@emulator

		jmp		@loop

@set_mode:	ldx		$88
		inx
		txa
		and		#$07
		sta		$88
		jmp		L8668

@set_speed:	lda		_baud
		and		#$07
		tax
		inx
		stx		$87
		jmp		L8668

@set_handshake:	lda		$86
		eor		#$01
		sta		$86
		jmp		L8668

@basic:		jmp		StartBASIC

@emulator:	jmp		LangEntry::L809C

.proc		OutString

@loop:		lda		_strings,X
		beq		@exit
		jsr		OSWRCH
		inx
		jmp		@loop
@exit:		rts

.endproc

_strings:	.byte		VDU_MODE,7
		.byte		VDU_TAB_XY,9,1
		.byte		"Unix Terminal Emulator"
		.byte		VDU_TAB_XY,8,5
		.byte		"M   Screen Mode"
		.byte		VDU_TAB_XY,8,7
		.byte		"L   Line Speed"
		.byte		VDU_TAB_XY,8,9
		.byte		"H   Handshake"
		.byte		VDU_TAB_XY,8,14
		.byte		"B   To BASIC"
		.byte		VDU_TAB_XY,7,18
		.byte		"ESC   Return To Emulator"
		.byte		VDU_TAB_XY,1,24
		.byte		"Use key indicated to toggle or act"
		.byte		0

_s_tab_25_5:	.byte		VDU_TAB_XY,25,5,0

_s_tab_25_7:	.byte		VDU_TAB_XY,25,7,0

_s_baud_table:	.byte		"75   ",0
		.byte		"150  ",0
		.byte		"300  ",0
		.byte		"1200 ",0
		.byte		"2400 ",0
		.byte		"4800 ",0
		.byte		"9600 ",0
		.byte		"19200",0

_s_tab_25_9:	.byte		VDU_TAB_XY,25,9,0

_s_hardware:	.byte		"hardware",0

_s_xon_xoff:	.byte		"xon/xoff",0

		.repeat		$8800 - *
		.byte		$00
		.endrep

		.repeat		$a000 - *
		.byte		$ff
		.endrep
