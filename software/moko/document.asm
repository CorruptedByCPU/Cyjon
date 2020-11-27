;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	ax - kod ASCII znaku
;	bl - aktualizowanie zmiennych globalnych == STATIC_EMPTY
; wyjście:
;	Flaga CF - jeśli znak nie jest drukowalny
moko_document_insert:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rsi
	push	rdi

	; znak drukowalny?
	cmp	ax,	STATIC_SCANCODE_SPACE
	jb	.error	; nie
	cmp	ax,	STATIC_SCANCODE_TILDE
	jb	.insert	; tak

.error:
	; flaga, błąd
	stc

	; koniec obsługi znaku
	jmp	.end

.insert:
	; wstawić znak na koniec dokumentu?
	cmp	r10,	qword [moko_document_end_address]
	je	.at_end_of_document	; tak

	; wstawiamy znak nowej linii?
	cmp	ax,	STATIC_SCANCODE_NEW_LINE
	je	.no_insert_key	; zignoruj klawisz insert

	; klawisz Insert aktywny?
	cmp	byte [moko_key_insert_semaphore],	STATIC_FALSE
	je	.no_insert_key	; nie

	; aktualnie w tym miejscu znajduje się znak nowej linii?
	cmp	byte [r10],	STATIC_SCANCODE_NEW_LINE
	je	.no_insert_key	; zignoruj klawisz Insert

	; podmień znak w linii
	mov	byte [r10],	al

	; koryguj zmienne
	jmp	.inserted

.no_insert_key:
	; przesuń zawartość dokumentu względem wskaźnika o jeden znak w przód

	; ilość znaków do przemieszczenia
	mov	rcx,	qword [moko_document_end_address]
	sub	rcx,	r10

	; rozpocznij od ostatniego znaku w dokumencie
	mov	rdi,	qword [moko_document_end_address]
	mov	rsi,	rdi
	dec	rsi

	; wykonaj operację wstecz
	std	; włącz Direction Flag
	rep	movsb
	cld	; wyłącz Direction Flag

.at_end_of_document:
	; zapisz znak do dokumentu
	mov	byte [r10],	al

	; ilość znaków w dokumencie +1
	inc	qword [moko_document_size]

	; ustaw wskaźnik końca dokumentu o jedną pozycję dalej
	inc	qword [moko_document_end_address]

	; nie modyfikować rozmiaru linii?
	test	bl,	bl
	jnz	.end	; tak

	; zwiększ rozmiar linii
	inc	r13

.inserted:
	; nie modyfikować właściwości aktualnej linii i kursora?
	test	bl,	bl
	jnz	.end	; tak

	; przesuń wskaźnik pozycji kursora w przestrzeni dokumentu do następnej pozycji
	inc	r10

	; przestaw kursor do następnej kolumny
	inc	r14

	; przesuń wskaźnik pozycji wew. linii na następny znak
	inc	r11

	; zachowaj ostatni znany wskaźnik pozycji wew. linii
	mov	qword [moko_document_line_index_last],	r11

	; kursor wyszedł poza ekran?
	cmp	r14,	r8
	jbe	.ready	; nie

	; cofnij kursor do poprzedniej kolumny
	dec	r14

	; wyświetl zawartość linii od następnego znaku
	inc	r12

	; zachowaj ostatni znany wskaźnik początku wyświetlanej linii
	mov	qword [moko_document_line_begin_last],	r12

.ready:
	; zaimportowano znak do dokumentu
	clc

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx

	; powrót z procedury
	ret

;===============================================================================
moko_document_area:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdi

.retry:
	; pobierz informacje o strumieniu wyjścia
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_meta
	mov	bl,	KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_get | KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_out
	mov	rdi,	moko_stream_meta
	int	KERNEL_SERVICE
	jc	.retry	; brak aktualnych informacji, spróbuj raz jeszcze

	; pobierz z meta danych strumienia
	; informacje o szerokości i wysokości przestrzeni znakowej
	movzx	r8,	word [rdi + CONSOLE_STRUCTURE_STREAM_META.width]
	movzx	r9,	word [rdi + CONSOLE_STRUCTURE_STREAM_META.height]

	; zmniejsz przestrzeń dokumentu o menu oraz zmień wartość na liczoną od zera
	sub	r9,	MOKO_MENU_HEIGHT_char + STATIC_BYTE_SIZE_byte

	; przygotuj miejsce pod pusty dokument (domyślnie 4 KiB ~ około 4000 znaków)
	mov	ax,	KERNEL_SERVICE_PROCESS_memory_alloc
	mov	rcx,	MOKO_DOCUMENT_AREA_SIZE_default
	int	KERNEL_SERVICE
	jc	moko.end	; brak wystarczającej ilości pamięci

	; aktualizuj właściwości dokumentu
	mov	qword [moko_document_start_address],	rdi
	mov	qword [moko_document_end_address],	rdi

	; aktualizuj pozycje kursora wew. dokumentu
	mov	r10,	rdi

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret
