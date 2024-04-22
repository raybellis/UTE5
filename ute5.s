;----------------------------------------------------------------------
; vim: ts=8:sw=8
;----------------------------------------------------------------------
;
; BBC MOS Entry Points
;
		OSRDCH  	:= $FFE0
		OSASCI		:= $FFE3
		OSNEWL		:= $FFE7
		OSWRCH		:= $FFEE
		OSWORD		:= $FFF1
		OSBYTE		:= $FFF4

;----------------------------------------------------------------------
;
; BBC MOS Variables
;
		OS_VDU_STATUS	:= $D0
		VEC_STAR_CMD	:= $F2

;----------------------------------------------------------------------
;
; Zero page variables
;
		_xoff		:= $70
		_next		:= $75
		_cursor_x	:= $76
		_cursor_y	:= $77
		_jmp_vec	:= $78
		_var_7A		:= $7A
		_var_7B		:= $7B
		_var_7C		:= $7C
		_var_7D		:= $7D
		_var_7E		:= $7E
		_var_7F		:= $7F
		_var_80		:= $80
		_var_81		:= $81
		_var_82		:= $82
		_palette_fg	:= $83
		_palette_bg	:= $84
		_handshake	:= $86
		_baud		:= $87
		_mode		:= $88
		_rows		:= $89
		_cols		:= $8A

;----------------------------------------------------------------------
;
; Other constants
;
		XON		= $11
		XOFF		= $13
		ESC		= $1B

		VDU_TEXT	= 4
		VDU_LEFT	= 8
		VDU_RIGHT	= 9
		VDU_DOWN	= 10
		VDU_UP		= 11
		VDU_CLS		= 12
		VDU_CLG		= 16
		VDU_COLOUR	= 17
		VDU_GCOL	= 18
		VDU_PALETTE	= 19
		VDU_MODE	= 22
		VDU_GVIEWPORT	= 24
		VDU_23		= 23
		VDU_PLOT	= 25
		VDU_RESTORE	= 26
		VDU_VIEWPORT	= 28
		VDU_ORIGIN	= 29
		VDU_HOME	= 30
		VDU_TAB_XY	= 31

		BAUD_9600	= 7

;----------------------------------------------------------------------

.segment "STARTUP"

.segment "CODE"

;----------------------------------------------------------------------

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

;----------------------------------------------------------------------

.proc		ServiceEntry

		pha

		cmp		#$09
		beq		@help

		cmp		#$04
		beq		@star

		pla
		rts

@help:		ldx		#$ff
@l1:		inx
		lda		Header::Title,x
		jsr		OSASCI
		bne		@l1

		jsr		OSNEWL
		pla
		rts

@star:   	tya
		pha
		txa
		pha

		ldx		#$ff
		dey
@l2:	    	inx
		iny
		lda		_ute5,X
		bmi		@start
		cmp		(VEC_STAR_CMD),Y
		beq		@l2

		pla
		tax
		pla
		tay
		pla
		rts

		; enter language ROM
@start:		lda		#$8e
		ldx		$F4
		jsr		OSBYTE

_ute5:		.byte		"UTE5", $FF

.endproc

;----------------------------------------------------------------------

.proc		LangEntry

		; enable interrupts
		cli

		; initialise stack
		ldx		#$FF
		txs

		; set default parameters
		lda		#$00
		sta		_xoff
		sta		$72
		sta		$73
		sta		_handshake
		sta		_mode

		; set initial baud rate
		lda		#BAUD_9600
		sta		_baud

		; set screen size
		lda		#32 - 1
		sta		_rows
		lda		#80 - 1
		sta		_cols

Main:		jsr		SetSerialRate

		; set ESC mode to ASCII
		lda		#$E5
		ldx		#$01
		ldy		#$00
		jsr		OSBYTE

		; set display mode
		lda		#VDU_MODE
		jsr		OSWRCH
		lda		_mode
		jsr		OSWRCH

		; flush all buffers
		lda		#$0F
		ldx		#$00
		jsr		OSBYTE

		; set keyboard status
		lda		#$CA
		ldx		#$30
		jsr		OSBYTE

		; disable cursor editing
		ldx		#$02
		lda		#$04
		jsr		OSBYTE

		; set function key status
		ldy		#$00
		ldx		#$80
		lda		#$E1
		jsr		OSBYTE

		; set shift function key status
		ldy		#$00
		ldx		#$90
		lda		#$E2
		jsr		OSBYTE

		; set control function key status
		ldy		#$00
		ldx		#$A0
		lda		#$E3
		jsr		OSBYTE

		; set shift-control function key status
		ldy		#$00
		ldx		#$01
		lda		#$E4
		jsr		OSBYTE

		; explode soft chars $A0 - $BF
		lda		#$14
		ldx		#$01
		jsr		OSBYTE

		jsr		SetupBell

		; define the back-tick soft character
		ldx		#$0A
		ldy		#$00
@l1:		lda		_s_set_char,Y
		jsr		OutVarChar
		bne		@l1

		; main input processing loop
@mainloop:	jsr		GetNext
		and		#$7F
		cmp		#' '
		bcs		@l2
		jsr		L82B9
		jmp		@mainloop

@l2:		ldx		$72
		bne		@l3
		jsr		OSWRCH
		jmp		@mainloop

@l3:		jsr		L81EC
		jmp		@mainloop

.endproc

;----------------------------------------------------------------------

.proc		GetNext

		; read serial output buffer status
		lda		#$80
		ldx		#$FD
		ldy		#$FF
		jsr		OSBYTE
		cpx		#$02
		bcc		@no_data

		; read keyboard buffer status
		lda		#$80
		ldx		#$FF
		ldy		#$FF
		jsr		OSBYTE
		cpx		#$01
		bcc		@no_data

		; enable keyboard and serial and read keyboard character
		lda		#$02
		ldx		#$02
		jsr		OSBYTE
		jsr		OSRDCH

		; check if ESC was pressed
		cmp		#ESC
		bne		@not_esc
		jsr		CheckCtrlEsc

@not_esc:	jsr		L816F
		tay
		jsr		WriteToBuffer

@no_data:	jsr		L827E
		cpx		#$01
		bcc		GetNext

		; enable serial and read character
		lda		#$02
		ldx		#$01
		jsr		OSBYTE
		jsr		OSRDCH
		sta		_next

		rts

.endproc

;----------------------------------------------------------------------

.proc		WriteToBuffer

		lda		#$8A
		ldx		_buffer_num
		jsr		OSBYTE
		rts

.endproc

;----------------------------------------------------------------------

.proc		L816F

		cmp		#$80
		bcc		@l2
		asl		A
		tax
		pha
		ldy		@table,X
		beq		@l1

		ldy		#ESC
		jsr		WriteToBuffer
		ldy		#'o'
		jsr		WriteToBuffer

@l1:		pla
		tax
		inx
		lda		@table,X

@l2:		rts

@table:		.byte		$1B,$41
		.byte		$1B,$42
		.byte		$1B,$43
		.byte		$1B,$44
		.byte		$1B,$45
		.byte		$1B,$46
		.byte		$1B,$47
		.byte		$1B,$48
		.byte		$1B,$49
		.byte		$1B,$4A
		.byte		$00,$00
		.byte		$1B,$4B
		.byte		$00,$02
		.byte		$00,$06
		.byte		$00,$0E
		.byte		$00,$10
		.byte		$1B,$61
		.byte		$1B,$62
		.byte		$1B,$63
		.byte		$1B,$64
		.byte		$1B,$65
		.byte		$1B,$66
		.byte		$1B,$67
		.byte		$1B,$68
		.byte		$1B,$69
		.byte		$1B,$6A
		.byte		$00,$00
		.byte		$1B,$6B
		.byte		$1B,$6C
		.byte		$1B,$6D
		.byte		$1B,$6E
		.byte		$1B,$6F
		.byte		$1B,$30
		.byte		$1B,$31
		.byte		$1B,$32
		.byte		$1B,$33
		.byte		$1B,$34
		.byte		$1B,$35
		.byte		$1B,$36
		.byte		$1B,$37
		.byte		$1B,$38
		.byte		$1B,$39
		.byte		$00,$00
		.byte		$1B,$3A
		.byte		$1B,$3B
		.byte		$1B,$3C
		.byte		$1B,$3D
		.byte		$1B,$3E

.endproc

;----------------------------------------------------------------------

.proc		L81EC

		; get cursor position
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

		lda		_next
		cmp		#$7F
		beq		L822E

@l1:		; read character at cursor
		lda		#$87
		jsr		OSBYTE
		txa

		; if unknown replace with space
		bne		@l2
		lda		#' '

@l2:		pha
		lda		_next
		jsr		OSWRCH
		pla
		sta		_next
		dec		$74
		bne		@l1

		; move cursor right
		lda		#VDU_TAB_XY
		jsr		OSWRCH
		inc		_cursor_x
		lda		_cursor_x
		jsr		OSWRCH
		lda		_cursor_y
		jsr		OSWRCH
		rts

.endproc

;----------------------------------------------------------------------

.proc		L822E

		lda		_cursor_x
		bne		L8233
		rts

.endproc

;----------------------------------------------------------------------

.proc		L8233

@l1:		; read character at cursor
		lda		#$87
		jsr		OSBYTE
		txa
		bne		@l2
		lda		#' '

@l2:		pha
		lda		#VDU_LEFT
		jsr		OSWRCH
		pla
		jsr		OSWRCH
		lda		#VDU_RIGHT
		jsr		OSWRCH
		dec		$74
		bne		L8233
		lda		#VDU_LEFT
		jsr		OSWRCH
		lda		#' '
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

.endproc

;----------------------------------------------------------------------

.proc		CheckCtrlEsc

		; test CTRL key
		lda		#$81
		ldx		#$FE
		ldy		#$FF
		jsr		OSBYTE

		; restore ESC to A
		lda		#ESC

		; return if CTRL wasn't pressed
		inx
		beq		@ctrl
		rts

		; otherwise show the settings page
@ctrl:		jmp		ShowSettings

.endproc

;----------------------------------------------------------------------

.proc		L827E

		; enable (only) serial input
		lda		#$02
		ldx		#$01
		jsr		OSBYTE

		; check serial input buffer status
		lda		#$80
		ldx		#$FE
		ldy		#$FF
		jsr		OSBYTE

		lda		_handshake
		bne		@l1
		rts

@l1:		cpx		_buffer_max
		bcc		SendXON

.endproc	; fall through

;----------------------------------------------------------------------

.proc		SendXOFF

		lda		_xoff
		bne		SendXDone

		lda		#$01
		sta		_xoff

		; send XOFF
		ldy		#XOFF
		jsr		WriteToBuffer
		rts

.endproc

.proc		SendXON

		cpx		_buffer_min
		bcs		SendXDone

		lda		_xoff
		beq		SendXDone

		lda		#$00
		sta		_xoff

		; send XON
		ldy		#XON
		jsr		WriteToBuffer

.endproc

SendXDone:	rts


;----------------------------------------------------------------------

.proc		L82B9
		asl		A
		tax
		lda		@jmp,X
		sta		_jmp_vec
		inx
		lda		@jmp,X
		beq		@l1
		sta		_jmp_vec + 1
		jmp		(_jmp_vec)

@l1:		lda		_next
		and		#$1F
		jsr		OSWRCH
		lda		_jmp_vec
		bne		@l2
		rts

@l2:		jsr		GetNext
		jsr		OSWRCH
		dec		$71
		bne		@l2
		rts

@jmp:
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
		.word		SetGForeground
		.word		SetPalette
		.word		$0000
		.word		L84BD
		.word		SetMode
		.word		$0009
		.word		$0008
		.word		$0005
		.word		$0000
		.word		L8322
		.word		SetViewport
		.word		$0004
		.word		$0000
		.word		L85A5

.endproc

;----------------------------------------------------------------------

.proc		L8322

		jsr		GetNext
		and		#$1F
		asl		A
		tax
		lda		@jmp,X
		sta		_jmp_vec
		inx
		lda		@jmp,X
		sta		_jmp_vec + 1
		jmp		(_jmp_vec)

@jmp:		.word		Noop
		.word		Noop
		.word		StartBASIC
		.word		Noop
		.word		SetTextMode
		.word		Noop
		.word		Noop
		.word		Noop
		.word		L8399
		.word		L83A1
		.word		Noop
		.word		Noop
		.word		SetBaud
		.word		Noop
		.word		Noop
		.word		L83A6
		.word		Noop
		.word		SetBackground
		.word		SetGBackground
		.word		SetTextInverse
		.word		SetTextDefault
		.word		SetPaletteInverse
		.word		SetPaletteDefault
		.word		Noop
		.word		SetGViewport
		.word		PlotLine
		.word		PlotPoint
		.word		Noop
		.word		Noop
		.word		SetOrigin
		.word		Noop
		.word		Noop

Noop:		rts

.endproc

;----------------------------------------------------------------------

.proc		StartBASIC

		; reset viewports
		lda		#VDU_RESTORE
		jsr		OSWRCH

		; clear screen
		lda		#VDU_CLS
		jsr		OSWRCH

		; set default escape mode
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

;----------------------------------------------------------------------

.proc		SetTextMode

		lda		#VDU_TEXT
		jsr		OSWRCH
		rts

.endproc

;----------------------------------------------------------------------

.proc		L8399

		jsr		GetNext
		and		#$01
		sta		_handshake
		rts

.endproc

;----------------------------------------------------------------------

.proc		L83A1

		lda		#$01
		jmp		L83A8

.endproc	; fallthrough

;----------------------------------------------------------------------

.proc		L83A6

		lda		#$00

.endproc	; fallthrough

;----------------------------------------------------------------------

.proc		L83A8

		sta		$72
		lda		OS_VDU_STATUS
		eor		#$02
		sta		OS_VDU_STATUS
		rts

.endproc

;----------------------------------------------------------------------

.proc		SetBaud

		jsr		GetNext
		and		#$0F
		sta		_baud
		jsr		SetSerialRate
		rts

.endproc

;----------------------------------------------------------------------

.proc		SetBackground

		lda		#VDU_COLOUR
		jsr		OSWRCH
		jsr		GetNext
		and		#$0F
		eor		#$80
		jsr		OSWRCH
		rts

.endproc

;----------------------------------------------------------------------

.proc		SetForeground

		lda		#VDU_COLOUR
		jsr		OSWRCH
		jsr		GetNext
		and		#$0F
		jsr		OSWRCH
		rts

.endproc

;----------------------------------------------------------------------

.proc		SetGForeground

		lda		#VDU_GCOL
		jsr		OSWRCH
		jsr		GetNext
		and		#$07
		jsr		OSWRCH
		jsr		GetNext
		and		#$0F
		jsr		OSWRCH
		rts

.endproc

;----------------------------------------------------------------------

.proc		SetGBackground

		lda		#VDU_GCOL
		jsr		OSWRCH
		jsr		GetNext
		and		#$07
		jsr		OSWRCH
		jsr		GetNext
		and		#$0F
		eor		#$80
		jsr		OSWRCH
		rts

.endproc

;----------------------------------------------------------------------

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

;----------------------------------------------------------------------

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

;----------------------------------------------------------------------

.proc		SetPaletteDefault

		lda		#$07
		sta		_palette_fg
		lda		#$00
		sta		_palette_bg
		jmp		WritePalette

.endproc

;----------------------------------------------------------------------

.proc		SetPaletteInverse

		lda		#$00
		sta		_palette_fg
		lda		#$07
		sta		_palette_bg

.endproc

;----------------------------------------------------------------------

.proc		WritePalette

		ldx		#$0C
		ldy		#$00
@loop:		lda		_s_set_palette,Y
		jsr		OutVarChar
		bne		@loop
		rts

.endProc

;----------------------------------------------------------------------

.proc		L8452
		; get cursor position
		lda		#$86
		jsr		OSBYTE
		stx		_var_7C
		sty		_var_7B
		sty		$7D
		lda		_rows
		sta		_var_7A

		ldx		#$0B
		ldy		#$00
@loop:		lda		L8635,Y
		jsr		OutVarChar
		bne		@loop
		rts

.endproc

;----------------------------------------------------------------------

.proc		L846E

		; get cursor position
		lda		#$86
		jsr		OSBYTE
		stx		$80
		sty		_var_7F
		sty		$82
		lda		_rows
		sta		_var_7E
		sec
		sbc		_var_7F
		sta		$81
		ldx		#$0D
		ldy		#$00
@loop:		lda		L8640,Y
		jsr		OutVarChar
		bne		@loop
		rts

.endproc

;----------------------------------------------------------------------

.proc		L848F

		lda		_handshake
		beq		@l1
		jsr		SendXOFF

@l1:		lda		#VDU_CLG
		jsr		OSWRCH
		rts

.endproc

;----------------------------------------------------------------------

.proc		SetPalette

		lda		#$13
		jsr		OSWRCH
		jsr		GetNext
		and		#$0F
		jsr		OSWRCH
		jsr		GetNext
		and		#$0F
		jsr		OSWRCH
		lda		#$00
		jsr		OSWRCH
		jsr		OSWRCH
		jsr		OSWRCH
		rts

.endproc

;----------------------------------------------------------------------

.proc		L84BD

		; get current cursor position
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
		beq		@l1

		jsr		ToggleScroll
@loop:		lda		#' '
		jsr		OSWRCH
		dex
		bne		@loop
		jsr		ToggleScroll

		; reset cursor position
		lda		#VDU_TAB_XY
		jsr		OSWRCH
		lda		_cursor_x
		jsr		OSWRCH
		lda		_cursor_y
		jsr		OSWRCH

@l1:		; set serial receive rate
		lda		#$07
		ldx		_baud
		jsr		OSBYTE
		rts

.endproc

;----------------------------------------------------------------------

.proc		SetMode

		lda		#VDU_MODE
		jsr		OSWRCH

		jsr		GetNext
		and		#$07
		sta		_mode
		jsr		OSWRCH

		ldx		_mode
		lda		_mode_cols,X
		sta		_cols
		lda		_mode_rows,X
		sta		_rows
		rts

_mode_rows:	.byte		32 - 1
		.byte		32 - 1
		.byte		32 - 1
		.byte		25 - 1
		.byte		32 - 1
		.byte		32 - 1
		.byte		25 - 1
		.byte		25 - 1

_mode_cols:	.byte		80 - 1
		.byte		40 - 1
		.byte		20 - 1
		.byte		80 - 1
		.byte		40 - 1
		.byte		20 - 1
		.byte		40 - 1
		.byte		40 - 1

.endproc

;----------------------------------------------------------------------

.proc		SetGViewport

		lda		#VDU_GVIEWPORT
		jsr		OSWRCH
		jsr		GetCoord
		jsr		GetCoord
		jsr		GetCoord
		jsr		GetCoord
		rts

.endproc

;----------------------------------------------------------------------

.proc		PlotLine

		lda		#VDU_PLOT
		jsr		OSWRCH
		jsr		GetNext
		and		#$3F
		jsr		OSWRCH
		jsr		GetCoord
		jsr		GetCoord
		rts

.endproc

;----------------------------------------------------------------------

.proc		PlotPoint

		lda		#VDU_PLOT
		jsr		OSWRCH
		jsr		GetNext
		and		#$3F
		eor		#$40
		jsr		OSWRCH
		jsr		GetCoord
		jsr		GetCoord
		rts

.endproc

;----------------------------------------------------------------------

.proc		SetOrigin

		lda		#VDU_ORIGIN
		jsr		OSWRCH
		jsr		GetCoord
		jsr		GetCoord
		rts

.endproc

;----------------------------------------------------------------------

.proc		GetCoord

		jsr		GetNext
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
		jsr		GetNext
		and		#$1F
		eor		$77
		jsr		OSWRCH
		lda		$76
		jsr		OSWRCH
		rts

.endproc

;----------------------------------------------------------------------

.proc		Tabstop

		; get cursor position
		lda		#$86
		jsr		OSBYTE

		; calculate 8 - (x % 8) and move cursor right that many times
		txa
		ora		#$F8
		tax
		lda		#VDU_RIGHT
@loop:		jsr		OSWRCH
		inx
		bne		@loop
		rts

.endproc

;----------------------------------------------------------------------

.proc		L859F

		lda		#VDU_RIGHT
		jsr		OSWRCH
		rts

.endproc

;----------------------------------------------------------------------

.proc		L85A5

		lda		#VDU_TAB_XY
		jsr		OSWRCH
		jmp		L85B8

.endproc

;----------------------------------------------------------------------

.proc		SetViewport

		lda		#VDU_VIEWPORT
		jsr		OSWRCH
		jsr		L85BF
		jsr		L85BF

.endproc	; fallthrough

;----------------------------------------------------------------------

.proc		L85B8

		jsr		L85BF
		jsr		L85BF
		rts

.endproc

;----------------------------------------------------------------------

.proc		L85BF

		jsr		GetNext
		clc
		adc		#$E0
		and		#$7F
		jsr		OSWRCH
		rts

.endproc

;----------------------------------------------------------------------
;
; Outputs the character in A, except that if A is >= $80
; it outputs the contents of the memory $70 + (A & $1F)
;
; On exit, Y is incremented (for indexed addressing into
; the string in memory) and X is decremented, for loop
; termination
;
.proc		OutVarChar

		bpl		@out
		and		#$1F
		stx		$85
		tax
		lda		$70,X
		ldx		$85
@out:		jsr		OSWRCH
		iny
		dex
		rts

.endproc

;----------------------------------------------------------------------

.proc		ToggleScroll

		lda		OS_VDU_STATUS
		eor		#$02
		sta		OS_VDU_STATUS
		rts

.endproc

;----------------------------------------------------------------------

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

;----------------------------------------------------------------------
;
; Set up the sound system for the BEL alert sound
;
.proc		SetupBell

		; set envelope
		lda		#$08
		ldx		@env
		ldy		@env + 1
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

@env:		.word		* + 2
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

.endproc

;----------------------------------------------------------------------

_buffer_max:	.byte		200
_buffer_min:	.byte		50
_buffer_num:	.byte		$02

;----------------------------------------------------------------------
;
; VarChar strings for use with OutVarChar
;

.macro		varchar		addr
		.byte		(addr - $70) | $80
.endmacro

L8635:		.byte		VDU_VIEWPORT
		.byte		0
		varchar		_var_7A
		varchar		_cols
		varchar		_var_7B
		.byte		VDU_HOME
		.byte		VDU_UP
		.byte		VDU_RESTORE
		.byte		VDU_TAB_XY
		varchar		_var_7C
		varchar		_var_7D

L8640:		.byte		VDU_VIEWPORT
		.byte		0
		varchar		_var_7E
		varchar		_cols
		varchar		_var_7F
		.byte		VDU_TAB_XY
		.byte		0
		varchar		_var_81
		.byte		VDU_DOWN
		.byte		VDU_RESTORE
		.byte		VDU_TAB_XY
		varchar		_var_80
		varchar		_var_82

_s_set_palette:	.byte		VDU_PALETTE
		.byte		0
		varchar		_palette_fg
		.byte		0
		.byte		0
		.byte		0
		.byte		VDU_PALETTE
		.byte		7
		varchar		_palette_bg
		.byte		0
		.byte		0
		.byte		0

_s_set_char:	.byte		VDU_23
		.byte		96
		.byte		%00110000
		.byte		%00011000
		.byte		%00001100
		.byte		%00000000
		.byte		%00000000
		.byte		%00000000
		.byte		%00000000
		.byte		%00000000

;----------------------------------------------------------------------
;
; Changes to MODE 7 and displays a menu with the current settings
;
.proc		ShowSettings

		ldx		#(_strings - _strings)
		jsr		_out

@settings:	; tab to 25, 5
		ldx		#(_s_tab_25_5 - _strings)
		jsr		_out

		; show the screen mode
		lda		_mode
		clc
		adc		#'0'
		jsr		OSWRCH

		; tab to 25, 7
		ldx		#(_s_tab_25_7 - _strings)
		jsr		_out

		; display baud rate
		lda		_baud
		asl		A
		clc
		adc		_baud
		asl		A
		clc
		adc		#(_s_baud_table - _strings) - 6
		tax
		jsr		_out

		; tab to 25, 9
		ldx		#(_s_tab_25_9 - _strings)
		jsr		_out

		; show handshake setting
		lda		_handshake
		beq		@hardware
		ldx		#(_s_xon_xoff - _strings)
		jmp		@handshake
@hardware:	ldx		#(_s_hardware - _strings)
@handshake:	jsr		_out

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
		jmp		@settings

@set_speed:	lda		_baud
		and		#$07
		tax
		inx
		stx		$87
		jmp		@settings

@set_handshake:	lda		_handshake
		eor		#$01
		sta		_handshake
		jmp		@settings

@basic:		jmp		StartBASIC

@emulator:	jmp		LangEntry::Main

;----------------------------------------------------------------------
;
; nested procedure that displays the NUL-terminated
; string at offset X from the _strings label
;
.proc		_out

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

.endproc
		.repeat		$8800 - *
		.byte		$00
		.endrep

		.repeat		$a000 - *
		.byte		$ff
		.endrep
