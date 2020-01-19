;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
; wejście:
;	rbx - ilość znaków w buforze
;	rcx - maksymalna ilość znaków w buforze
;	rsi - wskaźnik do początku bufora
; wyjście:
;	Falga CF - użytkownik przerwał wprowadzanie (np. klawisz ESC) lub bufor pusty
;	rcx - ilość znaków w buforze
library_input:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rsi
	push	rcx

	; wyświetlić zawartość bufora?
	cmp	rbx,	STATIC_EMPTY
	je	.loop	; nie

	; wyświetl zawartość bufora
	mov	ax,	KERNEL_SERVICE_VIDEO_string
	mov	rcx,	rbx
	int	KERNEL_SERVICE

	; przywróć maksymalny rozmiar bufora
	mov	rcx,	qword [rsp]

	; zmiejsz rozmiar o zawartość
	sub	rcx,	rbx

	; przesuń wskaźnik bufora na koniec
	add	rsi,	rbx

.loop:
	; pobierz znak z bufora klawiatury
	mov	ax,	KERNEL_SERVICE_KEYBOARD_key
	int	KERNEL_SERVICE
	jz	.loop

	; klawisz typu Backspace?
	cmp	ax,	STATIC_ASCII_BACKSPACE
	je	.key_backspace

	; klawisz typu Enter?
	cmp	ax,	STATIC_ASCII_ENTER
	je	.key_enter

	; klawisz typu ESC?
	cmp	ax,	STATIC_ASCII_ESCAPE
	je	.empty	; zakończ libliotekę

	; znak dozwolony?

	; sprawdź czy pobrany znak jest możliwy do wyświetlenia
	cmp	ax,	STATIC_ASCII_SPACE
	jb	.loop	; nie, zignoruj
	cmp	ax,	STATIC_ASCII_TILDE
	ja	.loop	; nie, zignoruj

	; bufor pełny?
	cmp	rcx,	STATIC_EMPTY
	je	.loop	; tak

	; zachowaj znak w buforze
	mov	byte [rsi + rbx],	al

	; ilość znaków w buforze
	inc	rbx

	; pozostałe miejsce w buforze
	dec	rcx

.print:
	; zachowaj rozmiar bufora
	push	rcx

	; wyświetl znak z bufora na ekran
	mov	edx,	KERNEL_SERVICE_VIDEO_char
	xchg	dx,	ax
	mov	ecx,	1	; jedna kopia
	int	KERNEL_SERVICE

	; przywróć rozmiar bufora
	pop	rcx

	; kontynuuj
	jmp	.loop

.key_backspace:
	; bufor pusty?
	test	rbx,	rbx
	jz	.loop	; tak

	; ilość znaków w buforze
	dec	rbx

	; rozmiar dostępnego bufora
	inc	rcx

	; wyświetl klawisz backspace
	jmp	.print

.key_enter:
	; bufor pusty?
	test	rbx,	rbx
	jz	.empty	; tak

	; zwróć ilość znaków w buforze
	mov	qword [rsp],	rbx

	; flaga, sukces
	clc

	; koniec liblioteki
	jmp	.end

.empty:
	; flaga, błąd
	stc

.end:
	; przywróć oryginalne rejestry
	pop	rcx
	pop	rsi
	pop	rbx
	pop	rax

	; powrót z liblioteki
	ret

	; macro_debug	"library_input"
