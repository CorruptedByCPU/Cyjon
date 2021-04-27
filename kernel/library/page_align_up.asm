;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rdi - adres
; wyjście:
;	rdi - adres wyrównany do pełnej strony w górę
library_page_align_up:
	; usuń młodszą część adresu
	add	rdi,	STATIC_PAGE_SIZE_byte - 0x01
	shr	rdi,	STATIC_DIVIDE_BY_PAGE_shift
	shl	rdi,	STATIC_MULTIPLE_BY_PAGE_shift

	; powrót z procedury
	ret

	macro_debug	"library_page_align_up"
