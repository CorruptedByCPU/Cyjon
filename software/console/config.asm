;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty
	;-----------------------------------------------------------------------
	%include	"kernel/config.asm"
	%include	"config.asm"	; globalne
	;-----------------------------------------------------------------------

CONSOLE_WINDOW_WIDTH_pixel	equ	120
CONSOLE_WINDOW_HEIGHT_pixel	equ	66

CONSOLE_WINDOW_BACKGROUND_color	equ	0x00000000

; 64 bitowy kod programu
[BITS 64]

; adresowanie w trybie relatywnym
[DEFAULT REL]

; położenie kodu w pamięci logicznej
[ORG SOFTWARE_base_address]
