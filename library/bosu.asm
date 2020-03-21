;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, struktury, obiekty
	;-----------------------------------------------------------------------
	%include	"library/bosu/config.asm"
	%include	"library/bosu/font.asm"
	;-----------------------------------------------------------------------

;===============================================================================
; wejście:
;	rsi - wskaźnik do właściwości okna
library_bosu:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdi
	push	rsi

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z liblioteki
	ret

;===============================================================================
; wejście:
;	rsi - wskaźnik do właściwości okna
; wyjście:
;	r8 - minimalna szerokość okna na podstawie zawartych elementów
;	r9 - minimalna wysokość okna na podstawie zawartych elementów
library_bosu_elements_specification:
	; zachowaj oryginalne rejestry
	push	rax
	push	rsi

	; pozycja najdalszego elementu na osi X
	xor	r8,	r8

	; pozycja najdalszego elementu na osi Y
	xor	r9,	r9

	; przesuń wskaźnik na listę elementów
	add	rsi,	LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.SIZE

.loop:
	; koniec elementów?
	cmp	dword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.type],	STATIC_EMPTY
	je	.end	; tak

	; element typu "nagłówek"?
	cmp	dword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.type],	LIBRARY_BOSU_ELEMENT_TYPE_header
	je	.next	; tak, pomiń

	; pozycja elementu na osi X
	mov	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x]
	add	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]

	; dalej niż poprzedni?
	cmp	rax,	r8
	jb	.y	; nie

	; zachowaj informację
	mov	r8,	rax

.y:
	; pozycja elementu na osi Y
	mov	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
	add	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]

	; dalej niż poprzedni?
	cmp	rax,	r9
	jb	.next	; nie

	; zachowaj informację
	mov	r9,	rax

.next:
	; przesuń wskaźnik na następny element z listy
	add	rsi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.size]

	; kontynuuj
	jmp	.loop

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rax

	; powrót z procedury
	ret
