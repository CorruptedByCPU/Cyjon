;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty, makra
	;-----------------------------------------------------------------------
	%include	"config.asm"
	%include	"kernel/config.asm"
	;-----------------------------------------------------------------------

; 64 bitowy kod programu
[BITS 64]

; adresowanie względne
[DEFAULT REL]

; położenie kodu programu w pamięci logicznej
[ORG SOFTWARE_base_address]

;===============================================================================
hello:
	; wyświetl powitanie
	mov	ax,	KERNEL_SERVICE_VIDEO_string
	mov	ecx,	hello_string_end - hello_string
	mov	rsi,	hello_string
	int	KERNEL_SERVICE

	; zakończ pracę programu
	xor	ax,	ax
	int	KERNEL_SERVICE

hello_string	db	"Hello, World!"
hello_string_end:
