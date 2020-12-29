;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rcx - rozmiar dokumentu w Bajtach
;	rdi - wskaźnik początku dokumentu
moko_document_analyze:
	; resetuj zmienne lokalne i globalne do domyślnych wartości
	mov	qword [moko_document_show_from_line],	STATIC_EMPTY
	mov	qword [moko_document_line_begin_last],	STATIC_EMPTY
	mov	qword [moko_document_line_index_last],	STATIC_EMPTY
	mov	qword [moko_document_line_count],	STATIC_EMPTY
	mov	r10,	qword [moko_document_start_address]
	xor	r11,	r11
	xor	r12,	r12
	xor	r14,	r14
	xor	r15,	r15

	; usuń z dokumentu znaki "karetki", domyślnie Moko ich nie obsługuje
	mov	rsi,	rdi
	call	moko_document_enter_remove

	; ustaw rozmiar dokumentu w Bajtach
	mov	qword [moko_document_size],		rcx

	; zachowaj wskaźnik końca dokumentu
	add	rdi,	rcx
	mov	qword [moko_document_end_address],	rdi

	; pobierz informacje o pierwszej linii dokumentu
	xor	ecx,	ecx
	call	moko_line_this
	jc	.end	; pusty dokument

	; rozmiar aktualnej linii w znakach
	mov	r13,	rcx

	; przesuń wskaźnik za pierwszą linię dokumentu
	add	rsi,	r13
	mov	rcx,	qword [moko_document_size]
	sub	rcx,	r13

.loop:
	; koniec dokumentu?
	cmp	rsi,	rdi
	je	.end	; tak

	; zlicz ilość linii w dokumencie
	cmp	byte [rsi],	STATIC_SCANCODE_NEW_LINE
	jne	.next	; następny

	; znaleziono koniec linii
	inc	qword [moko_document_line_count]

.next:
	; następny znak z dokumentu
	inc	rsi

	; znaleziono wszystkie?
	dec	rcx
	jnz	.loop	; nie

.end:
	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rcx - rozmiar dokumentu w Bajtach
;	rsi - wskaźnik początku dokumentu
moko_document_enter_remove:
	; zachowaj oryginalne rejestry
	push	rsi
	push	rdi
	push	rcx

.loop:
	; znak "karetki"?
	cmp	byte [rsi],	STATIC_SCANCODE_RETURN
	jne	.next	; nie

	; zachowaj wskaźnik i rozmiar pozostałego dokumentu do przetworzenia
	push	rcx
	push	rsi

	; usuń znak "karetki" z dokumentu
	mov	rdi,	rsi
	inc	rsi
	rep	movsb

	; przywróć wskaźnik i rozmiar pozostałego dokumentu do przetworzenia
	pop	rsi
	pop	rcx

	; rozmiar dokumentu zmniejszył się
	dec	qword [rsp]

	; kontynuuj
	jmp	.return

.next:
	; przesuń wskaźnik na następny znak
	inc	rsi

.return:
	; dokument przetworzony?
	dec	rcx
	jnz	.loop	; nie

.end:
	; przywróć oryginalne rejestry
	pop	rcx
	pop	rdi
	pop	rsi

	; powrót z procedury
	ret

;===============================================================================
moko_document_reload:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rsi

	; rozpocznij dokument od podanych linii
	xor	ebx,	ebx
	mov	rcx,	qword [moko_document_show_from_line]

	; rozpocznij
	jmp	.init

.loop:
	; wyświetl kolejną linię dokumentu
	inc	rbx
	inc	rcx

.init:
	; wyświetl "pierwszą" linię dokumentu
	call	moko_line_number
	jc	.ready	; wyświetlono pozostałe linie dokumentu

	; koniec przestrzeni dokumentu?
	cmp	rbx,	r9
	jb	.loop	; nie

.ready:
	; wyczyść kolejne linie dokumentu
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_line_clean_next_end - moko_string_line_clean_next
	mov	rsi,	moko_string_line_clean_next

