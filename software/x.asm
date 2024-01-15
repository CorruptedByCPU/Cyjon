;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; zestaw imiennych wartości stałych jądra systemu
%include	'config.asm'

%define	VARIABLE_PROGRAM_NAME			x
%define	VARIABLE_PROGRAM_VERSION		"v0.4"

VARIABLE_X_COLOR_WHITE			equ	0x00FFFFFF
VARIABLE_X_COLOR_BACKGROUND		equ	0x00627D93
VARIABLE_X_COLOR_WINDOW_HEADER		equ	0x00E4E9EB
VARIABLE_X_COLOR_WINDOW_HEADER_SPACE	equ	VARIABLE_X_COLOR_WINDOW_HEADER - 0x00101010
VARIABLE_X_COLOR_BACKGROUND_WINDOW	equ	0x00FFFFFF

; 64 Bitowy kod programu
[BITS 64]

; adresowanie względne (skoki, etykiety)
[DEFAULT REL]

; adres kodu programu w przestrzeni logicznej
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]

start:
	; uzyskaj dostęp na wyłączność do przestrzeni pamięci ekranu
	mov	ax,	VARIABLE_KERNEL_SERVICE_VIDEO_ACCESS
	int	STATIC_KERNEL_SERVICE
	cmp	rbx,	VARIABLE_EMPTY
	jne	.access_denied

	; wyłącz kursor trybu tekstowego
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_HIDE
	int	STATIC_KERNEL_SERVICE

	; pobierz podstawowe informacje o ekranie
	mov	ax,	VARIABLE_KERNEL_SERVICE_VIDEO_INFO
	int	STATIC_KERNEL_SERVICE

	; zapisz
	mov	qword [variable_x_video_base_address],	rbx	; wskaźnik adresu początku przestrzeni pamięci ekranu
	mov	qword [variable_x_video_width],	r8		; szerokość w pikselach
	mov	qword [variable_x_video_height],	r9	; wysokość w pikselach
	mov	qword [variable_x_video_size],	rcx		; rozmiar przestrzeni pamięci ekranu w Bajtach
	mov	qword [variable_x_video_scanline],	rdx	; prawdziwa szerokość ekranu w Bajtach

	; wyczyść ekran na domyślny kolor
	mov	rax,	VARIABLE_X_COLOR_BACKGROUND
	call	x_video_clear

	; wyświetl okno / test
	mov	rbx,	VARIABLE_X_COLOR_BACKGROUND_WINDOW
	mov	r8,	50
	mov	r9,	50
	mov	r10,	320
	mov	r11,	180
	call	x_video_window

.access_denied:
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	VARIABLE_FULL
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_access_denied
	int	STATIC_KERNEL_SERVICE

.end:
	; zatrzymaj dalsze wykonywanie kodu
	jmp	$

	; koniec procesu
	xor	ax,	ax
	int	STATIC_KERNEL_SERVICE

; wejście:
;	rax - kod ASCII znaku do wyświetlenia
;	rbx - kolor znaku
;	rdi - wskaźnik przestrzeni pamięci ekranu dla pozycji wyświetlanego znaku
; wyjście:
;	rdi - wskaźnik do następnego znaku w przestrzeni pamięci ekranu
x_video_print_char:
;	; zachowaj oryginalne rejestry
;	push	rax
;	push	rbx
;	push	rcx
;	push	rsi
;	push	r8
;	push	r9
;	push	rdx
;
;	; zachowaj wskaźnik
;	mov	r9,	rdi
;
;	; sprawdź czy znaki specjalne
;	cmp	al,	VARIABLE_ASCII_CODE_ENTER
;	je	.enter
;	cmp	al,	VARIABLE_ASCII_CODE_NEWLINE
;	je	.new_line
;	cmp	al,	VARIABLE_ASCII_CODE_BACKSPACE
;	je	.backspace
;
;	; oblicz przesunięcie w macierzy znaków
;	xor	rdx,	rdx
;	mov	r8,	qword [matrix_font_x_in_pixels]
;	cmp	byte [matrix_font_semaphore],	VARIABLE_FALSE
;	je	.compressed
;	
;	; czcionka nieskompresowana
;	inc	r8
;	mul	r8
;
.compressed:
;	mul	qword [matrix_font_y_in_pixels]
;
;	; ustaw wskaźnik na macierz znaku do wyświetlenia
;	mov	rsi,	matrix_font
;	add	rsi,	rax
;
;	; ustaw kolor i tło wypisywanych znaków
;	mov	ebx,	dword [table_color_palette_32_bit + rbx * VARIABLE_DWORD_SIZE]
;	mov	rdx,	qword [rsp]	; przywróć kolor tła
;	shr	rdx,	VARIABLE_SHIFT_BY_4
;	mov	edx,	dword [table_color_palette_32_bit + rdx * VARIABLE_DWORD_SIZE]
;
;	; wysokość znaku w pikselach
;	mov	r8,	qword [matrix_font_y_in_pixels]
;
;	; przetwarzać czcionkę skompresowaną?
;	cmp	byte [matrix_font_semaphore],	VARIABLE_FALSE
;	je	.compressed_char_N
;
.char_N:
;	; przywróć wskaźnik
;	mov	rdi,	r9
;
;	; zachowaj ilość kopii znaku do wyświetlenia
;	; wskaźnik do macierzy i wysokość znaku w pikselach
;	push	rcx
;	push	rsi
;	push	r8
;
.restart:
;	; szerokość znaku w pikselach
;	mov	rcx,	qword [matrix_font_x_in_pixels]
;
;	; przesuń wskaźnik na macierz znaku (pomiń flgę)
;	inc	rsi
;
;	; sprawdź flagę linii macierzy znaku
;	cmp	byte [rsi - VARIABLE_BYTE_SIZE],	VARIABLE_FALSE
;	je	.background_full	; brak bikseli, wyświetl w całej linii tło
;
.line:
;	; pobierz stan piksela z macierzy znaku
;	lodsb
;
;	; włączyć czy wyłączyć piksel?
;	cmp	al,	VARIABLE_EMPTY
;	je	.background
;
;	; włącz
;	mov	eax,	ebx
;	stosd
;
;	; następny piksel
;	jmp	.line_continue
;
.background:
;	; wyłącz
;	mov	eax,	edx
;	stosd
;
.line_continue:
;	; następny piksel
;	loop	.line
;
.matrix_continue:
;	; koniec N-tej linii w macierzy znaku?
;	dec	r8
;	jz	.ready	; znak wyświetlony
;
;	; przesuń wskaźnik w przestrzeni pamięci do następnej linii znaku
;
;	; dodaj szerokość rozdzielczości w Bajtach
;	add	rdi,	qword [variable_screen_width_scan_line]
;	; odejmij szerokość WYŚWIETLONEJ linii macierzy znaku w Bajtach
;	sub	rdi,	qword [variable_screen_char_width_in_bytes]
;
;	; kontynuuj od następnej linii
;	jmp	.restart
;
.background_full:
;	; wyłącz piksele
;	mov	eax,	edx
;	rep	stosd
;
;	; przesuń wskaźnik na następną linię macierzy znaku
;	add	rsi,	qword [matrix_font_x_in_pixels]
;
;	; kontynuuj pozostałe linie
;	jmp	.matrix_continue
;
.ready:
;	; przesuń wirtualny kursor o jedną pozycję w prawo
;	inc	dword [variable_screen_cursor]
;
;	; zwróć wskaźnik do pozycji następnego znaku w przestrzeni pamięci
;	add	r9,	qword [variable_screen_char_width_in_bytes]
;
;	; przywróć ilość kopii znaku do wyświetlenia
;	; wskaźnik do macierzy i wysokość znaku w pikselach
;	pop	r8
;	pop	rsi
;	pop	rcx
;
;	; wyświetl pozostałą ilość
;	loop	.char_N
;
.end:
;	; zwróć aktualny wskaźnik
;	mov	rdi,	r9
;
;	; przywróć oryginalne rejestry
;	pop	rdx
;	pop	r9
;	pop	r8
;	pop	rsi
;	pop	rcx
;	pop	rbx
;	pop	rax
;
;	; powrót z procedury
;	ret

; wejście:
;	r8 - x
;	r9 - y
;	r10 - width
;	r11 - height
x_video_window:
	; oblicz przesunięcie do linii Y
	mov	rax,	qword [variable_x_video_scanline]
	xor	rdx,	rdx
	mul	r9

	; oblicz przesunięcie do kolumny X
	shl	r8,	VARIABLE_MULTIPLE_BY_4

	; ustaw wskaźnik na pozycję
	mov	rdi,	qword [variable_x_video_base_address]
	add	rdi,	rax
	add	rdi,	r8

	; wysokość nagłówka okna
	mov	rax,	VARIABLE_X_COLOR_WINDOW_HEADER
	mov	rcx,	16
	call	x_video_square

	; oddziel nagłówek okna od treści
	mov	rax,	VARIABLE_X_COLOR_WINDOW_HEADER_SPACE
	mov	rcx,	r10
	push	rdi
	rep	stosd
	pop	rdi
	add	rdi,	qword [variable_x_video_scanline]

	; wyświetl zawartość okna
	mov	rax,	VARIABLE_X_COLOR_BACKGROUND_WINDOW
	mov	rcx,	r11
	call	x_video_square

	; powrót z procedury
	ret

; wejście:
;	rax - kolor tła
;	rcx - wysokość okna
;	rdi - wskaźnik lewego górnego rogu okna w przestrzeni pamięci ekranu
;	r10 - szerokość okna
; wyjście:
;	rdi - wskaźnik "lewego dolnego rogu" okna w przestrzeni pamięci ekranu
x_video_square:
	; zachowaj oryginalne rejestry
	push	rcx

.header_y:
	; zachowaj pozostałą wysokość nagłówka okna do wyświetlenia
	push	rcx

	; szerokość okna do wyświetlenia
	mov	rcx,	r10

.header_x:
	; zachowaj adres początku wskaźnika w przestrzeni pamięci ekranu
	push	rdi

	; wyświetl linię nagłówka okna
	rep	stosd

	; przywróć wskaźnik
	pop	rdi

	; przesuń wskaźnik do następnej linii nagłówka
	add	rdi,	qword [variable_x_video_scanline]

	; przywróć numer linii nagłówka
	pop	rcx

	; rysuj kolejną linię nagłówka okna
	dec	rcx
	jnz	.header_y

	; przywróć oryginalne rejestry
	pop	rcx

	; powrót z procedury
	ret

; wejście:
;	rax - 32 bitowy kolor
x_video_clear:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi

	; wyczyść ekran na rządany kolor
	mov	rcx,	qword [variable_x_video_size]
	shr	rcx,	VARIABLE_DIVIDE_BY_4
	mov	rdi,	qword [variable_x_video_base_address]
	rep	stosd

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

; wejście:
;	rbx - kolor 24 bitowy
;	r8 - x
;	r9 - y
x_video_set_pixel:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx
	push	rdi
	push	r8

	; oblicz przesunięcie do linii Y
	mov	rax,	qword [variable_x_video_scanline]
	xor	rdx,	rdx
	mul	r9

	; oblicz przesunięcie do kolumny X
	shl	r8,	VARIABLE_MULTIPLE_BY_4

	; ustaw wskaźnik na pozycję
	mov	rdi,	qword [variable_x_video_base_address]
	add	rdi,	rax
	add	rdi,	r8

	; ustaw kolor
	mov	rax,	rbx

	; wyświetl
	stosq

	; przywróć oryginalne rejestry
	pop	r8
	pop	rdi
	pop	rdx
	pop	rax

	; powrót z procedury
	ret

; wejście:
;	rbx - kolor 24 bitowy
;	r8 - x1
;	r9 - y1
;	r10 - x2
;	r11 - y2
x_video_draw_line:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx
	push	rsi
	push	rdi
	push	r8
	push	r9
	push	r12
	push	r13
	push	r14
	push	r15

	; sprawdź oś x
	; x1 > x2
	cmp	r8,	r10
	ja	.reverse_x

	; kierunek osi x rosnąco
	mov	r12,	1	; xi =	1
	mov	r14,	r10	; dx =	x2
	sub	r14,	r8	; dx -=	x1

	; sprawdź oś y
	jmp	.check_y

.reverse_x:
	; kierunek osi x malejąco
	mov	r12,	-1	; xi =	-1
	mov	r14,	r8	; dx =	x1
	sub	r14,	r10	; dx -=	x2

.check_y:
	; sprawdź oś y
	; y1 > y2
	cmp	r9,	r11
	ja	.reverse_y

	; kierunek osi y rosnąco
	mov	r13,	1	; yi =	1
	mov	r15,	r11	; dy =	y2
	sub	r15,	r9	; dy -=	y1

	; kontynuuj
	jmp	.done

.reverse_y:
	; kierunek osi y malejąco
	mov	r13,	-1	; yi =	-1
	mov	r15,	r9	; dy =	y1
	sub	r15,	r11	; dy -=	y2

.done:
	; względem której osi rysować linię?
	; dy > dx
	cmp	r15,	r14
	ja	.osY

	; rysuj linię względem osi X
	mov	rsi,	r15	; ai =	dy
	sub	rsi,	r14	; ai -=	dx
	shl	rsi,	VARIABLE_MULTIPLE_BY_2
	mov	rdx,	r15	; d =	dy
	shl	rdx,	VARIABLE_MULTIPLE_BY_2
	mov	rdi,	rdx	; bi =	d
	sub	rdx,	r14	; d -=	dx

.loop_x:
	; wyświetl piksel o zdefiniowanym kolorze
	call	x_video_set_pixel

	; jeśli wyświetlony piksel znajduje się w punkcie końca linii, koniec
	; x1 == x2
	cmp	r8,	r10
	je	.end

	; współczynnik ujemny?
	; d
	bt	rdx,	VARIABLE_QWORD_SIGN
	jc	.loop_x_minus

	; oblicz pozycję następnego piksela w linii
	add	r8,	r12	; x +=	xi
	add	r9,	r13	; y +=	yi
	add	rdx,	rsi	; d +=	ai

	; rysuj linię
	jmp	.loop_x

.loop_x_minus:
	; oblicz pozycję następnego piksela w linii
	add	rdx,	rdi	; d +=	bi
	add	r8,	r12	; x +=	xi

	; rysuj linię
	jmp	.loop_x

.osY:
	; rysuj linię względem osi Y
	mov	rsi,	r14	; ai =	dx
	sub	rsi,	r15	; ai -=	dy
	shl	rsi,	VARIABLE_MULTIPLE_BY_2
	mov	rdx,	r14	; d =	dx
	shl	rdx,	VARIABLE_MULTIPLE_BY_2
	mov	rdi,	rdx	; bi =	d
	sub	rdx,	r15	; d -=	dy
	
.loop_y:
	; wyświetl piksel o zdefiniowanym kolorze
	call	x_video_set_pixel

	; jeśli wyświetlony piksel znajduje się w punkcie końca linii, koniec
	; y1 == y2
	cmp	r9,	r11
	je	.end

	; współczynnik ujemny?
	; d
	bt	rdx,	VARIABLE_QWORD_SIGN
	jc	.loop_y_minus

	; oblicz pozycję następnego piksela w linii
	add	r8,	r12	; x +=	xi
	add	r9,	r13	; y +=	yi
	add	rdx,	rsi	; d +=	ai

	; rysuj linię
	jmp	.loop_y

.loop_y_minus:
	; oblicz pozycję następnego piksela w linii
	add	rdx,	rdi	; d +=	bi
	add	r9,	r13	; y +=	yi

	; rysuj linię
	jmp	.loop_y

.end:
	; przywtóć oryginalne rejestry
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r9
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rax

	; powrót z procedury
	ret

variable_x_video_base_address		dq	VARIABLE_EMPTY
variable_x_video_width			dq	VARIABLE_EMPTY
variable_x_video_height			dq	VARIABLE_EMPTY
variable_x_video_size			dq	VARIABLE_EMPTY
variable_x_video_scanline		dq	VARIABLE_EMPTY

; wczytaj lokalizacje programu systemu
%push
	%defstr		%$system_locale		VARIABLE_KERNEL_LOCALE
	%defstr		%$process_name		VARIABLE_PROGRAM_NAME
	%strcat		%$include_program_locale,	"software/", %$process_name, "/locale/", %$system_locale, ".asm"
	%include	%$include_program_locale
%pop

%include	"software/x/font.asm"
