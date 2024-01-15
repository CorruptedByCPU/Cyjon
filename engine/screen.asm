;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

VARIABLE_SCREEN_VIDEO_ERROR_ACCESS_DENIED	equ	0x01

variable_screen_video_mode_semaphore		db	VARIABLE_FALSE
variable_screen_video_user_semaphore		db	VARIABLE_FALSE	; jeden z procesów ma dostęp na wyłączność do przestrzeni pamięci ekranu

; pozycja kursora na ekranie i w przestrzeni pamięci ekranu
variable_screen_cursor_indicator		dq	VARIABLE_SCREEN_TEXT_MODE_BASE_ADDRESS

variable_screen_base_address			dq	VARIABLE_SCREEN_TEXT_MODE_BASE_ADDRESS
variable_screen_base_address_end		dq	VARIABLE_SCREEN_TEXT_MODE_BASE_ADDRESS + VARIABLE_SCREEN_TEXT_MODE_SIZE_IN_BYTES
variable_screen_size				dq	VARIABLE_SCREEN_TEXT_MODE_SIZE_IN_BYTES
variable_screen_width				dq	VARIABLE_SCREEN_TEXT_MODE_WIDTH
variable_screen_width_on_chars			dq	VARIABLE_SCREEN_TEXT_MODE_WIDTH
variable_screen_width_scan_line			dq	VARIABLE_SCREEN_TEXT_MODE_WIDTH
variable_screen_height				dq	VARIABLE_SCREEN_TEXT_MODE_HEIGHT
variable_screen_height_on_chars			dq	VARIABLE_SCREEN_TEXT_MODE_HEIGHT
variable_screen_depth				dq	VARIABLE_EMPTY
variable_screen_line_of_chars_in_bytes		dq	VARIABLE_SCREEN_TEXT_MODE_WIDTH * VARIABLE_SCREEN_TEXT_MODE_CHAR_SIZE
variable_screen_char_width_in_bytes		dq	VARIABLE_SCREEN_TEXT_MODE_CHAR_SIZE
variable_screen_cursor				dq	VARIABLE_EMPTY
variable_screen_cursor_width			dq	2	; szerokość kursora w pikselach
; siła blokady kursora, im więcej procedur modyfikuje pamięć ekranu tym silniejsza
variable_screen_cursor_lock_level		dq	VARIABLE_EMPTY

; indeksowana paleta kolorów 32 bitowych na podstawie trybu tekstowego
table_color_palette_32_bit			dd	0x00000000	; czarny
						dd	0x000000A8	; niebieski
						dd	0x0000A800	; zielony
						dd	0x0000A8A8	; seledynowy
						dd	0x00A80000	; czerwony
						dd	0x00A800A8	; fioletowy
						dd	0x00A85700	; brązowy
						dd	0x00A8A8A8	; jasno-szary
						dd	0x00575757	; szary
						dd	0x005757ff	; jasno-niebieski
						dd	0x0057ff57	; jasno-zielony
						dd	0x0057ffff	; jasno-seledynowy
						dd	0x00ff5757	; jasno-czerwony
						dd	0x00ff57ff	; jasno-fioletowy
						dd	0x00ffff57	; żółty
						dd	0x00ffffff	; biały

; 64 Bitowy kod programu
[BITS 64]

cyjon_screen_init:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx

	; sprawdź czy wskaźnik do mapy trybu graficznego jest ustawiony
	cmp	rdi,	VARIABLE_EMPTY
	je	.no_graphics_mode

	; pobierz podstawowe informacje o trybie graficznym

	; adres przestrzeni pamięci ekranu trybu graficznego
	mov	eax,	dword [rdi + STRUCTURE_MODE_INFO_BLOCK.PhysicalVideoAddress]
	mov	qword [variable_screen_base_address],	rax
	mov	qword [variable_screen_base_address_end],	rax
	; wskaźnik kursora w przestrzeni pamięci ekranu w trybie graficznym
	mov	qword [variable_screen_cursor_indicator],	rax

	; szerokość rozdzielczości w pikselach
	movzx	eax,	word [rdi + STRUCTURE_MODE_INFO_BLOCK.XResolution]
	mov	qword [variable_screen_width],	rax

	; szerokość rozdzielczości (rzeczywista ekranu, za pikselami może być PARĘ dodatkowych [niewidocznych na ekranie]) Bajtów
	mov	ax,	word [rdi + STRUCTURE_MODE_INFO_BLOCK.BytesPerScanLine]
	mov	qword [variable_screen_width_scan_line],	rax

	; oblicz rozmiar linii znaków w Bajtach
	xor	rdx,	rdx
	mul	qword [matrix_font_y_in_pixels]
	mov	qword [variable_screen_line_of_chars_in_bytes],	rax

	; wysokość rozdzielczości w pikselach
	mov	ax,	word [rdi + STRUCTURE_MODE_INFO_BLOCK.YResolution]
	mov	qword [variable_screen_height],	rax

	; głębia kolorów w bitach
	movzx	ax,	byte [rdi + STRUCTURE_MODE_INFO_BLOCK.BitsPerPixel]
	shr	ax,	VARIABLE_DIVIDE_BY_8
	mov	qword [variable_screen_depth],	rax

	; oblicz rozmiar przestrzeni pamięci
	; zamień bity głębi kolorów na ilość bajtów opisujących piksel
	xor	rdx,	rdx	; brak starszej części
	mul	qword [variable_screen_width_scan_line]
	mul	qword [variable_screen_height]
	mov	qword [variable_screen_size],	rax
	; oblicz koniec przestrzeni pamięci ekranu trybu graficznego
	add	qword [variable_screen_base_address_end],	rax

	; oblicz szekorość znaku w Bajtach
	mov	rax,	qword [matrix_font_x_in_pixels]
	mov	rcx,	qword [variable_screen_depth]
	shr	rcx,	VARIABLE_DIVIDE_BY_2
	shl	rax,	cl
	mov	qword [variable_screen_char_width_in_bytes],	rax

	; oblicz ilość znaków na szerokość ekranu
	mov	rax,	qword [variable_screen_width]
	xor	rdx,	rdx
	div	qword [matrix_font_x_in_pixels]
	mov	qword [variable_screen_width_on_chars],	rax

	; oblicz ilość znaków na wysokość ekranu
	mov	rax,	qword [variable_screen_height]
	xor	rdx,	rdx
	div	qword [matrix_font_y_in_pixels]
	mov	qword [variable_screen_height_on_chars],	rax

	; włącz informację o trybie graficznym
	mov	byte [variable_screen_video_mode_semaphore],	VARIABLE_TRUE

.no_graphics_mode:
	; wyczyść cały ekran
	xor	rbx,	rbx
	xor	rcx,	rcx
	call	cyjon_screen_clear

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; na podstawie współrzędnych wirtualnego kursora oblicza adres w przestrzeni pamięci ekranu
; IN:
;	rbx - pozycja kursora
;
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_screen_cursor_indicator:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rbx

	; oblicz przesunięcie do określonej linii Y
	mov	rax,	qword [variable_screen_line_of_chars_in_bytes]
	xor	rdx,	rdx
	mul	dword [rsp + VARIABLE_QWORD_HIGH]

	; ustaw wskaźnik kursora na początek ekranu
	mov	rdi,	qword [variable_screen_base_address]
	add	rdi,	rax	; przesuń wskaźnik na obliczoną linię

	; oblicz przesunięcie do określonej kolumny X
	mov	eax,	dword [rsp]
	mul	qword [variable_screen_char_width_in_bytes]

	; zapisz wskaźnik adresu w przestrzeni pamięci ekranu odpowiadający położeniu kursora
	add	rdi,	rax
	mov	qword [variable_screen_cursor_indicator],	rdi

	; przywróć oryginalne rejestry
	pop	rbx
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;=======================================================================
; czyści ekran na domyślny kolor tła
; IN:
;	brak
;
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_screen_clear:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rdi

	; tryb graficzny?
	cmp	byte [variable_screen_video_mode_semaphore],	VARIABLE_TRUE
	je	.graphics

	; początek przestrzeni pamięci ekranu
	mov	rdi,	VARIABLE_SCREEN_TEXT_MODE_BASE_ADDRESS

	; zacznij od linii Y?
	cmp	rbx,	VARIABLE_EMPTY
	je	.from_begin

	; oblicz numer linii, od której rozpocząć czyszczenie ekranu
	mov	rax,	qword [variable_screen_line_of_chars_in_bytes]
	mul	rbx

	; koryguj początek
	add	rdi,	rax

.from_begin:
	; ograniczona ilość linii?
	cmp	rcx,	VARIABLE_EMPTY
	je	.all_of_them

	; oblicz ilość linii do wyczyszczenia
	mov	rax,	qword [variable_screen_width_on_chars]
	mul	rcx
	mov	rcx,	rax

	; kontynuuj
	jmp	.prepared

.all_of_them:
	; rozmiar przestrzeni pamięci do wyczyszczenia
	mov	rcx,	VARIABLE_SCREEN_TEXT_MODE_SIZE

.prepared:
	; ustaw domyślną kolorystykę i znak czyszczenia "spacja"
	mov	al,	VARIABLE_ASCII_CODE_SPACE
	mov	ah,	VARIABLE_COLOR_DEFAULT + VARIABLE_COLOR_BACKGROUND_DEFAULT

.loop:
	; wyczyść pierwszy znak
	stosw

	; zmniejsz ilość przestrzeni do przetworzenia
	dec	rcx

	; jeśli pozostały następne
	jnz	.loop	; kontynuuj

	; ustaw kursor na początek ekranu i przestrzeni pamięci ekranu
	mov	qword [variable_screen_cursor_indicator],	VARIABLE_SCREEN_TEXT_MODE_BASE_ADDRESS

	; zresetuj pozycje wirtualnego kursora
	mov	qword [variable_screen_cursor],	VARIABLE_EMPTY

	; ustaw kursor na swoją pozycję
	call	cyjon_screen_cursor_move

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót
	ret