.clean:
	; wyczyszczono pozostałe linie dokumentu?
	cmp	rbx,	r9
	ja	.end	; tak

	; wyczyść
	int	KERNEL_SERVICE

	; następna linia dokumentu
	inc	rbx

	; kontynuuj
	jmp	.clean

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
moko_document_remove:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi
	push	rdi

	; ilość znaków do przesunięcia
	mov	rdi,	r10
	sub	rdi,	qword [moko_document_start_address]
	mov	rcx,	qword [moko_document_size]
	sub	rcx,	rdi

	; rozpocznij w
	mov	rdi,	r10
	mov	rsi,	rdi
	inc	rsi

	; wykonaj operacje
	rep	movsb

	; ilość znaków w dokumencie mniejszyła się
	dec	qword [moko_document_size]

	; przesuń wskaźnik końca dokumentu
	dec	qword [moko_document_end_address]

	; zmodyfikowano status dokumentu
	mov	byte [moko_modified_semaphore],	STATIC_TRUE

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx

	; powrót z procedury
	ret

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
	jb	.end	; nie

	; cofnij kursor do poprzedniej kolumny
	dec	r14

	; wyświetl zawartość linii od następnego znaku
	inc	r12

	; zachowaj ostatni znany wskaźnik początku wyświetlanej linii
	mov	qword [moko_document_line_begin_last],	r12

.end:
	; zmodyfikowano status dokumentu
	mov	byte [moko_modified_semaphore],	STATIC_TRUE

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rcx - rozmiar listy argumentów w Bajtach
;	rsi - wskaźnik do ciągu argumentów
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

	; przesłano argumenty?
	test	rcx,	rcx
	jz	.no_args	; nie

	; wczytaj i przetwórz zawartość pliku
	call	moko_document_format
	jnc	.end	; wykonano poprawnie

.no_args:
	; przygotuj miejsce pod pusty dokument (domyślnie 4 KiB ~ około 4000 znaków)
	mov	ax,	KERNEL_SERVICE_PROCESS_memory_alloc
	mov	rcx,	MOKO_DOCUMENT_AREA_SIZE_default
	int	KERNEL_SERVICE
	jc	moko.end	; brak wystarczającej ilości pamięci

.set_up:
	; aktualizuj właściwości dokumentu
	mov	qword [moko_document_start_address],	rdi
	mov	qword [moko_document_end_address],	rdi

	; aktualizuj pozycje kursora wew. dokumentu
	mov	r10,	rdi

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	Flaga CF - jeśli nie przetworzono nowego dokumentu
;	rcx - ilość znaków w ciągu
;	rsi - wskaźnik do ciągu
moko_document_format:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi
	push	rdi

	; pobierz typ pliku
	mov	ax,	KERNEL_SERVICE_VFS_exist
	int	KERNEL_SERVICE
	jc	.end	; pliku nie znaleziono

	; zwykły plik tekstowy?
	cmp	bl,	KERNEL_VFS_FILE_TYPE_regular_file
	je	.regular_file	; tak

	; brak obsługi
	stc

	; koniec obsługi
	jmp	.end

.regular_file:
	; załaduj podany plik
	mov	ax,	KERNEL_SERVICE_VFS_read
	int	KERNEL_SERVICE
	jc	.end	; pliku nie znaleziono lub nie udało się wczytać

	; zachowaj rozmiar wczytanego dokumentu
	mov	qword [moko_document_size],	rcx

	; podmień wskaźnik dokumentu
	xchg	qword [moko_document_start_address],	rdi

	; zwolnić przestrzeń starego dokumentu?
	test	rdi,	rdi
	jz	.no	; nie

	; jeśli rozmiar dokumentu nie został zainicjowany
	test	rcx,	rcx
	jnz	.sized	; został

	; ustaw domyślny
	mov	ecx,	STATIC_PAGE_SIZE_byte

.sized:
	; zwolnij przestrzeń starego dokumentu
	mov	ax,	KERNEL_SERVICE_PROCESS_memory_release
	int	KERNEL_SERVICE

.no:
	; analizuj zawartość dokumentu
	mov	rcx,	qword [moko_document_size]
	mov	rdi,	qword [moko_document_start_address]
	call	moko_document_analyze

	; wyświetl zawartość dokumentu
	call	moko_document_reload

	; ustaw kursor na początek dokumentu
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_document_cursor_end - moko_string_document_cursor
	mov	rsi,	moko_string_document_cursor
	mov	dword [moko_string_document_cursor.joint],	STATIC_EMPTY
	int	KERNEL_SERVICE

	; zapamiętaj informację o wyświetleniu komunikatu
	mov	byte [moko_status_semaphore],	STATIC_TRUE

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret
