;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wyjście:
;	Flaga CF, jeśli początek dokumentu
;	rcx - rozmiar poprzedniej linii
;	rsi - wskaźnik początku poprzedniej linii w dokumencie
moko_line_previous:
	; zachowaj oryginalne rejestry
	push	rsi

	; ustaw wskaźnik przed znakiem nowej linii na podstawie aktualnej linii
	mov	rsi,	r10
	sub	rsi,	r11

	; początek dokumentu?
	cmp	rsi,	qword [moko_document_start_address]
	ja	.ok	; nie

	; flaga, błąd
	stc

	; koniec
	jmp	.end

.ok:
	; rozpocznij przed znakiem nowej linii
	dec	rsi

	; określ pozycję i rozmiar poprzedniej linii
	xor	ecx,	ecx	; rozmiar

.loop:
	; początek dokumentu?
	cmp	rsi,	qword [moko_document_start_address]
	je	.found	; tak

	; koniec poprzedniej linii?
	cmp	byte [rsi - STATIC_BYTE_SIZE_byte],	STATIC_SCANCODE_NEW_LINE
	je	.found	; tak

	; ilość znaków +1
	inc	rcx

	; następny (poprzedni) znak w linii
	dec	rsi

	; koniec dokumentu?
	cmp	rsi,	qword [moko_document_start_address]
	jne	.loop	; nie

.found:
	; zwróć informacje o pozycji początku poprzedniej linii w dokumencie
	mov	qword [rsp],	rsi

.end:
	; przywróć oryginalne rejestry
	pop	rsi

	; powrót z procedury
	ret

;===============================================================================
; wyjście:
;	Flaga CF - jeśli koniec dokumentu
;	rcx - rozmiar linii w znakach
;	rsi - wskaźnik początku następnej linii
moko_line_next:
	; zachowaj oryginalne rejestry
	push	rsi

	; ustaw wskaźnik przed znakiem nowej linii na podstawie aktualnej linii
	mov	rsi,	r10
	sub	rsi,	r11
	add	rsi,	r13

	; koniec dokumentu?
	cmp	rsi,	qword [moko_document_end_address]
	jb	.ok	; nie

	; flaga, błąd
	stc

	; koniec
	jmp	.end

.ok:
	; rozpocznij za znakiem nowej linii
	inc	rsi

	; określ pozycję i rozmiar poprzedniej linii
	xor	ecx,	ecx	; rozmiar

.loop:
	; koniec dokumentu?
	cmp	rsi,	qword [moko_document_end_address]
	je	.found	; tak

	; koniec następnej linii?
	cmp	byte [rsi],	STATIC_SCANCODE_NEW_LINE
	je	.found	; tak

	; ilość znaków +1
	inc	rcx

	; następny znak w linii
	inc	rsi

	; kontynuuj
	jmp	.loop

.found:
	; ustaw wskaźnik na początek linii
	sub	rsi,	rcx

	; zwróć informacje o pozycji początku następnej linii w dokumencie
	mov	qword [rsp],	rsi

.end:
	; przywróć oryginalne rejestry
	pop	rsi

	; powrót z procedury
	ret

;===============================================================================
moko_line:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rsi

	; ustaw kursor na początek aktualnego wiersza przestrzeni znakowej
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_document_cursor_end - moko_string_document_cursor
	mov	rsi,	moko_string_document_cursor
	mov	word [moko_string_document_cursor.x],	STATIC_EMPTY
	mov	word [moko_string_document_cursor.y],	r15w
	int	KERNEL_SERVICE

	; ustaw wskaźnik na początek/fragment linii do wyświetlenia
	mov	rsi,	r10
	sub	rsi,	r11
	add	rsi,	r12

	; ilość znaków z linii do wyświetlenia
	mov	rcx,	r13
	sub	rcx,	r12
	cmp	rcx,	r8
	jb	.visible	; ilość znaków mniejsza od szerokości ekranu

	; wyświetl maksymalną ilość znaków na ekran
	mov	rcx,	r8
	dec	rcx	; ostatnia kolumna zawsze pusta

.visible:
	; linia jest pusta?
	test	rcx,	rcx
	jz	.empty	; tak

	; wyświetl kolejno ciąg znaków o określonej długości
	int	KERNEL_SERVICE

.empty:
	; wyczyścić resztę linii?
	cmp	r8,	rcx
	je	.no	; nie

	; pozostałą część linii za pomocą znaku spacji
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
	sub	rcx,	r8
	not	rcx	; zamień na wartość bezwzględną
	mov	dl,	STATIC_SCANCODE_SPACE
	int	KERNEL_SERVICE

.no:
	; ustaw kursor na pozycję
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_document_cursor_end - moko_string_document_cursor
	mov	rsi,	moko_string_document_cursor
	mov	word [moko_string_document_cursor.x],	r14w
	mov	word [moko_string_document_cursor.y],	r15w
	int	KERNEL_SERVICE

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret
