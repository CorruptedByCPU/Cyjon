;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

kernel_video_semaphore				db	STATIC_FALSE
kernel_video_base_address			dq	STATIC_EMPTY
kernel_video_pointer				dq	STATIC_EMPTY
kernel_video_framebuffer			dq	STATIC_EMPTY
kernel_video_size_byte				dq	STATIC_EMPTY
kernel_video_size_pixel				dq	STATIC_EMPTY
kernel_video_width_pixel			dq	STATIC_EMPTY
kernel_video_height_pixel			dq	STATIC_EMPTY
kernel_video_width_char				dq	STATIC_EMPTY
kernel_video_height_char			dq	STATIC_EMPTY
kernel_video_scanline_byte			dq	STATIC_EMPTY
kernel_video_scanline_char			dq	STATIC_EMPTY

kernel_video_color				dd	STATIC_COLOR_default
kernel_video_color_background			dd	STATIC_COLOR_BACKGROUND_default

; domyślnie kursor jest wyłączony
kernel_video_cursor_lock			dq	STATIC_EMPTY
kernel_video_cursor:
					.x:	dd	STATIC_EMPTY
					.y:	dd	STATIC_EMPTY

kernel_video_color_sequence_default		db	STATIC_COLOR_ASCII_DEFAULT
kernel_video_color_sequence_black		db	STATIC_COLOR_ASCII_BLACK
kernel_video_color_sequence_blue		db	STATIC_COLOR_ASCII_BLUE
kernel_video_color_sequence_green		db	STATIC_COLOR_ASCII_GREEN
kernel_video_color_sequence_cyan		db	STATIC_COLOR_ASCII_CYAN
kernel_video_color_sequence_red			db	STATIC_COLOR_ASCII_RED
kernel_video_color_sequence_magenta		db	STATIC_COLOR_ASCII_MAGENTA
kernel_video_color_sequence_brown		db	STATIC_COLOR_ASCII_BROWN
kernel_video_color_sequence_gray_light		db	STATIC_COLOR_ASCII_GRAY_LIGHT
kernel_video_color_sequence_gray		db	STATIC_COLOR_ASCII_GRAY
kernel_video_color_sequence_blue_light		db	STATIC_COLOR_ASCII_BLUE_LIGHT
kernel_video_color_sequence_green_light		db	STATIC_COLOR_ASCII_GREEN_LIGHT
kernel_video_color_sequence_cyan_light		db	STATIC_COLOR_ASCII_CYAN_LIGHT
kernel_video_color_sequence_red_light		db	STATIC_COLOR_ASCII_RED_LIGHT
kernel_video_color_sequence_magenta_light	db	STATIC_COLOR_ASCII_MAGENTA_LIGHT
kernel_video_color_sequence_yellow		db	STATIC_COLOR_ASCII_YELLOW
kernel_video_color_sequence_white		db	STATIC_COLOR_ASCII_WHITE

;===============================================================================
kernel_video_drain:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi

	; wyłącz wirtualny kursor
	call	kernel_video_cursor_disable

	; wyczyść przestrzeń pamięci trybu tekstowego "jasno-szarymi znakami spacji"
	mov	eax,	dword [kernel_video_color_background]
	mov	rcx,	qword [kernel_video_size_pixel]
	mov	rdi,	qword [kernel_video_framebuffer]
	rep	stosd

	; ustaw wirtualny kursor na na początek przestrzeni ekranu
	mov	qword [kernel_video_cursor],	STATIC_EMPTY

	; ustaw sprzętowy kursor na miejsce
	call	kernel_video_cursor_set

	; włącz wirtualny kursor
	call	kernel_video_cursor_enable

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_video_drain"

;===============================================================================
; wejście:
;	rax - kod ASCII znaku
;	rdi - pozycja znaku w przestrzeni pamięci ekranu
kernel_video_matrix:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r8

	; oblicz prdesunięcie względem początku matrycy czcionki dla znaku
	mov	ebx,	dword [kernel_font_height_pixel]
	mul	rbx

	; ustaw wskaźnik na matrycę znaku
	mov	rsi,	kernel_font_matrix
	add	rsi,	rax

	; pobierz kolor czcionki
	mov	r8d,	dword [kernel_video_color]

.next:
	; szerokość matrycy znaku liczona od zera
	mov	ecx,	KERNEL_FONT_WIDTH_pixel - 0x01

.loop:
	; włączyć piksel matrycy znaku na ekranie?
	bt	word [rsi],	cx
	jnc	.continue	; nie

	; wyświetl piksel o zdefiniowanym kolorze znaku
	mov	dword [rdi],	r8d

	; wyświetl cień za pikselem
	mov	dword [rdi + STATIC_DWORD_SIZE_byte],	STATIC_EMPTY

.continue:
	; następny piksel matrycy znaku
	add	rdi,	STATIC_DWORD_SIZE_byte

	; wyświetlić pozostałe?
	dec	cl
	jns	.loop	; tak

	; przesuń wskaźnik na następną linię matrycy na ekranie
	sub	rdi,	KERNEL_FONT_WIDTH_pixel << KERNEL_VIDEO_DEPTH_shift	; cofnij o szerokość wyświetlonego znaku w Bajtach
	add	rdi,	qword [kernel_video_scanline_byte]	; przesuń do przodu o rozmiar scanline ekranu

	; przesuń wskaźnik na następną linię matrycy znaku
	inc	rsi

	; przetworzono całą matrycę znaku?
	dec	bl
	jnz	.next	; nie, kontynuuj z następną linią matrycy znaku

	; przywróć oryginalne rejestry
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_video_matrix"

;===============================================================================
; wejście:
;	rdi - wskaźnik pozycji znaku
kernel_video_char_clean:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rdi

	; wysokość matrycy znaku w pikselach
	mov	ebx,	KERNEL_FONT_HEIGHT_pixel

	; kolor tła
	mov	eax,	dword [kernel_video_color_background]

.next:
	; szerokość matrycy znaku liczona od zera
	mov	cx,	KERNEL_FONT_WIDTH_pixel - 0x01

.loop:
	; wyświetl piksel o zdefiniowanym kolorze tła
	stosd

.continue:
	; następny piksel z linii matrycy znaku
	dec	cl
	jns	.loop

	; przesuń wskaźnik na następną linię matrycy na ekranie
	sub	rdi,	KERNEL_FONT_WIDTH_pixel << KERNEL_VIDEO_DEPTH_shift	; cofnij o szerokość znaku w Bajtach
	add	rdi,	qword [kernel_video_scanline_byte]	; przesuń do przodu o rozmiar scanline ekranu

	; przetworzono całą matrycę znaku?
	dec	bl
	jnz	.next	; nie, następna linia matrycy znaku

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_video_char_clean"

;===============================================================================
kernel_video_cursor_set:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx

	; wyłącz kursor
	call	kernel_video_cursor_disable

	; oblicz pozycję kursora w znakach
	mov	eax,	dword [kernel_video_cursor.y]
	mul	qword [kernel_video_scanline_char]
	push	rax	; zapamiętaj
	mov	eax,	dword [kernel_video_cursor.x]
	mul	qword [kernel_font_width_byte]
	add	qword [rsp],	rax
	pop	rax	; zwróć wynik

	; zapisz nową pozycję wskaźnika w przestrzeni pamięci karty graficznej
	add	rax,	qword [kernel_video_framebuffer]
	mov	qword [kernel_video_pointer],	rax

	; włącz kursor
	call	kernel_video_cursor_enable

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_video_cursor_set"

;===============================================================================
; wejście:
;	rcx - ilość znaków w ciągu
;	rsi - wskaźnik do ciągu
kernel_video_string:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi

	; wyłącz kursor
	call	kernel_video_cursor_disable

	; wyświetlić jakąkolwiek ilość znaków z ciągu?
	test	rcx,	rcx
	jz	.end	; nie

	; wyczyść zmienną
	xor	eax,	eax

.loop:
	; pobierz kod ASCII z ciągu
	lodsb

	; wymuszony koniec ciągu?
	test	al,	al
	jz	.end	; tak

	; rozpoczęto sekwencję?
	cmp	al,	STATIC_ASCII_BACKSLASH
	jne	.no	; tak

	; rozmiar ciągu może zawierać sekwencję?
	cmp	rcx,	STATIC_ASCII_SEQUENCE_length
	jb	.fail	; nie

	; zachowaj oryginalne rejestry
	push	rdi
	push	rsi
	push	rcx

	; cofnij wskaźnik na początek sekwencji
	dec	rsi

	; rozmiar poszukiwanej sekwencji
	mov	ecx,	STATIC_ASCII_SEQUENCE_length

.default:
	; zmiana kolorystyki na domyślny?
	mov	rdi,	kernel_video_color_sequence_default
	call	library_string_compare
	jc	.black	; nie

	; ustaw kolorystykę na domyślny
	mov	dword [kernel_video_color],	STATIC_COLOR_default

	; koniec obsługi sekwencji
	jmp	.done

.black:
	; zmiana kolorystyki na czarny?
	mov	rdi,	kernel_video_color_sequence_black
	call	library_string_compare
	jc	.blue	; nie

	; ustaw kolorystykę na czarny
	mov	dword [kernel_video_color],	STATIC_COLOR_black

	; koniec obsługi sekwencji
	jmp	.done

.blue:
	; zmiana kolorystyki na niebieski?
	mov	rdi,	kernel_video_color_sequence_blue
	call	library_string_compare
	jc	.green	; nie

	; ustaw kolorystykę na niebieski
	mov	dword [kernel_video_color],	STATIC_COLOR_blue

	; koniec obsługi sekwencji
	jmp	.done

.green:
	; zmiana kolorystyki na zielony?
	mov	rdi,	kernel_video_color_sequence_green
	call	library_string_compare
	jc	.cyan	; nie

	; ustaw kolorystykę na zielony
	mov	dword [kernel_video_color],	STATIC_COLOR_green

	; koniec obsługi sekwencji
	jmp	.done

.cyan:
	; zmiana kolorystyki na cyan?
	mov	rdi,	kernel_video_color_sequence_cyan
	call	library_string_compare
	jc	.red	; nie

	; ustaw kolorystykę na cyan
	mov	dword [kernel_video_color],	STATIC_COLOR_cyan

	; koniec obsługi sekwencji
	jmp	.done

.red:
	; zmiana kolorystyki na czerwony?
	mov	rdi,	kernel_video_color_sequence_red
	call	library_string_compare
	jc	.magenta	; nie

	; ustaw kolorystykę na czerwony
	mov	dword [kernel_video_color],	STATIC_COLOR_red

	; koniec obsługi sekwencji
	jmp	.done

.magenta:
	; zmiana kolorystyki na magenta?
	mov	rdi,	kernel_video_color_sequence_magenta
	call	library_string_compare
	jc	.brown	; nie

	; ustaw kolorystykę na magenta
	mov	dword [kernel_video_color],	STATIC_COLOR_magenta

	; koniec obsługi sekwencji
	jmp	.done

.brown:
	; zmiana kolorystyki na brązowy?
	mov	rdi,	kernel_video_color_sequence_brown
	call	library_string_compare
	jc	.gray_light	; nie

	; ustaw kolorystykę na brązowy
	mov	dword [kernel_video_color],	STATIC_COLOR_brown

	; koniec obsługi sekwencji
	jmp	.done

.gray_light:
	; zmiana kolorystyki na jasno-szary?
	mov	rdi,	kernel_video_color_sequence_gray_light
	call	library_string_compare
	jc	.gray	; nie

	; ustaw kolorystykę na jasno-zielony
	mov	dword [kernel_video_color],	STATIC_COLOR_gray_light

	; koniec obsługi sekwencji
	jmp	.done

.gray:
	; zmiana kolorystyki na szary?
	mov	rdi,	kernel_video_color_sequence_gray
	call	library_string_compare
	jc	.blue_light	; nie

	; ustaw kolorystykę na szary
	mov	dword [kernel_video_color],	STATIC_COLOR_gray

	; koniec obsługi sekwencji
	jmp	.done

.blue_light:
	; zmiana kolorystyki na jasno-niebieski?
	mov	rdi,	kernel_video_color_sequence_blue_light
	call	library_string_compare
	jc	.green_light	; nie

	; ustaw kolorystykę na jasno-nieblieski
	mov	dword [kernel_video_color],	STATIC_COLOR_blue_light

	; koniec obsługi sekwencji
	jmp	.done

.green_light:
	; zmiana kolorystyki na jasno-zielony?
	mov	rdi,	kernel_video_color_sequence_green_light
	call	library_string_compare
	jc	.cyan_light	; nie

	; ustaw kolorystykę na jasno-zielony
	mov	dword [kernel_video_color],	STATIC_COLOR_green_light

	; koniec obsługi sekwencji
	jmp	.done

.cyan_light:
	; zmiana kolorystyki na jasny cyan?
	mov	rdi,	kernel_video_color_sequence_cyan_light
	call	library_string_compare
	jc	.red_light	; nie

	; ustaw kolorystykę na jasny cyan
	mov	dword [kernel_video_color],	STATIC_COLOR_cyan_light

	; koniec obsługi sekwencji
	jmp	.done

.red_light:
	; zmiana kolorystyki na jasno-czerwony?
	mov	rdi,	kernel_video_color_sequence_red_light
	call	library_string_compare
	jc	.magenta_light	; nie

	; ustaw kolorystykę na jasno-zielony
	mov	dword [kernel_video_color],	STATIC_COLOR_red_light

	; koniec obsługi sekwencji
	jmp	.done

.magenta_light:
	; zmiana kolorystyki na jasna magenta?
	mov	rdi,	kernel_video_color_sequence_magenta_light
	call	library_string_compare
	jc	.yellow	; nie

	; ustaw kolorystykę na jasna magenta
	mov	dword [kernel_video_color],	STATIC_COLOR_magenta_light

	; koniec obsługi sekwencji
	jmp	.done

.yellow:
	; zmiana kolorystyki na żółty?
	mov	rdi,	kernel_video_color_sequence_yellow
	call	library_string_compare
	jc	.white	; nie

	; ustaw kolorystykę na żółty
	mov	dword [kernel_video_color],	STATIC_COLOR_yellow

	; koniec obsługi sekwencji
	jmp	.done

.white:
	; zmiana kolorystyki na jasno-szary?
	mov	rdi,	kernel_video_color_sequence_white
	call	library_string_compare
	jc	.fail	; nie

	; ustaw kolorystykę na jasno-zielony
	mov	dword [kernel_video_color],	STATIC_COLOR_white

.done:
	; zmniejsz rozmiar ciągu i przesuń wskaźnik za sekwencję
	sub	qword [rsp],	STATIC_ASCII_SEQUENCE_length - 0x01
	add	qword [rsp + STATIC_QWORD_SIZE_byte],	STATIC_ASCII_SEQUENCE_length - 0x01

.fail:
	; przywróć oryginalne rejestry
	pop	rcx
	pop	rsi
	pop	rdi

	; kontynuuj
	jnc	.continue

.no:
	; zachowaj pozostały rozmiar ciągu
	push	rcx

	; wyświetl 1 kopię kodu ASCII
	mov	ecx,	1
	call	kernel_video_char

	; przywróć pozostały rozmiar ciągu
	pop	rcx

.continue:
	; wyświetl pozostałą część ciągu
	dec	rcx
	jnz	.loop

.end:
	; włącz kursor
	call	kernel_video_cursor_enable

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_video_string"

;===============================================================================
; wejście:
;	rax - kod ASCII znaku
;	rcx - ilość kopii znaku do wyświetlenia
kernel_video_char:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rdi

	; wyłącz kursor
	call	kernel_video_cursor_disable

	; zablokuj dostęp do przestrzeni karty graficznej
	macro_lock	kernel_video_semaphore,	0

	; pozycja kursora na osi X,Y
	mov	ebx,	dword [kernel_video_cursor]
	mov	edx,	dword [kernel_video_cursor + STATIC_DWORD_SIZE_byte]

	; ustaw wskaźnik na ostatnią pozycję w przestrzeni pamięci trybu tekstowego
	mov	rdi,	qword [kernel_video_pointer]

.loop:
	; znak "nowej linii"?
	cmp	ax,	STATIC_ASCII_NEW_LINE
	je	.new_line

	; znak "backspace"?
	cmp	ax,	STATIC_ASCII_BACKSPACE
	je	.backspace

	; wyczyść przestrzeń znaku domyślnym kolorem tła
	call	kernel_video_char_clean

	; wyświetl matrycę znaku na ekran
	sub	ax,	STATIC_ASCII_SPACE	; macierz czcionki rozpoczyna się od znaku STATIC_ASCII_SPACE
	call	kernel_video_matrix

	; przesuń kursor na osi X o jedną pozycję w prawo
	inc	ebx

	; przesuń wskaźnik na następną pozycję w przestrzeni pamięci karty graficznej
	add	rdi,	qword [kernel_font_width_byte]

	; pozycja kursora poza przestrzenią pamięci trybu tekstowego?
	cmp	ebx,	dword [kernel_video_width_char]
	jb	.continue	; nie

	; zachowaj oryginalne rejestr
	push	rax
	push	rdx

	; przesuń wskaźnik kursora na początek nowej linii
	mov	rax,	qword [kernel_font_width_byte]
	mul	rbx
	sub	rdi,	rax
	add	rdi,	qword [kernel_video_scanline_char]

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rax

	; przesuń kursor do następnego wiersza
	xor	ebx,	ebx
	inc	edx

.row:
	; pozycja kursora poza przestrzenią pamięci trybu tekstowego?
	cmp	edx,	dword [kernel_video_height_char]
	jb	.continue	; nie

	; koryguj pozycję kursora na osi Y
	dec	edx

	; koryguj wskaźnik
	sub	rdi,	qword [kernel_video_scanline_char]

	; przewiń zawartość przestrzeni pamięci trybu tekstowego o jedną linię tekstu w górę
	call	kernel_video_scroll

.continue:
	; wyświetlono wszystkie kopie?
	dec	rcx
	jnz	.loop	; nie

	; zachowaj aktualną pozycję kursora w przestrzeni pamięci trybu tekstowego
	mov	dword [kernel_video_cursor],	ebx
	mov	dword [kernel_video_cursor + STATIC_DWORD_SIZE_byte],	edx

	; zachowaj aktualną pozycję wskaźnika w przestrzeni pamięci trybu tekstowego
	mov	qword [kernel_video_pointer],	rdi

	; zwolnij dostęp do procedury znaku
	mov	byte [kernel_video_semaphore],	STATIC_FALSE

	; włącz kursor
	call	kernel_video_cursor_enable

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;-------------------------------------------------------------------------------
.new_line:
	; zachowaj oryginalne rejestry
	push	rax	; kod ASCII znaku
	push	rdx	; pozycja kursor na osi Y

	; cofnij wskaźnik na początek linii
	mov	eax,	ebx
	mul	qword [kernel_font_width_pixel]
	shl	rax,	KERNEL_VIDEO_DEPTH_shift
	sub	rdi,	rax

	; cofnij wirtualny kursor na początek linii
	xor	ebx,	ebx

	; przesuń kursor i wskaźnik do następnej linii
	add	rdi,	qword [kernel_video_scanline_char]

	; przywróć pozycję kursora na osi Y
	pop	rdx
	inc	rdx	; przesuń kursor do następnej linii

	; przywróć kod ASCII znaku
	pop	rax

	; kontynuuj
	jmp	.row

;-------------------------------------------------------------------------------
.backspace:
	; kursor znajduje się na początku linii?
	test	ebx,	ebx
	jz	.begin	; tak

	; cofnij pozycję kursora na osi X
	dec	ebx

	; kontynuuj
	jmp	.clear

.begin:
	; kursor znajduje się w pierwszej linii?
	test	edx,	edx
	jz	.continue	; tak

	; ustaw pozycję kursora na koniec aktualnej linii
	mov	ebx,	dword [kernel_video_width_char]
	dec	ebx

	; cofnij pozycję kursora o jedną linię
	dec	edx

	; zachowaj oryginalny rejestr
	push	rax
	push	rdx

	; przesuń wskaźnik kursora na początek poprzedniej linii
	sub	rdi,	qword [kernel_video_scanline_char]
	mov	rax,	qword [kernel_font_width_byte]
	mul	dword [kernel_video_width_char]
	add	rdi,	rax

	; przywróć oryginalny rejestr
	pop	rdx
	pop	rax

.clear:
	; przesuń wskaźnik o jeden znak wstecz
	sub	rdi,	KERNEL_FONT_WIDTH_pixel << KERNEL_VIDEO_DEPTH_shift

	; wyczyść przestrzeń znaku domyślnym kolorem tła
	call	kernel_video_char_clean

	; kontynuuj
	jmp	.continue

	macro_debug	"kernel_video_char"

;===============================================================================
; wejście:
;	rax - wartość do wyświetlenia
;	rbx - system liczbowy
;	rcx - rozmiar wypełnienia przed liczbą
;	rdx  - kod ASCII wypełnienia
kernel_video_number:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx
	push	rbp
	push	r8
	push	r9

	; wyłącz kursor
	call	kernel_video_cursor_disable

	; wyczyść zbędne dane w rejestrze RBX
	and	ebx,	STATIC_BYTE_mask

	; podstawa liczby w odpowiednim zakresie?
	cmp	bl,	2
	jb	.error	; nie
	cmp	bl,	36
	ja	.error	; nie

	; zachowaj wartość prefiksa
	mov	r8,	rdx
	sub	r8,	0x30

	; wyczyść starszą część / resztę z dzielenia
	xor	rdx,	rdx

	; utwórz stos zmiennych lokalnych
	mov	rbp,	rsp

.loop:
	; oblicz resztę z dzielenia
	div	rbx

	; zapisz resztę z dzielenia do zmiennych lokalnych
	push	rdx
	dec	rcx	; zmniejsz rozmiar prefiksu

	; wyczyść resztę z dzielenia
	xor	rdx,	rdx

	; przeliczać dalej?
	test	rax,	rax
	jnz	.loop	; tak

	; uzupełnić prefiks?
	cmp	rcx,	STATIC_EMPTY
	jle	.print	; nie

.prefix:
	; uzupełnij wartość o prefiks
	push	r8

	; uzupełniać dalej?
	dec	rcx
	jnz	.prefix	; tak

.print:
	; wyświetl każdą cyfrę
	mov	ecx,	0x01	; 1 raz

	; pozostały cyfry do wyświetlenia?
	cmp	rsp,	rbp
	je	.end	; nie

	; pobierz cyfrę
	pop	rax

	; przemianuj cyfrę na kod ASCII
	add	rax,	0x30

	; system liczbowy powyżej podstawy 10?
	cmp	al,	0x3A
	jb	.no	; nie

	; koryguj kod ASCII do podstawy liczbowej
	add	al,	0x07

.no:
	; wyświetl cyfrę
	call	kernel_video_char

	; kontynuuj
	jmp	.print

.error:
	; flaga, błąd
	stc

.end:
	; włącz kursor
	call	kernel_video_cursor_enable

	; przywróć oryginalne rejestry
	pop	r9
	pop	r8
	pop	rbp
	pop	rdx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_video_number"

;===============================================================================
kernel_video_scroll:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi
	push	rdi

	; wyłącz wirtualny kursor
	call	kernel_video_cursor_disable

	; rozmiar przemieszczanej przestrzeni
	mov	rcx,	qword [kernel_video_size_byte]
	sub	rcx,	qword [kernel_video_scanline_char]

	; rozpocznij przewijanie z linii 1 do 0
	mov	rdi,	qword [kernel_video_framebuffer]
	mov	rsi,	rdi
	add	rsi,	qword [kernel_video_scanline_char]
	call	kernel_memory_copy

	; wyczyść ostatnią linię znaków na ekranie
	mov	ecx,	dword [kernel_video_height_char]
	dec	ecx
	call	kernel_video_line_drain

	; włącz wirtualny kursor
	call	kernel_video_cursor_enable

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx

	; powrót z procedury
	ret

	macro_debug	"kernel_video_scroll"

;===============================================================================
; wejście:
;	rcx - numer linii na ekranie
kernel_video_line_drain:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rdi

	; wyłącz kursor
	call	kernel_video_cursor_disable

	; załaduj numer linii do akumulatora
	mov	rax,	rcx

	; ustaw wskaźnik na początek danej linii ekranu0
	mov	rcx,	qword [kernel_video_scanline_char]
	mul	rcx
	add	rax,	qword [kernel_video_framebuffer]
	mov	rdi,	rax

	; wyczyść linię domyślnym kolorem tła
	mov	eax,	STATIC_COLOR_BACKGROUND_default
	shr	rcx,	KERNEL_VIDEO_DEPTH_shift
	rep	stosd

	; włącz kursor
	call	kernel_video_cursor_enable

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_video_line_drain"

;===============================================================================
kernel_video_cursor_disable:
	; nałóż blokadę na kursor
	inc	qword [kernel_video_cursor_lock]

	; blokada nałożona?
	cmp	qword [kernel_video_cursor_lock],	STATIC_FALSE
	jne	.ready	; blokada nałożona już wcześniej, zwiększono poziom

	; przełącz widoczność kursora
	call	kernel_video_cursor_switch

.ready:
	; przywróć oryginalne rejestry
	ret

	macro_debug	"kernel_video_cursor_disable"

;===============================================================================
kernel_video_cursor_enable:
	; blokada nałożona?
	cmp	qword [kernel_video_cursor_lock],	STATIC_EMPTY
	je	.ready	; nie, zignoruj

	; zwolnij blokadę na kursor
	dec	qword [kernel_video_cursor_lock]

	; blokada dalej nałożona?
	cmp	qword [kernel_video_cursor_lock],	STATIC_EMPTY
	jne	.ready	; tak, zignoruj

	; przełącz widoczność kursora
	call	kernel_video_cursor_switch

.ready:
	; przywróć oryginalne rejestry
	ret

	macro_debug	"kernel_video_cursor_enable"

;===============================================================================
kernel_video_cursor_switch:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi

	; scanline ekranu
	mov	rax,	qword [kernel_video_scanline_byte]

	; wysokość kursora
	mov	rcx,	KERNEL_FONT_HEIGHT_pixel

	; pozycja kursora
	mov	rdi,	qword [kernel_video_pointer]

.loop:
	; odróć kolor piksela
	not	dword [rdi]

	; piksel w pełni widoczny
	or	byte [rdi + 0x03],	STATIC_MAX_unsigned

	; przesuń wskaźnik na następny piksel
	add	rdi,	rax

	; nastepny piksel?
	dec	rcx
	jnz	.loop

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_video_cursor_switch"
