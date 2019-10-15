;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

KERNEL_VIDEO_BASE_address		equ	0x000B8000
KERNEL_VIDEO_BASE_limit			equ	KERNEL_VIDEO_BASE_address + KERNEL_VIDEO_SIZE_byte
KERNEL_VIDEO_WIDTH_char			equ	80
KERNEL_VIDEO_HEIGHT_char		equ	25
KERNEL_VIDEO_CHAR_SIZE_byte		equ	0x02
KERNEL_VIDEO_LINE_SIZE_byte		equ	KERNEL_VIDEO_WIDTH_char * KERNEL_VIDEO_CHAR_SIZE_byte
KERNEL_VIDEO_SIZE_byte			equ	KERNEL_VIDEO_LINE_SIZE_byte * KERNEL_VIDEO_HEIGHT_char

; kernel_video_base_address		dq	KERNEL_VIDEO_BASE_address
kernel_video_width			dq	KERNEL_VIDEO_WIDTH_char
kernel_video_height			dq	KERNEL_VIDEO_HEIGHT_char
kernel_video_char_size_byte		dq	KERNEL_VIDEO_CHAR_SIZE_byte
kernel_video_line_size_byte		dq	KERNEL_VIDEO_LINE_SIZE_byte
kernel_video_size_byte			dq	KERNEL_VIDEO_LINE_SIZE_byte * KERNEL_VIDEO_HEIGHT_char

kernel_video_pointer			dq	KERNEL_VIDEO_BASE_address
kernel_video_cursor			dd	STATIC_EMPTY	; x
					dd	STATIC_EMPTY	; y

kernel_video_char_color_and_background	db	0x07

;===============================================================================
kernel_video_dump:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi

	; wyczyść przestrzeń pamięci trybu tekstowego "jasno-szarymi znakami spacji"
	mov	rax,	0x0720072007200720
	mov	ecx,	(KERNEL_VIDEO_LINE_SIZE_byte * KERNEL_VIDEO_WIDTH_char)
	mov	rdi,	KERNEL_VIDEO_BASE_address
	rep	stosq

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
kernel_video_cursor_set:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx

	; oblicz pozycję kursora w znakach
	mov	eax,	KERNEL_VIDEO_WIDTH_char
	mul	dword [kernel_video_cursor + STATIC_DWORD_SIZE_byte]	; pozycja na osi Y
	add	eax,	dword [kernel_video_cursor]	; pozycja na osi X

	; zapamiętaj
	mov	cx,	ax

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

	; powrót z procedury
	ret

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

	; wyświetlić jakąkolwiek ilość znaków z ciągu?
	test	rcx,	rcx
	jz	.end	; nie

	; pobierz kolor i tło znaków
	mov	ah,	byte [kernel_video_char_color_and_background]

.loop:
	; pobierz kod ASCII z ciągu
	lodsb

	; wymuszony koniec ciągu?
	test	al,	al
	jz	.end	; tak

	; zachowaj pozostały rozmiar ciągu
	push	rcx

	; wyświetl 1 kopię kodu ASCII
	mov	ecx,	1
	call	kernel_video_char

	; przywróć pozostały rozmiar ciągu
	pop	rcx

	; wyświetl pozostałą część ciągu
	dec	rcx
	jnz	.loop

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	al - kod ASCII znaku
;	rcx - ilość kopii do wyświetlenia
kernel_video_char:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rdi

	; pobierz kolor znaku/tła
	mov	ah,	byte [kernel_video_char_color_and_background]

	; pozycja kursora na osi X,Y
	mov	ebx,	dword [kernel_video_cursor]
	mov	edx,	dword [kernel_video_cursor + STATIC_DWORD_SIZE_byte]

	; ustaw wskaźnik na ostatnią pozycję w przestrzeni pamięci trybu tekstowego
	mov	rdi,	qword [kernel_video_pointer]

.loop:
	; znak "nowej linii"?
	cmp	al,	STATIC_ASCII_NEW_LINE
	je	.new_line

	; znak "backspace"?
	cmp	al,	STATIC_ASCII_BACKSPACE
	je	.backspace

	; zapisz znak do przestrzeni pamięci trybu tekstowego
	stosw

	; przesuń kursor na osi X o jedną pozycję w prawo
	inc	ebx

	; pozycja kursora poza przestrzenią pamięci trybu tekstowego?
	cmp	ebx,	KERNEL_VIDEO_WIDTH_char
	jb	.continue	; nie

	; przesuń kursor na początek nowej linii
	sub	ebx,	KERNEL_VIDEO_WIDTH_char
	inc	edx

	; pozycja kursora poza przestrzenią pamięci trybu tekstowego?
	cmp	edx,	KERNEL_VIDEO_HEIGHT_char
	jb	.continue	; nie

	; koryguj pozycję kursora na osi Y
	dec	edx

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

	; koryguj pozycję kursora
	call	kernel_video_cursor_set

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
	; kod ASCII znaku
	push	rax

	; koryguj pozycję kursora i wskaźnika o ilość znaków do początku linii
	mov	eax,	ebx
	shl	eax,	STATIC_MULTIPLE_BY_2_shift
	sub	rdi,	rax
	xor	ebx,	ebx

	; przesuń kursor i wskaźnik do następnej linii
	inc	edx
	add	rdi,	KERNEL_VIDEO_LINE_SIZE_byte

	; przywróć oryginalne rejestry
	pop	rax

	; kontynuuj
	jmp	.continue

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
	jz	.clear

	; cofnij pozycję kursora o jedną linię
	dec	edx

	; ustaw pozycję kursora na koniec aktualnej linii
	mov	ebx,	KERNEL_VIDEO_WIDTH_char - 0x01

.clear:
	; przesuń wskaźnik o jeden znak wstecz
	sub	rdi,	KERNEL_VIDEO_CHAR_SIZE_byte

	; wyczyść pozycję w przestrzeni pamięci "jasnoszarą spacją"
	mov	word [rdi],	0x0720

	; kontynuuj
	jmp	.continue

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
	; przywróć oryginalne rejestry
	pop	r9
	pop	r8
	pop	rbp
	pop	rdx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
kernel_video_scroll:
	jmp	$
