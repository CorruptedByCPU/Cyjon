;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
moko_line_clear_last:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi

	; ustaw kursor na ostatnią linię dokumentu
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_document_cursor_end - moko_string_document_cursor
	mov	rsi,	moko_string_document_cursor
	mov	word [moko_string_document_cursor.x],	STATIC_EMPTY
	mov	word [moko_string_document_cursor.y],	r9w
	int	KERNEL_SERVICE

	; wyczyść
	mov	ecx,	moko_string_line_clean_end - moko_string_line_clean
	mov	rsi,	moko_string_line_clean
	int	KERNEL_SERVICE

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rcx - numer linii do sprawdzenia
; wyjście:
;	Flaga CF jeśli błąd
;	rcx - rozmiar linii dokumentu
;	rsi - wskaźnik początku linii
moko_line_this:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi

	; ustaw wskaźnik na początek przestrzeni dokumentu
	mov	rsi,	qword [moko_document_start_address]

	; pobrać informacje o pierwszej linii dokumentu?
	test	rcx,	rcx
	jz	.first_line	; tak

.search:
	; koniec dokumentu?
	cmp	rsi,	qword [moko_document_end_address]
	je	.error	; nie znaleziono podanej linii w dokumencie

	; pobierz pierwszy znak linii
	lodsb

	; znak nowej linii
	cmp	al,	STATIC_SCANCODE_NEW_LINE
	jne	.search	; nie

	; rozpoznano koniec linii, szukać następny?
	dec	rcx
	jnz	.search	; tak

.first_line:
	; zachowaj wskaźnik początku linii w dokumencie
	push	rsi

.length:
	; koniec dokumentu?
	cmp	rsi,	qword [moko_document_end_address]
	je	.ready	; określono rozmiar linii

	; szukaj znaku końca linii
	lodsb

	; koniec?
	cmp	al,	STATIC_SCANCODE_NEW_LINE
	je	.ready	; tak

	; ilość znaków w linii
	inc	rcx
	jmp	.length	; kontynuuj

.ready:
	; przywróć wskaźnik początku danej linii
	pop	rsi

	; zwróć informację o początku danej linii i jej rozmiar
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	rcx
	mov	qword [rsp],	rsi

	; koniec procedury
	jmp	.end

.error:
	; flaga, błąd
	stc

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rbx - numer wiersza na ekranie
;	rcx - numer linii dokumentu do wyświetlenia
moko_line_number:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi
	push	r10
	push	r11
	push	r12
	push	r13
	push	r15

	; pobierz informacje o podanej linii
	call	moko_line_this
	jc	.end	; brak informacji o podanej linii

	; ustaw właściwości poprzedniej linii
	mov	r10,	rsi	; wskaźnik początku linii w dokumencie
	xor	r11,	r11	; wskaźnik wew. linii na początku
	xor	r12,	r12	; wyświetl całą linię od początku
	mov	r13,	rcx	; rozmiar linii
	mov	r15,	rbx	; w przewidzianej do tego linii

	; wyświetl
	call	moko_line

.end:
	; przywróć oryginalne rejestry
	pop	r15
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rcx - rozmiar rozpatrywanej linii
;	rsi - wskaźnik początku rozpatrywanej linii
moko_line_update:
	; wskaźnik pozycji kursora w przestrzeni dokumentu
	mov	r10,	rsi

	; rozmiar nowej linii
	mov	r13,	rcx

	; czy ostatnio używany numer kolumny znajduje się w przestrzeni rozmiaru aktualnej linii?
	cmp	qword [moko_document_line_index_last],	r13
	jbe	.in_line	; tak

	; ustaw wskaźnik wew. dokumentu na koniec linii
	add	r10,	rcx

	; przesunięcie wew. linii ustaw na koniec linii
	mov	r11,	rcx

	; wyświetl linię od pierwszego znaku
	xor	r12,	r12

	; ustaw kursor w kolumnie odpowiadającej pozycji końca linii
	mov	r14,	rcx

	; koniec procedury
	ret

.in_line:
	; wyświetl linię na podstawie ostnio znanych właściwości
	mov	r11,	qword [moko_document_line_index_last]
	mov	r12,	qword [moko_document_line_begin_last]

	; ustaw wskaźnik wew. dokumentu na pozycje
	add	r10,	r11

	; ustaw kursor w odpowiedniej kolumnie
	mov	r14,	r11

	; cała linia mieści się w przestrzeni ekranu?
	cmp	rcx,	r8
	jbe	.end	; tak

	; ustaw kursor w odpowiedniej kolumnie
	mov	r14,	r11
	sub	r14,	r12

.end:
	; koniec procedury
	ret

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