.graphics:
	; wyłącz kursor
	call	cyjon_screen_cursor_lock

	; początek przestrzeni pamięci trybu graficznego
	mov	rdi,	qword [variable_screen_base_address]
	; wirtualny kursor na początek ekranu
	mov	qword [variable_screen_cursor],	VARIABLE_EMPTY

	; zacznij od linii Y?
	cmp	rbx,	VARIABLE_EMPTY
	je	.graphics_from_begin

	; oblicz numer linii, od której rozpocząć czyszczenie ekranu
	mov	rax,	qword [variable_screen_line_of_chars_in_bytes]
	mul	rbx

	; koryguj początek
	add	rdi,	rax

.graphics_from_begin:
	; ograniczona ilość linii?
	cmp	rcx,	VARIABLE_EMPTY
	je	.graphics_all_of_them

	; oblicz ilość linii do wyczyszczenia
	mov	rax,	qword [variable_screen_line_of_chars_in_bytes]
	mul	rcx
	mov	rcx,	rax

	; kontynuuj
	jmp	.graphics_prepared

.graphics_all_of_them:
	; wyczyść całą przestrzeń
	mov	rcx,	qword [variable_screen_size]

.graphics_prepared:
	; domyślny kolor tła
	mov	rax,	VARIABLE_COLOR_BACKGROUND_DEFAULT >> VARIABLE_SHIFT_BY_4
	mov	eax,	dword [table_color_palette_32_bit + rax * VARIABLE_DWORD_SIZE]

	; wyczyść
	shr	rcx,	VARIABLE_DIVIDE_BY_4
	rep	stosd

	; zresetuj pozycje kursora
	xor	rbx,	rbx
	call	cyjon_screen_cursor_indicator

	; zapisz pozycje
	mov	qword [variable_screen_cursor],	rbx

	; włącz kursor
	call	cyjon_screen_cursor_unlock

	; koniec
	jmp	.end

;===============================================================================
; ustawia kursor sprzętowy w odpowiednim miejscu ekranu
; IN:
;	brak
;
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_screen_cursor_move:
	; tryb graficzny?
	cmp	byte [variable_screen_video_mode_semaphore],	VARIABLE_TRUE
	je	.leave

	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx

	; oblicz przesunięcie kursora względem początku przestrzeni pamięci ekranu
	mov	rcx,	qword [variable_screen_cursor_indicator]
	sub	rcx,	VARIABLE_SCREEN_TEXT_MODE_BASE_ADDRESS
	shr	rcx,	1	; usuń atrybuty

	; młodszy port kursora (rejestr indeksowy VGA)
	mov	al,	0x0F
	mov	dx,	0x03D4
	out	dx,	al

	inc	dx	; 0x03D5
	mov	al,	cl
	out	dx,	al

	; starszy port kursora
	mov	al,	0x0E
	dec	dx
	out	dx,	al

	inc	dx
	mov	al,	ch
	out	dx,	al

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rcx
	pop	rax

.leave:
	; powrót z procedury
	ret

;=======================================================================
; wyświetla znak pod adresem wskaźnika w przestrzeni pamięci ekranu
; IN:
;	al - kod ASCII znaku do wyświetlenia
;	bl - kolor znaku
;	dl - kolor tła znaku
;	rdi - wskaźnik przestrzeni pamięci ekranu dla pozycji wyświetlanego znaku
;
; OUT:
;	rdi - wskaźnik do następnego znaku w przestrzeni pamięci ekranu
;
; pozostałe rejestry zachowane
cyjon_screen_print_char:
	; tryb graficzny?
	cmp	byte [variable_screen_video_mode_semaphore],	VARIABLE_TRUE
	je	.graphics

	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx

	; ustaw kolor i tło znaku
	mov	ah,	bl
	add	ah,	dl

.loop:
	cmp	al,	VARIABLE_ASCII_CODE_ENTER
	je	.enter

	cmp	al,	VARIABLE_ASCII_CODE_NEWLINE
	je	.new_line

	cmp	al,	VARIABLE_ASCII_CODE_BACKSPACE
	je	.backspace

	; zapisz znak do przestrzeni pamięci ekranu
	stosw

	; przesuń wirtualny kursor o jedną pozycję w prawo
	inc	dword [variable_screen_cursor]

.continue:
	; wyświetlono znak odpowiednią ilość razy?
	dec	rcx
	jnz	.loop

	; przywróć oryginalne rejestry
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

.enter:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdx

	; zachowaj wskaźnik w przestrzeni pamięci
	push	rdi

	; oblicz przesunięcie względem początku przestrzeni pamięci
	sub	rdi,	VARIABLE_SCREEN_TEXT_MODE_BASE_ADDRESS
	shr	rdi,	1	; usuń atrybuty

	; oblicz rozmiar aktualnej linii
	mov	rax,	rdi
	mov	rcx,	VARIABLE_SCREEN_TEXT_MODE_WIDTH
	xor	rdx,	rdx
	div	rcx

	; przywróć przesunięcie względem poczatku przestrzeni pamięci
	pop	rdi

	; przesuń wskaźnik na początek tej linii
	shl	rdx,	1	; dodaj atrybuty
	sub	rdi,	rdx

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rcx

	; przesuń wirtualny kursor na poczatek linii
	mov	dword [variable_screen_cursor],	VARIABLE_EMPTY

	; koniec obsługi
	jmp	.continue

.new_line:
	; przesuń wskaźnik kursora w przestrzeni pamięci ekranu o rozmiar linii
	add	rdi,	qword [variable_screen_line_of_chars_in_bytes]

	; przesuń wirtualny kursor do nowej linii
	inc	dword [variable_screen_cursor + VARIABLE_QWORD_HIGH]

	; koniec obsługi
	jmp	.continue

.backspace:
	; sprawdź czy kursor znajduje się na początku linii
	cmp	dword [variable_screen_cursor],	VARIABLE_EMPTY
	ja	.no_start_line

	; sprawdź czy można się cofnąć o jedną linię wcześniej
	cmp	dword [variable_screen_cursor + VARIABLE_DWORD_SIZE],	VARIABLE_EMPTY
	je	.continue	; kursora nie można ustawić poza ekranem

	; przesuń kursor o jedną linię wyżej
	dec	dword [variable_screen_cursor + VARIABLE_DWORD_SIZE]
	; na koniec linii
	mov	rbx,	qword [variable_screen_width_on_chars]
	dec	rbx
	mov	dword [variable_screen_cursor],	ebx

	; usuń znak z nowego miejsca
	jmp	.backspace_print

.no_start_line:
	; przesuń kursor o jedną pozycję w lewo
	dec	dword [variable_screen_cursor]

.backspace_print:
	; cofnij wskaźnik o rozmiar znaku
	sub	rdi,	qword [variable_screen_char_width_in_bytes]

	; zastąp znak w przestrzeni pamięci ekranu czystym
	mov	al,	VARIABLE_ASCII_CODE_SPACE
	mov	word [rdi],	ax

	; koniec obsługi
	jmp	.continue

.graphics:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	r8
	push	r9
	push	rdx

	; zachowaj wskaźnik
	mov	r9,	rdi

	; sprawdź czy znaki specjalne
	cmp	al,	VARIABLE_ASCII_CODE_ENTER
	je	.graphics_enter
	cmp	al,	VARIABLE_ASCII_CODE_NEWLINE
	je	.graphics_new_line
	cmp	al,	VARIABLE_ASCII_CODE_BACKSPACE
	je	.graphics_backspace

	; oblicz przesunięcie w macierzy znaków
	xor	rdx,	rdx
	mov	r8,	qword [matrix_font_x_in_pixels]
	cmp	byte [matrix_font_semaphore],	VARIABLE_FALSE
	je	.compressed
	
	; czcionka nieskompresowana
	inc	r8
	mul	r8

.compressed:
	mul	qword [matrix_font_y_in_pixels]

	; ustaw wskaźnik na macierz znaku do wyświetlenia
	mov	rsi,	matrix_font
	add	rsi,	rax

	; ustaw kolor i tło wypisywanych znaków
	mov	ebx,	dword [table_color_palette_32_bit + rbx * VARIABLE_DWORD_SIZE]
	mov	rdx,	qword [rsp]	; przywróć kolor tła
	shr	rdx,	VARIABLE_SHIFT_BY_4
	mov	edx,	dword [table_color_palette_32_bit + rdx * VARIABLE_DWORD_SIZE]

	; wysokość znaku w pikselach
	mov	r8,	qword [matrix_font_y_in_pixels]

	; przetwarzać czcionkę skompresowaną?
	cmp	byte [matrix_font_semaphore],	VARIABLE_FALSE
	je	.compressed_char_N

.char_N:
	; przywróć wskaźnik
	mov	rdi,	r9

	; zachowaj ilość kopii znaku do wyświetlenia
	; wskaźnik do macierzy i wysokość znaku w pikselach
	push	rcx
	push	rsi
	push	r8

.restart:
	; szerokość znaku w pikselach
	mov	rcx,	qword [matrix_font_x_in_pixels]

	; przesuń wskaźnik na macierz znaku (pomiń flgę)
	inc	rsi

	; sprawdź flagę linii macierzy znaku
	cmp	byte [rsi - VARIABLE_BYTE_SIZE],	VARIABLE_FALSE
	je	.background_full	; brak bikseli, wyświetl w całej linii tło

.line:
	; pobierz stan piksela z macierzy znaku
	lodsb

	; włączyć czy wyłączyć piksel?
	cmp	al,	VARIABLE_EMPTY
	je	.background

	; włącz
	mov	eax,	ebx
	stosd

	; następny piksel
	jmp	.line_continue

.background:
	; wyłącz
	mov	eax,	edx
	stosd

.line_continue:
	; następny piksel
	loop	.line

.matrix_continue:
	; koniec N-tej linii w macierzy znaku?
	dec	r8
	jz	.ready	; znak wyświetlony

	; przesuń wskaźnik w przestrzeni pamięci do następnej linii znaku

	; dodaj szerokość rozdzielczości w Bajtach
	add	rdi,	qword [variable_screen_width_scan_line]
	; odejmij szerokość WYŚWIETLONEJ linii macierzy znaku w Bajtach
	sub	rdi,	qword [variable_screen_char_width_in_bytes]

	; kontynuuj od następnej linii
	jmp	.restart

.background_full:
	; wyłącz piksele
	mov	eax,	edx
	rep	stosd

	; przesuń wskaźnik na następną linię macierzy znaku
	add	rsi,	qword [matrix_font_x_in_pixels]

	; kontynuuj pozostałe linie
	jmp	.matrix_continue

.ready:
	; przesuń wirtualny kursor o jedną pozycję w prawo
	inc	dword [variable_screen_cursor]

	; zwróć wskaźnik do pozycji następnego znaku w przestrzeni pamięci
	add	r9,	qword [variable_screen_char_width_in_bytes]

	; przywróć ilość kopii znaku do wyświetlenia
	; wskaźnik do macierzy i wysokość znaku w pikselach
	pop	r8
	pop	rsi
	pop	rcx

	; wyświetl pozostałą ilość
	loop	.char_N

.end:
	; zwróć aktualny wskaźnik
	mov	rdi,	r9

	; przywróć oryginalne rejestry
	pop	rdx
	pop	r9
	pop	r8
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
.compressed_char_N:
	; przywróć wskaźnik
	mov	rdi,	r9

	; zachowaj ilość kopii znaku do wyświetlenia
	; wskaźnik do macierzy i wysokość znaku w pikselach
	push	rcx
	push	rsi
	push	r8

.compressed_next_line:
	; szerokość matrycy znaku w pikselach
	mov	rcx,	qword [matrix_font_x_in_pixels]

	; koryguj wskaźnik pozycji bitu w matrycy linii znaku
	dec	rcx

.compressed_check_pixel:
	; sprawdź czy bit zapalony
	bt	word [rsi],	cx
	jnc	.compressed_background	; nie, tło

	; wyświetl piksel o sprecyzowanym kolorze
	mov	rax,	rbx
	stosd

	; kontynuuj
	jmp	.compressed_continue_line

.compressed_background:
	; wyświetl piksel o sprecyzowanym kolorze
	mov	rax,	rdx
	stosd

.compressed_continue_line:
	; następny piksel
	dec	rcx

	; sprawdź czy koniec bitów dla znaku
	cmp	rcx,	VARIABLE_FULL
	jne	.compressed_check_pixel

	; koniec N-tej linii w macierzy znaku?
	dec	r8
	jz	.compressed_ready

	; przesuń wskaźnik w przestrzeni pamięci do następnej linii znaku

	; dodaj szerokość rozdzielczości w Bajtach
	add	rdi,	qword [variable_screen_width_scan_line]
	; odejmij szerokość WYŚWIETLONEJ linii macierzy znaku w Bajtach
	sub	rdi,	qword [variable_screen_char_width_in_bytes]

	; przesuń wskaźnik na opis następnej linii
	inc	rsi

	; następna linia macierzy znaku
	jmp	.compressed_next_line

.compressed_ready:
	; przesuń wirtualny kursor o jedną pozycję w prawo
	inc	dword [variable_screen_cursor]

	; zwróć wskaźnik do pozycji następnego znaku w przestrzeni pamięci
	add	r9,	qword [variable_screen_char_width_in_bytes]

	; przywróć ilość kopii znaku do wyświetlenia
	; wskaźnik do macierzy i wysokość znaku w pikselach
	pop	r8
	pop	rsi
	pop	rcx

	; wyświetl pozostałą ilość
	loop	.compressed_char_N

	; koniec
	jmp	.end

;===============================================================================

.graphics_enter:
	; oblicz pozycję wskaźnika na początku linii znaków
	mov	rax,	qword [variable_screen_line_of_chars_in_bytes]
	xor	rdx,	rdx
	mul	dword [variable_screen_cursor + VARIABLE_QWORD_HIGH]
	add	rax,	qword [variable_screen_base_address]

	; ustaw nowy wskaźnik
	mov	r9,	rax

	; ustaw wirtualny kursor na początku ekranu
	mov	dword [variable_screen_cursor],	VARIABLE_EMPTY

	; koniec
	jmp	.end

.graphics_new_line:
	; przesuń wskaźnik do następnej linii
	add	r9,	qword [variable_screen_line_of_chars_in_bytes]

	; przesuń wirtualny kursor na następną linię
	inc	dword [variable_screen_cursor + VARIABLE_QWORD_HIGH]

	; koniec
	jmp	.end

.graphics_backspace:
	; przywróć wskaźnik
	mov	rdi,	r9

	; sprawdź czy kursor znajduje się na początku linii
	cmp	dword [variable_screen_cursor],	VARIABLE_EMPTY
	ja	.no

	; sprawdź czy można się cofnąć o jedną linię wcześniej
	cmp	dword [variable_screen_cursor + VARIABLE_DWORD_SIZE],	VARIABLE_EMPTY
	je	.end	; kursora nie można ustawić poza ekranem

	; przesuń kursor o jedną linię wyżej
	dec	dword [variable_screen_cursor + VARIABLE_DWORD_SIZE]

	; przesuń kursor na koniec linii
	mov	rax,	qword [variable_screen_width_on_chars]
	mov	dword [variable_screen_cursor],	eax
	; koryguj
	dec	qword [variable_screen_cursor]

	; oblicz wskaźnik
	jmp	.calculate

.no:
	; przesuń kursor o jedną pozycję w lewo
	dec	dword [variable_screen_cursor]

