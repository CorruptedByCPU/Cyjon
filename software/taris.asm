;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty, makra
	;-----------------------------------------------------------------------
	%include	"kernel/header.asm"
	;-----------------------------------------------------------------------
	%include	"software/taris/config.asm"
	;-----------------------------------------------------------------------

; 64 bitowy kod programu
[bits 64]

; adresowanie względne
[default rel]

; położenie kodu programu w pamięci logicznej
[org SOFTWARE_base_address]

;===============================================================================
taris:
	; utwórz okno
	mov	rsi,	taris_window
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu
	jc	taris.close	; brak wystarczającej przestrzeni pamięci

.loop:
	; sprawdź przychodzące zdarzenia
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu_event

	; debug
	jmp	$

.close:
	; zakończ pracę programu
	xor	ax,	ax
	int	KERNEL_SERVICE

	macro_debug	"software: taris"

	;-----------------------------------------------------------------------
	%include	"software/taris/data.asm"
	;-----------------------------------------------------------------------
