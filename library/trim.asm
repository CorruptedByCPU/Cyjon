;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; 64 bitowy kod programu
[BITS 64]

;===============================================================================
; procedura modyfikuje wskaźnik początku ciągu i jego rozmiar,
; pozbywając się wszystkich białych znaków na krańcach
; IN:
;	rcx	- ilość znaków w ciągu
;	rdi	- wskaźnik do ciągu
;
; OUT:
;	rcx	- ilość znaków w ciągu bez ostatnich "białych" znaków
;	rdi	- wskaźnik początku ciągu bez pierwszych "białych" znaków
;
; wszystkie rejestry zachowane
library_trim:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdi

.loop0:
	; spacja?
	mov	al,	VARIABLE_ASCII_CODE_SPACE
	cmp	byte [rdi],	al
	je	.prefix

	; tabulator?
	mov	al,	VARIABLE_ASCII_CODE_TAB
	cmp	byte [rdi],	al
	je	.prefix

	; zachowaj wskaźnik początku ciągu bez białych znaków
	mov	qword [rsp],	rdi

	; przesuń wskaźnik na ostatni znak
	add	rdi,	rcx
	dec	rdi

.loop1:
	; spacja?
	mov	al,	VARIABLE_ASCII_CODE_SPACE
	cmp	byte [rdi],	al
	je	.suffix

	; tabulator?
	mov	al,	VARIABLE_ASCII_CODE_TAB
	cmp	byte [rdi],	al
	jne	.end

.suffix:
	; cofnij wskaźnik na poprzedni znaj
	dec	rdi
	; kontynuuj
	loop	.loop1

	; koniec
	jmp	.end

.prefix:
	; przesuń wskaźnik na następny znak
	inc	rdi
	; kontynuuj
	loop	.loop0

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rax

	; powrót z procedury
	ret