.calculate:
	; oblicz położenie wskaźnika w przestrzeni pamięci ekranu
	mov	rbx,	qword [variable_screen_cursor]
	push	rbx	; zachowaj
	call	cyjon_screen_cursor_indicator

	; wyczyść znak w nowym miejscu
	mov	eax,	VARIABLE_ASCII_CODE_SPACE
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	VARIABLE_TRUE	; 1 znak
	mov	rdi,	qword [variable_screen_cursor_indicator]
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	call	cyjon_screen_print_char

	; zachowaj wskaźnik
	mov	r9,	rdi

	; przywróć pozycje wirtualnego kursora
	pop	rbx
	mov	qword [variable_screen_cursor],	rbx

	; koniec
	jmp	.end

;=======================================================================
; wyświetla ciąg znaków spod wskaźnika RSI, zakończony terminatorem lub ilością na podstawie rejestru RCX
; IN:
;	ebx - kolor znaku
;	rcx - ilość znaków do wyświetlenia z ciągu
;	edx - kolor tła znaku
;	rsi - wskaźnik przestrzeni pamięci ekranu dla pozycji wyświetlanego znaku
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_screen_print_string:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi
	push	rdi

	; wyłącz kursor
	call	cyjon_screen_cursor_lock

	; pobierz wskaźnik aktualnego miejsca położenia matrycy znaku do wypisania na ekranie
	mov	rdi,	qword [variable_screen_cursor_indicator]

	; sprawdź czy wskazano ilość znaków do wyświetlenia
	cmp	rcx,	VARIABLE_EMPTY
	je	.end	; jeśli nie, zakończ działanie

	; wyczyść
	xor	rax,	rax

.string:
	; pobierz znak z ciągu tekstu
	lodsb	; załaduj do rejestru AL Bajt pod adresem w wskaźniku RSI, zwiększ wskaźnik RSI o jeden

	; sprawdź czy koniec ciągu
	cmp	al,	VARIABLE_ASCII_CODE_TERMINATOR
	je	.end	; jeśli tak, koniec

	; zachowaj licznik
	push	rcx

	; wyświetl znak na ekranie
	mov	rcx,	1
	call	cyjon_screen_print_char

	; zapisz aktualną pozycję kursora w przestrzeni pamięci ekranu
	mov	qword [variable_screen_cursor_indicator],	rdi

	; sprawdź pozycje kursora
	call	cyjon_screen_cursor_virtual

	; przywróć licznik
	pop	rcx

	; wyświetl pozostałe znaki z ciągu
	dec	rcx
	jnz	.string

.end:
	; zapisz aktualny wskaźnik kursora
	mov	qword [variable_screen_cursor_indicator],	rdi

	; włącz kursor
	call	cyjon_screen_cursor_unlock

	; ustaw kursor na końcu wyświetlonego tekstu
	call	cyjon_screen_cursor_move

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;=======================================================================
; sprawdź pozycję wirtualnego kursora
; IN:
;	brak
; OUT:
;	rdi - aktualny wskaźnk kursora w przestrzeni pamięci ekranu
;
; pozostałe rejestry zachowane
cyjon_screen_cursor_virtual:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx

	; czy wirtualny kursor znajduje się za daleko na prawo?
	mov	eax,	dword [variable_screen_cursor]
	cmp	rax,	qword [variable_screen_width_on_chars]
	jb	.x_ok

	; przesuń kursor na początek nowej linii
	mov	dword [variable_screen_cursor],	VARIABLE_EMPTY
	inc	dword [variable_screen_cursor + VARIABLE_QWORD_HIGH]	

.x_ok:
	; czy wirtualny kursor znajduje się za daleko w dół?
	mov	eax,	dword [variable_screen_cursor + VARIABLE_QWORD_HIGH]
	cmp	rax,	qword [variable_screen_height_on_chars]
	jb	.y_ok

	; przesuń kursor na poprzednią linię
	dec	dword [variable_screen_cursor + VARIABLE_QWORD_HIGH]

	; przewiń zawartość ekranu do góry o jedną linię
	call	cyjon_screen_scroll

.y_ok:
	; oblicz nowy wskaźnik kursora w przestrzeni ekranu

	; wiersz
	mov	rax,	qword [variable_screen_line_of_chars_in_bytes]
	xor	rdx,	rdx
	mul	dword [variable_screen_cursor + VARIABLE_QWORD_HIGH]

	; ustaw wskaźnik kursora na poczatek ekranu
	mov	rdi,	qword [variable_screen_base_address]
	add	rdi,	rax	; przesuń wskaźnik na odpowednią linię

	; kolumna
	mov	eax,	dword [variable_screen_cursor]
	mul	qword [variable_screen_char_width_in_bytes]

	; zwróć sumę przesunięć jak i wskaźnik adresu w przestrzeni pamięci ekranu odpowiadający położeniu kursora
	add	rdi,	rax

	; zapamietaj
	mov	qword [variable_screen_cursor_indicator],	rdi

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;=======================================================================
; przewija zawartość ekranu o jedną linię do góry
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_screen_scroll:
	; zachowaj oryginalne rejestryl
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; adres docelowy przesunięcia zawartości pamięci ekranu na początek
	mov	rdi,	qword [variable_screen_base_address]

	; oblicz adres źródłowy przsunięcia zawartości ekranu
	mov	rsi,	rdi
	add	rsi,	qword [variable_screen_line_of_chars_in_bytes]

	; rozmiar pamięci do przesunięcia (Y linii)
	mov	rcx,	qword [variable_screen_size]
	; skopiuj Y - 1 linii, skopiuj z 1..Y do 0..Y-1
	sub	rcx,	qword [variable_screen_line_of_chars_in_bytes]

	; tryb graficzny?
	cmp	byte [variable_screen_video_mode_semaphore],	VARIABLE_TRUE
	je	.graphics

	; przesuń zawartość pamięci
	shr	rcx,	VARIABLE_DIVIDE_BY_2
	rep	movsw

	; wyczyść ostatnią linię
	mov	al,	VARIABLE_ASCII_CODE_SPACE
	mov	ah,	VARIABLE_COLOR_DEFAULT | VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rcx,	VARIABLE_SCREEN_TEXT_MODE_WIDTH
	mov	rdi,	VARIABLE_SCREEN_TEXT_MODE_BASE_ADDRESS + VARIABLE_SCREEN_TEXT_MODE_SIZE_IN_BYTES - VARIABLE_SCREEN_TEXT_MODE_LINE_SIZE
	rep	stosw

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

.graphics:
	; http://forum.4programmers.net/Off-Topic/250332-cyjon_os?p=1268711#id1268711
	shr	rcx,	VARIABLE_DIVIDE_BY_128

.graphics_loop:
	prefetchnta	[rsi + 128]
	prefetchnta	[rsi + 160]
	prefetchnta	[rsi + 192]
	prefetchnta	[rsi + 224]

	movdqa	xmm0,	[rsi]
	movdqa	xmm1,	[rsi + 16]
	movdqa	xmm2,	[rsi + 32]
	movdqa	xmm3,	[rsi + 48]
	movdqa	xmm4,	[rsi + 64]
	movdqa	xmm5,	[rsi + 80]
	movdqa	xmm6,	[rsi + 96]
	movdqa	xmm7,	[rsi + 112]

	movntdq	[rdi],	xmm0
	movntdq	[rdi + 16],	xmm1
	movntdq	[rdi + 32],	xmm2
	movntdq	[rdi + 48],	xmm3
	movntdq	[rdi + 64],	xmm4
	movntdq	[rdi + 80],	xmm5
	movntdq	[rdi + 96],	xmm6
	movntdq	[rdi + 112],	xmm7

	add	rsi,	128
	add	rdi,	128
	dec	rcx
	jnz	.graphics_loop

	; wyczyść ostatnią linię
	mov	rax,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	shr	rax,	VARIABLE_SHIFT_BY_4
	mov	eax,	dword [table_color_palette_32_bit + rax * VARIABLE_DWORD_SIZE]
	mov	rcx,	qword [variable_screen_line_of_chars_in_bytes]
	shr	rcx,	VARIABLE_DIVIDE_BY_4
	rep	stosd

	; koniec
	jmp	.end

;=======================================================================
; wyświetla liczbę o podanej podstawie
; IN:
;	rax - liczba/cyfra do wyświetlenia
;	rbx - kolor liczby
;	cl - podstawa liczbowa
;	ch - uzupełnienie o zera np.
;		ch=4 dla liczby 257 > (0x)0101 lub 0257
;		ch=4 dla liczby 15 > (0x)000F lub 0015
;	rdx - kolor tła tło
;	rdi - wskaźnik przestrzeni pamięci ekranu dla pozycji wyświetlanej liczby
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_screen_print_number:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rdi
	push	rbp
	push	r8
	push	r9
	push	r10

	; wyłącz kursor
	call	cyjon_screen_cursor_lock

	; sprawdź czy podstawa liczby dozwolona
	cmp	cl,	2
	jb	.end	; brak obsługi

	; sprawdź czy podstawa liczby dozwolona
	cmp	cl,	36
	ja	.end	; brak obsługi

	; zapamiętaj kolor tła
	mov	r8,	rdx

	; wyczyść starszą część / resztę z dzielenia
	xor	rdx,	rdx

	; zapamiętaj flagi
	mov	r9w,	cx
	shr	r9,	8

	; wyczyść uzupełnienie
	xor	ch,	ch

	; utwórz stos zmiennych lokalnych
	mov	rbp,	rsp

	; zresetuj licznik cyfr
	xor	r10,	r10

	; usuń zbędne wartości
	and	rcx,	0x00000000000000FF

.loop:
	; oblicz resztę z dzielenia
	div	rcx

	; licznik cyfr
	inc	r10

	; zapisz resztę z dzielenia do zmiennych lokalnych
	push	rdx

	; wyczyść resztę z dzielenia
	xor	rdx,	rdx

	; sprawdź czy przeliczać dalej
	cmp	rax,	VARIABLE_EMPTY
	ja	.loop	; jeśli tak, powtórz działanie

	; przywróć kolor tła liczby
	mov	rdx,	r8

	; załaduj wskaźnik pozycji kursora
	mov	rdi,	qword [variable_screen_cursor_indicator]

	; wyświetlaj po jednej kopii cyfry
	mov	rcx,	1

	; sprawdź zasadność flagi
	cmp	r10,	r9
	jae	.print	; brak uzupełnienia

	; oblicz różnicę
	sub	r9,	r10

