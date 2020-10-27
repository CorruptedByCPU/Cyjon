;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rcx - rozmiar w Bajtach
; wyjście:
;	rcx - rozmiar w stronach wyrównany do góry
library_page_from_size:
	; zmienna lokalna
	push	rcx

	; usuń młodszą część rozmiaru
	and	cx,	STATIC_PAGE_mask

	; sprawdź czy rozmiar jednakowy
	cmp	rcx,	qword [rsp]
	je	.ready	; jeśli tak, koniec

	; przesuń rozmiar o jedną stronę do przodu
	add	rcx,	STATIC_PAGE_SIZE_byte

.ready:
	; zamień na strony
	shr	rcx,	STATIC_DIVIDE_BY_PAGE_shift

	; usuń zmienną lokalną
	add	rsp,	STATIC_QWORD_SIZE_byte

	; powrót z procedury
	ret

	; macro_debug	"library_page_from_size"
