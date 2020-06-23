;===============================================================================
; Copyright (C) by vLock.dev
;===============================================================================

;===============================================================================
; wejście:
;	rdi - adres
; wyjście:
;	rdi - adres wyrównany do pełnej strony w górę
library_page_align_up:
	; utwórz zmienną lokalną
	push	rdi

	; usuń młodszą część adresu
	and	di,	KERNEL_PAGE_mask

	; sprawdź czy adres jest identyczny z zmienną lokalną
	cmp	rdi,	qword [rsp]
	je	.end	; jeśli tak, koniec

	; przesuń adres o jedną ramkę do przodu
	add	rdi,	KERNEL_PAGE_SIZE_byte

.end:
	; usuń zmienną lokalną
	add	rsp,	STATIC_QWORD_SIZE_byte

	; powrót z procedury
	ret

	; macro_debug	"library_page_align_up"