.zero_before:
	push	VARIABLE_EMPTY	; zero digit

	dec	r9
	jnz	.zero_before

.print:
	; pobierz z zmiennych lokalnych cyfrę
	pop	rax

	; przemianuj cyfrę na kod ASCII
	add	rax,	0x30

	; sprawdź czy system liczbowy powyżej podstawy 10
	cmp	al,	0x3A
	jb	.no	; jeśli nie, kontynuuj

	; koryguj kod ASCII do odpowiedniej podstawy liczbowej
	add	al,	0x07

.no:
	; wyświetl cyfrę
	call	cyjon_screen_print_char

	; sprawdź pozycje kursora
	call	cyjon_screen_cursor_virtual

	; sprawdź czy pozostały cyfry do wyświetlenia z liczby
	cmp	rsp,	rbp
	jne	.print	; jeśli tak, wyświetl pozostałe

	; zapisz nowy wskaźnik kursora
	mov	qword [variable_screen_cursor_indicator],	rdi

	; ustaw kursor na końcu wyświetlonego tekstu
	call	cyjon_screen_cursor_move

.end:
	; włącz kursor
	call	cyjon_screen_cursor_unlock

	; przywróć oryginalne rejestry
	pop	r10
	pop	r9
	pop	r8
	pop	rbp
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wyświetla lub ukrywa kursor
; IN:
;	rdi - wskaźnik kursora w przestrzeni pamięci
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_screen_cursor_invert:
	; zachowaj oryginalne rejestrt
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rdi

	; wysokość kursora
	mov	rbx,	qword [matrix_font_y_in_pixels]

	; szerokosć kursora w bitach
	mov	rcx,	qword [variable_screen_depth]
	shr	rcx,	VARIABLE_DIVIDE_BY_2

.loopY:
	; szerokość kursora
	mov	rdx,	qword [variable_screen_cursor_width]

.loopX:
	; pobierz kolor piksela
	mov	eax,	dword [rdi]
	not	eax	; inwersja
	and	eax,	VARIABLE_COLOR_MASK	; usuń maskę

	; zapisz kolor piksela
	stosd

	; nastepny piksel
	dec	rdx
	jnz	.loopX

	; przesuń wskaźnik w przestrzeni pamięci do następnej linii znaku

	; dodaj szerokość rozdzielczości w Bajtach
	add	rdi,	qword [variable_screen_width_scan_line]
	; odejmij szerokość WYŚWIETLONEJ linii macierzy znaku w Bajtach
	mov	rax,	qword [variable_screen_cursor_width]
	shl	rax,	cl	; zamień na Bajty
	sub	rdi,	rax

	; następna linia
	dec	rbx
	jnz	.loopY

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; procedura decyduje czy kursor wyłączyć lub zwiększyć poziom blokady
; IN:
;	rdi - wskaźnik kursora w przestrzeni pamięci
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_screen_cursor_lock:
	; tryb tekstowy?
	cmp	byte [variable_screen_video_mode_semaphore],	VARIABLE_FALSE
	je	.text_mode

	; zachowaj oryginalne rejestry
	push	rdi

	cmp	byte [variable_screen_cursor_lock_level],	VARIABLE_FALSE
	jne	.level_up

	; wyłącz kursor
	mov	rdi,	qword [variable_screen_cursor_indicator]
	call	cyjon_screen_cursor_invert

.level_up:
	; zwiększ poziom blokady kursora
	inc	qword [variable_screen_cursor_lock_level]

	; przywróć oryginalne rejestry
	pop	rdi

.text_mode:
	; powrót z procedury
	ret

;===============================================================================
; procedura decyduje czy kursor włączyć lub zmniejszyć poziom blokady
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_screen_cursor_unlock:
	; tryb tekstowy?
	cmp	byte [variable_screen_video_mode_semaphore],	VARIABLE_FALSE
	je	.text_mode

	; zachowaj oryginalne rejestry
	push	rdi

	; zmniejsz poziom blokady
	dec	qword [variable_screen_cursor_lock_level]

	; sprawdź poziom blokady
	cmp	qword [variable_screen_cursor_lock_level],	VARIABLE_FALSE
	jne	.locked

	; włącz kursor
	mov	rdi,	qword [variable_screen_cursor_indicator]
	call	cyjon_screen_cursor_invert

.locked:
	; przywróć oryginalne rejestry
	pop	rdi

.text_mode:
	; powrót z procedury
	ret

;===============================================================================
; wyświetla ostatni komunikat jądra
; IN:
;	rsi - wskaźnik do ciągu tekstu
;
; OUT:
;	brak
;
; wszystkie rejestry zniszczone
cyjon_screen_kernel_panic:
	; wyświetl informację o błędzie wewnętrznym jądra systemu
	mov	bl,	VARIABLE_COLOR_LIGHT_RED
	mov	rcx,	VARIABLE_FULL
	mov	dl,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	call	cyjon_screen_print_string

	; zatrzymaj wykonywanie jakichkolwiek instrukcji procesora
	cli
	jmp	$
