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
		VDU_STATUS	:= $D0
		VEC_STAR_CMD	:= $F2

;----------------------------------------------------------------------
;
; Zero page variables
;
		_xoff		:= $70
		_var_71		:= $71
		_insert_mode	:= $72
		_var_73		:= $73
		_edit_cols	:= $74
		_serial_in	:= $75
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

		; ASCII
		XON		= $11
		XOFF		= $13
		ESC		= $1B

		; MOS VDU sequence
.scope		VDU
		TEXT		= 4
		LEFT		= 8
		RIGHT		= 9
		DOWN		= 10
		UP		= 11
		CLS		= 12
		CLG		= 16
		COLOUR		= 17
		GCOL		= 18
		PALETTE		= 19
		MODE		= 22
		GVIEWPORT	= 24
		PLOT		= 25
		RESTORE		= 26
		VIEWPORT	= 28
		ORIGIN		= 29
		HOME		= 30
		TAB_XY		= 31
.endscope

		; MOS BAUD rate settings
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

@help:		ldx		#$FF
:		inx
		lda		Header::Title,x
		jsr		OSASCI
		bne		:-

		jsr		OSNEWL
		pla
		rts

@star:   	tya
		pha
		txa
		pha

		; compare supplied command to "UTE5"
		ldx		#$FF
		dey
:	    	inx
		iny
		lda		_ute5,X
		bmi		@lang
		cmp		(VEC_STAR_CMD),Y
		beq		:-

		; no match - restore registers and return
		pla
		tax
		pla
		tay
		pla
		rts

		; enter language ROM
@lang:		lda		#$8E
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
		sta		_insert_mode
		sta		_var_73
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
		lda		#VDU::MODE
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

		; disable cursor editing and enable soft keys
		ldx		#$02
		lda		#$04
		jsr		OSBYTE

		; set function key status to base $80
		ldy		#$00
		ldx		#$80
		lda		#$E1
		jsr		OSBYTE

		; set shift function key status to base $90
		ldy		#$00
		ldx		#$90
		lda		#$E2
		jsr		OSBYTE

		; set control function key status to base $A0
		ldy		#$00
		ldx		#$A0
		lda		#$E3
		jsr		OSBYTE

		; set shift-control function key status to soft key mode
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
:		lda		_s_set_char,Y
		jsr		OutVarChar
		bne		:-

		; main serial input processing loop
@main_loop:	jsr		GetSerial
		and		#$7F
		cmp		#' '
		bcs		@not_ctrl
		jsr		DoControl
		jmp		@main_loop

@not_ctrl:	ldx		_insert_mode
		bne		@insert
		jsr		OSWRCH
		jmp		@main_loop

@insert:	jsr		DoInsert
		jmp		@main_loop

.endproc

;----------------------------------------------------------------------

.proc		GetSerial

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

@not_esc:	; handle FN key mapping
		jsr		CheckFNKeys
		tay
		jsr		WriteToBuffer

@no_data:	; check serial buffer status
		jsr		CheckSerial
		cpx		#$01
		bcc		GetSerial

		; enable serial and read character
		lda		#$02
		ldx		#$01
		jsr		OSBYTE
		jsr		OSRDCH
		sta		_serial_in

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

.proc		CheckFNKeys

		; low characters are ignored
		cmp		#$80
		bcc		@exit

		; double A and save
		asl		A
		tax
		pha

		; look up in table, branch if zero
		ldy		@table,X
		beq		@not_esc

		; send ESC-o
		ldy		#ESC
		jsr		WriteToBuffer
		ldy		#'o'
		jsr		WriteToBuffer

@not_esc:	; look up next character from table and return it
		pla
		tax
		inx
		lda		@table,X

@exit:		rts

@table:		.byte		ESC,'A'		; f0
		.byte		ESC,'B'
		.byte		ESC,'C'
		.byte		ESC,'D'
		.byte		ESC,'E'
		.byte		ESC,'F'
		.byte		ESC,'G'
		.byte		ESC,'H'
		.byte		ESC,'I'
		.byte		ESC,'J'		; f9
		.byte		$00,$00		; break
		.byte		ESC,'K'		; copy
		.byte		$00,$02		; left
		.byte		$00,$06		; right
		.byte		$00,$0E		; down
		.byte		$00,$10		; up
		.byte		ESC,'a'
		.byte		ESC,'b'
		.byte		ESC,'c'
		.byte		ESC,'d'
		.byte		ESC,'e'
		.byte		ESC,'f'
		.byte		ESC,'g'
		.byte		ESC,'h'
		.byte		ESC,'i'
		.byte		ESC,'j'
		.byte		$00,$00
		.byte		ESC,'k'
		.byte		ESC,'l'
		.byte		ESC,'m'
		.byte		ESC,'n'
		.byte		ESC,'o'
		.byte		ESC,'0'
		.byte		ESC,'1'
		.byte		ESC,'2'
		.byte		ESC,'3'
		.byte		ESC,'4'
		.byte		ESC,'5'
		.byte		ESC,'6'
		.byte		ESC,'7'
		.byte		ESC,'8'
		.byte		ESC,'9'
		.byte		$00,$00
		.byte		ESC,':'
		.byte		ESC,';'
		.byte		ESC,'<'
		.byte		ESC,'='
		.byte		ESC,'>'

.endproc

;----------------------------------------------------------------------

.proc		DoInsert

		; get cursor position
		lda		#$86
		jsr		OSBYTE
		stx		_cursor_x
		sty		_cursor_y

		; calculate how many columns are left
		clc
		lda		#$01
		adc		_cols
		sec
		sbc		_cursor_x
		sta		_edit_cols

		; check if the character was DEL
		lda		_serial_in
		cmp		#$7F
		beq		DoBackspace

@loop:		; read character at cursor
		lda		#$87
		jsr		OSBYTE
		txa

		; use space if unrecognised
		bne		@replace
		lda		#' '

@replace:	; remember the character at the cursor
		pha

		; replace it with the character from previous iteration
		lda		_serial_in
		jsr		OSWRCH

		; restore A, saving it for the next iteration
		pla
		sta		_serial_in

		; and loop until the final column
		dec		_edit_cols
		bne		@loop

		; move cursor right of original position
		lda		#VDU::TAB_XY
		jsr		OSWRCH
		inc		_cursor_x
		lda		_cursor_x
		jsr		OSWRCH
		lda		_cursor_y
		jsr		OSWRCH
		rts

.endproc

;----------------------------------------------------------------------

.proc		DoBackspace

		; make sure we're not in column zero
		lda		_cursor_x
		bne		@loop
		rts

@loop:		; read character at cursor
		lda		#$87
		jsr		OSBYTE
		txa

		; use space if not recognised
		bne		@replace
		lda		#' '

@replace:	pha
		lda		#VDU::LEFT
		jsr		OSWRCH
		pla
		jsr		OSWRCH
		lda		#VDU::RIGHT
		jsr		OSWRCH
		dec		_edit_cols
		bne		@loop

		; erase final character on the line
		lda		#VDU::LEFT
		jsr		OSWRCH
		lda		#' '
		jsr		OSWRCH

		; move cursor left of original position
		lda		#VDU::TAB_XY
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

.proc		CheckSerial

		; enable (only) serial input
		lda		#$02
		ldx		#$01
		jsr		OSBYTE

		; check serial input buffer status
		lda		#$80
		ldx		#$FE
		ldy		#$FF
		jsr		OSBYTE

		; finish if using hardware handshake
		lda		_handshake
		bne		@send_xon
		rts

		; send XON if buffer space is available
@send_xon:	cpx		_buffer_max
		bcc		SendXON

.endproc	; or fall through and send XOFF

;----------------------------------------------------------------------

.proc		SendXOFF

		; check if XOFF was already sent
		lda		_xoff
		bne		SendXDone

		; set XOFF flag status
		lda		#$01
		sta		_xoff

		; send XOFF
		ldy		#XOFF
		jsr		WriteToBuffer
		rts

.endproc

.proc		SendXON

		; check if buffer space is available
		cpx		_buffer_min
		bcs		SendXDone

		; check XOFF flag status
		lda		_xoff
		beq		SendXDone

		; clear XOFF flag status
		lda		#$00
		sta		_xoff

		; send XON
		ldy		#XON
		jsr		WriteToBuffer

.endproc

SendXDone:	rts


;----------------------------------------------------------------------

.proc		DoControl
		asl		A
		tax
		lda		@jmp,X
		sta		_jmp_vec
		inx
		lda		@jmp,X
		beq		@l1
		sta		_jmp_vec + 1
		jmp		(_jmp_vec)

@l1:		lda		_serial_in
		and		#$1F
		jsr		OSWRCH
		lda		_jmp_vec
		bne		@l2
		rts

@l2:		jsr		GetSerial
		jsr		OSWRCH
		dec		_var_71
		bne		@l2
		rts

@jmp:
		.word		$0000
		.word		$0001
		.word		$0000
		.word		$0000
		.word		$0000
		.word		$0000
		.word		DoCursorRight
		.word		$0000
		.word		$0000
		.word		Tabstop
		.word		$0000
		.word		$0000
		.word		$0000
		.word		$0000
		.word		OpenLine
		.word		CloseLine
		.word		ClearGraphics
		.word		SetForeground
		.word		SetGForeground
		.word		SetPalette
		.word		$0000
		.word		ClearEOL
		.word		SetMode
		.word		$0009
		.word		$0008
		.word		$0005
		.word		$0000
		.word		DoEscape
		.word		SetViewport
		.word		$0004
		.word		$0000
		.word		TabXY

.endproc

;----------------------------------------------------------------------

.proc		DoEscape

		jsr		GetSerial
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
		.word		SetHandshake
		.word		SetInsertOn
		.word		Noop
		.word		Noop
		.word		SetBaud
		.word		Noop
		.word		Noop
		.word		SetInsertOff
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
		lda		#VDU::RESTORE
		jsr		OSWRCH

		; clear screen
		lda		#VDU::CLS
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

		lda		#VDU::TEXT
		jsr		OSWRCH
		rts

.endproc

;----------------------------------------------------------------------

.proc		SetHandshake

		jsr		GetSerial
		and		#$01
		sta		_handshake
		rts

.endproc

;----------------------------------------------------------------------

.proc		SetInsertOn

		lda		#$01
		jmp		SetInsert

.endproc	; fallthrough

.proc		SetInsertOff

		lda		#$00

.endproc	; fallthrough

.proc		SetInsert

		sta		_insert_mode

		; toggle scroll mode
		lda		VDU_STATUS
		eor		#$02
		sta		VDU_STATUS
		rts

.endproc

;----------------------------------------------------------------------

.proc		SetBaud

		jsr		GetSerial
		and		#$0F
		sta		_baud
		jsr		SetSerialRate
		rts

.endproc

;----------------------------------------------------------------------

.proc		SetBackground

		lda		#VDU::COLOUR
		jsr		OSWRCH
		jsr		GetSerial
		and		#$0F
		eor		#$80
		jsr		OSWRCH
		rts

.endproc

;----------------------------------------------------------------------

.proc		SetForeground

		lda		#VDU::COLOUR
		jsr		OSWRCH
		jsr		GetSerial
		and		#$0F
		jsr		OSWRCH
		rts

.endproc

;----------------------------------------------------------------------

.proc		SetGForeground

		lda		#VDU::GCOL
		jsr		OSWRCH
		jsr		GetSerial
		and		#$07
		jsr		OSWRCH
		jsr		GetSerial
		and		#$0F
		jsr		OSWRCH
		rts

.endproc

;----------------------------------------------------------------------

.proc		SetGBackground

		lda		#VDU::GCOL
		jsr		OSWRCH
		jsr		GetSerial
		and		#$07
		jsr		OSWRCH
		jsr		GetSerial
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
:		lda		_s_set_palette,Y
		jsr		OutVarChar
		bne		:-
		rts

.endProc

;----------------------------------------------------------------------

.proc		OpenLine

		; get cursor position
		lda		#$86
		jsr		OSBYTE
		stx		_var_7C
		sty		_var_7B
		sty		_var_7D
		lda		_rows
		sta		_var_7A

		; send VDU string
		ldx		#$0B
		ldy		#$00
:		lda		_s_vc1,Y
		jsr		OutVarChar
		bne		:-
		rts

.endproc

;----------------------------------------------------------------------

.proc		CloseLine

		; get cursor position
		lda		#$86
		jsr		OSBYTE
		stx		_var_80
		sty		_var_7F
		sty		_var_82
		lda		_rows
		sta		_var_7E
		sec
		sbc		_var_7F
		sta		_var_81

		; send VDU string
		ldx		#$0D
		ldy		#$00
:		lda		_s_vc2,Y
		jsr		OutVarChar
		bne		:-
		rts

.endproc

;----------------------------------------------------------------------

.proc		ClearGraphics

		lda		_handshake
		beq		@l1
		jsr		SendXOFF

@l1:		lda		#VDU::CLG
		jsr		OSWRCH
		rts

.endproc

;----------------------------------------------------------------------

.proc		SetPalette

		lda		#$13
		jsr		OSWRCH
		jsr		GetSerial
		and		#$0F
		jsr		OSWRCH
		jsr		GetSerial
		and		#$0F
		jsr		OSWRCH
		lda		#$00
		jsr		OSWRCH
		jsr		OSWRCH
		jsr		OSWRCH
		rts

.endproc

;----------------------------------------------------------------------

.proc		ClearEOL

		; get current cursor position
		lda		#$86
		jsr		OSBYTE
		sty		_cursor_y
		stx		_cursor_x

		; calculate columns remaining
		clc
		lda		#$01
		adc		_cols
		sec
		sbc		_cursor_x

		; nothing to do if we're at the end of the line
		tax
		beq		l1

		; output that many spaces
		jsr		ToggleScroll
:		lda		#' '
		jsr		OSWRCH
		dex
		bne		:-
		jsr		ToggleScroll

		; reset cursor position
		lda		#VDU::TAB_XY
		jsr		OSWRCH
		lda		_cursor_x
		jsr		OSWRCH
		lda		_cursor_y
		jsr		OSWRCH

l1:		; set serial receive rate (why?!)
		lda		#$07
		ldx		_baud
		jsr		OSBYTE
		rts

.endproc

;----------------------------------------------------------------------

.proc		SetMode

		lda		#VDU::MODE
		jsr		OSWRCH

		jsr		GetSerial
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

		lda		#VDU::GVIEWPORT
		jsr		OSWRCH
		jsr		GetCoord16
		jsr		GetCoord16
		jsr		GetCoord16
		jsr		GetCoord16
		rts

.endproc

;----------------------------------------------------------------------

.proc		PlotLine

		lda		#VDU::PLOT
		jsr		OSWRCH
		jsr		GetSerial
		and		#$3F
		jsr		OSWRCH
		jsr		GetCoord16
		jsr		GetCoord16
		rts

.endproc

;----------------------------------------------------------------------

.proc		PlotPoint

		lda		#VDU::PLOT
		jsr		OSWRCH
		jsr		GetSerial
		and		#$3F
		eor		#$40
		jsr		OSWRCH
		jsr		GetCoord16
		jsr		GetCoord16
		rts

.endproc

;----------------------------------------------------------------------

