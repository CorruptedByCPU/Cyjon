;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty, makra
	;-----------------------------------------------------------------------
	%include	"config.asm"	; globalne
	;-----------------------------------------------------------------------
	%include	"kernel/config.asm"	; lokalne
	;-----------------------------------------------------------------------

; 32 bitowy kod inicjalizacyjny jądra systemu
[BITS 32]

; położenie kodu jądra systemu w pamięci fizycznej
[ORG KERNEL_BASE_address]

init:
	;-----------------------------------------------------------------------
	; Init - inicjalizacja środowiska pracy jądra systemu
	;-----------------------------------------------------------------------
	%include	"kernel/init.asm"

clean:

kernel:
	; zatrzymaj dalsze wykonywanie kodu
	jmp	$

	;-----------------------------------------------------------------------
	; procedury, makra, dane, biblioteki, usługi - wszystko co niezbędne
	; do prawidłowej pracy jądra systemu
	;-----------------------------------------------------------------------
	%include	"kernel/macro/close.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/panic.asm"
	%include	"kernel/page.asm"
	%include	"kernel/memory.asm"
	%include	"kernel/video.asm"
	;-----------------------------------------------------------------------
	%include	"library/page_align_up.asm"
	%include	"library/page_from_size.asm"
	;-----------------------------------------------------------------------

kernel_end:
