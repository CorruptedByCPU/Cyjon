;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
moko_document_area:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdi

	; pobierz informacje o strumieniu wyjścia
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_meta
	mov	bl,	KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_get | KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_out
	mov	rdi,	moko_stream_meta
	int	KERNEL_SERVICE
	jc	moko_document_area	; brak aktualnych informacji, spróbuj raz jeszcze

	; pobierz z meta danych strumienia
	; informacje o szerokości i wysokości przestrzeni znakowej
	movzx	r8,	word [rdi + CONSOLE_STRUCTURE_STREAM_META.width]
	movzx	r9,	word [rdi + CONSOLE_STRUCTURE_STREAM_META.height]

	; zmniejsz przestrzeń dokumentu o menu oraz zmień wartość na liczoną od zera
	sub	r9,	MOKO_MENU_HEIGHT_char + STATIC_BYTE_SIZE_byte

	; przygotuj miejsce pod pusty dokument (domyślnie 4 KiB ~ około 4000 znaków)
	mov	ax,	KERNEL_SERVICE_PROCESS_memory_alloc
	mov	rcx,	STATIC_PAGE_SIZE_byte
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