.proc		SetOrigin

		lda		#VDU::ORIGIN
		jsr		OSWRCH
		jsr		GetCoord16
		jsr		GetCoord16
		rts

.endproc

;----------------------------------------------------------------------

.proc		GetCoord16

		jsr		GetSerial
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
		jsr		GetSerial
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
		lda		#VDU::RIGHT
:		jsr		OSWRCH
		inx
		bne		:-
		rts

.endproc

;----------------------------------------------------------------------

.proc		DoCursorRight

		lda		#VDU::RIGHT
		jsr		OSWRCH
		rts

.endproc

;----------------------------------------------------------------------

.proc		TabXY

		lda		#VDU::TAB_XY
		jsr		OSWRCH
		jmp		GetCoord8x2

.endproc

;----------------------------------------------------------------------

.proc		SetViewport

		lda		#VDU::VIEWPORT
		jsr		OSWRCH
		jsr		GetCoord8
		jsr		GetCoord8

.endproc	; fallthrough

;----------------------------------------------------------------------

.proc		GetCoord8x2

		jsr		GetCoord8
		jsr		GetCoord8
		rts

.endproc

;----------------------------------------------------------------------

.proc		GetCoord8

		jsr		GetSerial
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

		lda		VDU_STATUS
		eor		#$02
		sta		VDU_STATUS
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

.macro		varptr		addr
		.byte		(addr - $70) | $80
.endmacro

_s_vc1:		.byte		VDU::VIEWPORT
		.byte		0
		varptr		_var_7A
		varptr		_cols
		varptr		_var_7B
		.byte		VDU::HOME
		.byte		VDU::UP
		.byte		VDU::RESTORE
		.byte		VDU::TAB_XY
		varptr		_var_7C
		varptr		_var_7D

_s_vc2:		.byte		VDU::VIEWPORT
		.byte		0
		varptr		_var_7E
		varptr		_cols
		varptr		_var_7F
		.byte		VDU::TAB_XY
		.byte		0
		varptr		_var_81
		.byte		VDU::DOWN
		.byte		VDU::RESTORE
		.byte		VDU::TAB_XY
		varptr		_var_80
		varptr		_var_82

_s_set_palette:	.byte		VDU::PALETTE
		.byte		0
		varptr		_palette_fg
		.byte		0
		.byte		0
		.byte		0
		.byte		VDU::PALETTE
		.byte		7
		varptr		_palette_bg
		.byte		0
		.byte		0
		.byte		0

_s_set_char:	.byte		23
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

_strings:	.byte		VDU::MODE,7
		.byte		VDU::TAB_XY,9,1
		.byte		"Unix Terminal Emulator"
		.byte		VDU::TAB_XY,8,5
		.byte		"M   Screen Mode"
		.byte		VDU::TAB_XY,8,7
		.byte		"L   Line Speed"
		.byte		VDU::TAB_XY,8,9
		.byte		"H   Handshake"
		.byte		VDU::TAB_XY,8,14
		.byte		"B   To BASIC"
		.byte		VDU::TAB_XY,7,18
		.byte		"ESC   Return To Emulator"
		.byte		VDU::TAB_XY,1,24
		.byte		"Use key indicated to toggle or act"
		.byte		0

_s_tab_25_5:	.byte		VDU::TAB_XY,25,5,0

_s_tab_25_7:	.byte		VDU::TAB_XY,25,7,0

_s_baud_table:	.byte		"75   ",0
		.byte		"150  ",0
		.byte		"300  ",0
		.byte		"1200 ",0
		.byte		"2400 ",0
		.byte		"4800 ",0
		.byte		"9600 ",0
		.byte		"19200",0

_s_tab_25_9:	.byte		VDU::TAB_XY,25,9,0

_s_hardware:	.byte		"hardware",0

_s_xon_xoff:	.byte		"xon/xoff",0

.endproc

;----------------------------------------------------------------------
;
; filler bytes
;
		.res		$8800 - *, $00
		.res		$a000 - *, $ff
