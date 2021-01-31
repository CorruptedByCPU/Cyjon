;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rbx - rozmiar bufora
;	rcx - ilość znaków w buforze
;	rdx - procedura obsługi wyjątku
;	rsi - wskaźnik przestrzeni bufora
;	rdi - wskaźnik przestrzeni IPC
; wyjście:
;	Flaga CF - użytkownik przerwał wprowadzanie (np. klawisz ESC) lub bufor pusty
;	rcx - ilość znaków w ciągu
;	rsi - wskaźnik do bufora
library_input:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rdx
	push	rcx

	; wyświetlić zawartość bufora?
	test	rcx,	rcx
	jz	.entry	; nie

	; wyświetl zawartość bufora
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	int	KERNEL_SERVICE

.entry:
	; wyczyść akumulator
	xor	eax,	eax

	; ilość wolnego miejsca w buforze
	sub	rbx,	rcx

.loop:
	; zwolnij pozostały czas procesora
	mov	ax,	KERNEL_SERVICE_PROCESS_release
	int	KERNEL_SERVICE

	; pobierz komunikat "znak z bufora klawiatury"
	mov	ax,	KERNEL_SERVICE_PROCESS_ipc_receive
	int	KERNEL_SERVICE
	jc	.loop	; brak komunikatu

	; komunikat typu: klawiatura?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_KEYBOARD
	je	.keyboard	; tak

	; obsłuż komunikat
	call	qword [rsp + STATIC_QWORD_SIZE_byte]

	; kontynuuj
	jmp	.loop

.keyboard:
	; pobierz kod klawisza
	mov	dx,	word [rdi + KERNEL_IPC_STRUCTURE.data]

	; klawisz typu Backspace?
	cmp	dx,	STATIC_SCANCODE_BACKSPACE
	je	.key_backspace

	; klawisz typu Enter?
	cmp	dx,	STATIC_SCANCODE_RETURN
	je	.key_enter

	; klawisz typu ESC?
	cmp	dx,	STATIC_SCANCODE_ESCAPE
	je	.empty	; zakończ libliotekę

	; znak dozwolony?

	; sprawdź czy pobrany znak jest możliwy do wyświetlenia
	cmp	dx,	STATIC_SCANCODE_SPACE
	jb	.loop	; nie, zignoruj
	cmp	dx,	STATIC_SCANCODE_TILDE
	ja	.loop	; nie, zignoruj

	; bufor pełny?
	test	rbx,	rbx
	jz	.loop	; tak

	; zachowaj znak w buforze
	mov	byte [rsi + rcx],	dl

	; pozostałe miejsce w buforze
	dec	rbx

	; ilość znaków w buforze
	inc	rcx

.print:
	; zachowaj ilość znaków w buforze
	push	rcx

	; wyświetl znak na terminal
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
	mov	ecx,	0x01	; jeden raz
	int	KERNEL_SERVICE

	; przywróć ilość znakóœ w buforze
	pop	rcx

	; kontynuuj
	jmp	.loop

.key_backspace:
	; bufor pusty?
	test	rcx,	rcx
	jz	.loop	; tak

	; ilość znaków w buforze
	dec	rcx

	; rozmiar dostępnego bufora
	inc	rbx

	; wyświetl klawisz backspace
	jmp	.print

.key_enter:
	; bufor pusty?
	test	rcx,	rcx
	jz	.empty	; tak

	; zwróć ilość znaków w buforze
	mov	qword [rsp],	rcx

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
	pop	rdx
	pop	rbx
	pop	rax

	; powrót z biblioteki
	ret

	macro_debug	"library_input"
