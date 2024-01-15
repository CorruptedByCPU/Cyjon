;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

variable_keyboard_semaphore					db	VARIABLE_FALSE
variable_keyboard_semaphore_capslock				db	VARIABLE_FALSE
variable_keyboard_semaphore_shift				db	VARIABLE_FALSE

variable_keyboard_key_special					db	VARIABLE_EMPTY
variable_keyboard_matrix_active					dq	VARIABLE_EMPTY

variable_keyboard_matrix_low					db	0x00, 0x1B, "1234567890-=", 0x08, 0x09, "qwertyuiop[]", 0x0D, 0x1D, "asdfghjkl;", "'", "`", 0x00, "\", "zxcvbnm,./", 0x00, 0x00, 0x00, " ", 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, "789-456+1230", 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
								db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x9D, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
variable_keyboard_matrix_high					db	0x00, 0x1B, "!@#$%^&*()_+", 0x08, 0x09, "QWERTYUIOP{}", 0x0D, 0x1D, "ASDFGHJKL:", '"', "~", 0x00, "|", "ZXCVBNM<>?", 0x00, 0x00, 0x00, " ", 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, "789-456+1230", 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
								db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x9D, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

variable_keyboard_cache	times	VARIABLE_KEYBOARD_CACHE_SIZE	dw	VARIABLE_EMPTY	; bufor
variable_keyboard_cache_keys					db	VARIABLE_EMPTY

; 64 bitowy kod programu
[BITS 64]

;===============================================================================
; procedura ustawia domyślną macierz klawiszy (małe znaki)
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
keyboard:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx

	; ustaw standardową macierz klawiatury
	mov	rax,	variable_keyboard_matrix_low
	mov	qword [variable_keyboard_matrix_active],	rax

	; włącz przerwanie sprzętowe klawiatury
	mov	cx,	1
	call	cyjon_programmable_interrupt_controller_enable_irq

	; przywróć oryginalne rejestry
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; procedura zapisuje pobrany/zmodyfikowany kod klawisza ASCII z klawiatury do bufora programowego klawiatury
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
keyboard_key_save:
	; sprawdź dostępność miejsca w programowalnym buforze klawiatury
	cmp	byte [variable_keyboard_cache_keys],	VARIABLE_KEYBOARD_CACHE_SIZE - 1
	je	.end	; brak miejsca, zignoruj klawisz

	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi

	; załaduj adres bufora programowego klawiatury
	mov	rsi,	variable_keyboard_cache

	; załaduj wskaźnik pozycji następnego wolnego miejsca w buforze programowym klawiatury
	movzx	rcx,	byte [variable_keyboard_cache_keys]
	shl	rcx,	1	; każdy rekord/klawisz zajmuje 2 Bajty

	; zapisz znak do bufora programowego klawiatury
	mov	word [rsi + rcx],	ax

	; zwięsz ilość znaków ASCII przechowywanych w buforze programowym klawiatury
	inc	byte [variable_keyboard_cache_keys]

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx

.end:
	; powrót z procedury
	ret

;===============================================================================
; procedura przełącza macierz klawiatury przy naciśnięciu/puszczeniu klawisza SHIFT
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
keyboard_key_shift_or_capslock:
	; lewy naciśnięty
	cmp	al,	0x2A
	je	.press

	; prawy naciśnięty
	cmp	al,	0x36
	je	.press

	; lewy puszczony
	cmp	al,	0x2A + 0x80
	je	.release

	; prawy puszczony
	cmp	al,	0x36 + 0x80
	je	.release

	; capslock naciśnięty
	cmp	al,	0x3A
	je	.press_capslock

	; powrót z procedury
	ret

.press_capslock:
	cmp	byte [variable_keyboard_semaphore_capslock],	VARIABLE_TRUE
	jne	.press_capslock_continue

	; naciśnięto znak ":"
	ret

.press_capslock_continue:
	cmp	qword [variable_keyboard_matrix_active],	variable_keyboard_matrix_low
	jne	.press_capslock_another

	mov	rax,	variable_keyboard_matrix_high
	mov	qword [variable_keyboard_matrix_active],	rax

	add	rsp,	VARIABLE_QWORD_SIZE
	jmp	irq33.end

.press_capslock_another:
	mov	rax,	variable_keyboard_matrix_low
	mov	qword [variable_keyboard_matrix_active],	rax

	add	rsp,	VARIABLE_QWORD_SIZE
	jmp	irq33.end

.press:
	; wyłącz klawisz CAPSLOCK, gdy naciśnięty jest SHIFT
	mov	byte [variable_keyboard_semaphore_capslock],	VARIABLE_TRUE

	; przytrzymanie klawisza?
	cmp	byte [variable_keyboard_semaphore_shift],	VARIABLE_TRUE
	je	.press_end

	cmp	qword [variable_keyboard_matrix_active],	variable_keyboard_matrix_low
	jne	.press_another

	; ustaw macierz drugą jako domyślną
	mov	rax,	variable_keyboard_matrix_high
	mov	qword [variable_keyboard_matrix_active],	rax

	jmp	.press_continue

.press_another:
	; ustaw macierz drugą jako domyślną
	mov	rax,	variable_keyboard_matrix_low
	mov	qword [variable_keyboard_matrix_active],	rax

.press_continue:
	; zapisz do bufora informacje o naciśnięciu klawisza SHIFT
	mov	ax,	0x8000	; lewy lub prawy (0x8001 prawy)
	call	keyboard_key_save

	; zakończ obsługę przerwania sprzetowego klawiatury
	add	rsp,	0x08	; usuń adres powrotu z procedury

.press_end:
	; kontynuuj
	jmp	irq33.end

.release:
	; włącz obsługę klawisza CAPSLOCK
	mov	byte [variable_keyboard_semaphore_capslock],	VARIABLE_FALSE
	; włącz klawisz SHIFT
	mov	byte [variable_keyboard_semaphore_shift],	VARIABLE_FALSE

	cmp	qword [variable_keyboard_matrix_active],	variable_keyboard_matrix_low
	jne	.release_another

	; ustaw macierz drugą jako domyślną
	mov	rax,	variable_keyboard_matrix_high
	mov	qword [variable_keyboard_matrix_active],	rax

	jmp	.release_continue

.release_another:
	; ustaw macierz drugą jako domyślną
	mov	rax,	variable_keyboard_matrix_low
	mov	qword [variable_keyboard_matrix_active],	rax

.release_continue:
	; zapisz do bufora informacje o naciśniętym klawiszu SHIFT
	mov	ax,	0xB000	; lewy lub prawy (0xB001 prawy)
	call	keyboard_key_save

	; zakończ obsługę przerwania sprzetowego klawiatury
	add	rsp,	0x08	; usuń adres powrotu z procedury

	; kontynuuj
	jmp	irq33.end

;===============================================================================
; procedura pobiera z bufora programowego klawiatury zachowany pierwszy klawisz
; IN:
;	brak
; OUT:
;	ax - kod ASCII klawisza, lub ZERO jeśli bufor pusty
;
; pozostałe rejestry zachowane
cyjon_keyboard_key_read:
	; wyczyść wynik operacji
	xor	rax,	rax

	; sprawdź czy bufor programowy klawiatury zawiera klawisze
	cmp	byte [variable_keyboard_cache_keys],	VARIABLE_EMPTY
	je	.end

	; zachowaj oryginalne rejestry
	push	rdx
	push	rsi

	; pobierz kod ASCII z bufora programowego klawiatury
	mov	ax,	word [variable_keyboard_cache]

	; usuń znak z bufora programowego klawiatury
	mov	rdx,	qword [variable_keyboard_cache + 0x02]
	mov	qword [variable_keyboard_cache],	rdx
	mov	rdx,	qword [variable_keyboard_cache + 0x0A]
	mov	qword [variable_keyboard_cache + 0x08],	rdx

	; zmniejsz ilość znaków przechowywanych w buforze programowym klawiatury
	dec	byte [variable_keyboard_cache_keys]

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdx

.end:
	; powrót z procedury
	ret

;===============================================================================
; procedura obsługuje przerwanie sprzętowe klawiatury, zachowując informacje o naciśniętych klawiszach
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
irq33:
	; zachowaj oryginalne rejestry
	push	rax
	push	rsi

	; pobierz kod klawisza z bufora sprzętowego klawiatury
	xor	rax,	rax	; wyczyść cały akumulator
	in	al,	0x60

	; sprawdź czy zmienić typ macierzy
	call	keyboard_key_shift_or_capslock

	; sprawdź czy naciśnięto klawisz specjalny
	cmp	al,	0xE0
	jne	.no_special	; nie

	; ustaw flagę
	mov	byte [variable_keyboard_key_special],	0x01

	; koniec
	jmp	.end

.no_special:
	; sprawdź czy specjalny kod klawisza
	cmp	byte [variable_keyboard_key_special],	VARIABLE_EMPTY
	je	.no

	; wyłącz flagę
	mov	byte [variable_keyboard_key_special],	VARIABLE_EMPTY

	; naciśnięcie klawisza strzałki w lewo?
	cmp	al,	0x4B
	je	.key_left_arrow_press

	; puszczenie klawisza strzałki w lewo?
	cmp	al,	0x4B + 0x80
	je	.key_left_arrow_release

	; naciśnięcie klawisza strzałki w prawo?
	cmp	al,	0x4D
	je	.key_right_arrow_press

	; puszczenie klawisza strzałki w prawo?
	cmp	al,	0x4D + 0x80
	je	.key_right_arrow_release

	; naciśnięcie klawisza strzałki w górę?
	cmp	al,	0x48
	je	.key_up_arrow_press

	; puszczenie klawisza strzałki w górę?
	cmp	al,	0x48 + 0x80
	je	.key_up_arrow_release

	; naciśnięcie klawisza strzałki w dół?
	cmp	al,	0x50
	je	.key_down_arrow_press

	; puszczenie klawisza strzałki w dół?
	cmp	al,	0x50 + 0x80
	je	.key_down_arrow_release

	; naciśnięcie prawego klawisza CTRL
	cmp	al,	0x1D
	je	.key_ctrl_right_press

	; puszczenie prawego klawisza CTRL
	cmp	al,	0x1D + 0x80
	je	.key_ctrl_right_release

	; naciśnięcie klawisza End
	cmp	al,	0x4F
	je	.key_end_press

	; puszczenie klawisza End
	cmp	al,	0x4F + 0x80
	je	.key_end_release

	; naciśnięcie klawisza Home
	cmp	al,	0x47
	je	.key_home_press

	; puszczenie klawisza Home
	cmp	al,	0x47 + 0x80
	je	.key_home_release

	; naciśnięcie klawisza Delete
	cmp	al,	0x53
	je	.key_delete_press

	; puszczenie klawisza Delete
	cmp	al,	0x53 + 0x80
	je	.key_delete_release

	; naciśnięcie klawisza PageUp
	cmp	al,	0x49
	je	.key_pageup_press

	; puszczenie klawisza PageUp
	cmp	al,	0x49 + 0x80
	je	.key_pageup_release

	; naciśnięcie klawisza PageDown
	cmp	al,	0x51
	je	.key_pagedown_press

	; puszczenie klawisza PageDown
	cmp	al,	0x51 + 0x80
	je	.key_pagedown_release

	; naciśnięcie klawisza Insert
	cmp	al,	0x52
	je	.key_insert_press

	; puszczenie klawisza Insert
	cmp	al,	0x52 + 0x80
	je	.key_insert_release

	; nie rozpoznano znaku złożonego
	jmp	.end

.key_left_arrow_press:
	; ustaw systemowy kod klawisza
	mov	ax,	0x8002

	; koniec
	jmp	.save

.key_left_arrow_release:
	; ustaw systemowy kod klawisza
	mov	ax,	0xB002

	; koniec
	jmp	.save

.key_right_arrow_press:
	; ustaw systemowy kod klawisza
	mov	ax,	0x8003

	; koniec
	jmp	.save

.key_right_arrow_release:
	; ustaw systemowy kod klawisza
	mov	ax,	0xB003

	; koniec
	jmp	.save

.key_up_arrow_press:
	; ustaw systemowy kod klawisza
	mov	ax,	0x8004

	; koniec
	jmp	.save

.key_up_arrow_release:
	; ustaw systemowy kod klawisza
	mov	ax,	0xB004

	; koniec
	jmp	.save

.key_down_arrow_press:
	; ustaw systemowy kod klawisza
	mov	ax,	0x8005

	; koniec
	jmp	.save

.key_down_arrow_release:
	; ustaw systemowy kod klawisza
	mov	ax,	0xB005

	; koniec
	jmp	.save

.key_ctrl_right_press:
	; ustaw systemowy kod klawisza
	mov	ax,	0x8006

	; koniec
	jmp	.save

.key_ctrl_right_release:
	; ustaw systemowy kod klawisza
	mov	ax,	0xB006

	; koniec
	jmp	.save

.key_end_press:
	; ustaw systemowy kod klawisza
	mov	ax,	0x8008

	; koniec
	jmp	.save

.key_end_release:
	; ustaw systemowy kod klawisza
	mov	ax,	0xB008

	; koniec
	jmp	.save

.key_home_press:
	; ustaw systemowy kod klawisza
	mov	ax,	0x8007

	; koniec
	jmp	.save

.key_home_release:
	; ustaw systemowy kod klawisza
	mov	ax,	0xB007

	; koniec
	jmp	.save

.key_delete_press:
	; ustaw systemowy kod klawisza
	mov	ax,	0x8009

	; koniec
	jmp	.save

.key_delete_release:
	; ustaw systemowy kod klawisza
	mov	ax,	0xB009

	; koniec
	jmp	.save

.key_pageup_press:
	; ustaw systemowy kod klawisza
	mov	ax,	0x800A

	; koniec
	jmp	.save

.key_pageup_release:
	; ustaw systemowy kod klawisza
	mov	ax,	0xB00A

	; koniec
	jmp	.save

.key_pagedown_press:
	; ustaw systemowy kod klawisza
	mov	ax,	0x800B

	; koniec
	jmp	.save

.key_pagedown_release:
	; ustaw systemowy kod klawisza
	mov	ax,	0xB00B

	; koniec
	jmp	.save

.key_insert_press:
	; ustaw systemowy kod klawisza
	mov	ax,	0x800C

	; koniec
	jmp	.save

.key_insert_release:
	; ustaw systemowy kod klawisza
	mov	ax,	0xB00C

	; koniec
	jmp	.save

.no:
	; pobierz kod ASCII klawisza z macierzy
	mov	rsi,	qword [variable_keyboard_matrix_active]
	mov	al,	byte [rsi + rax]

	; sprawdź czy naciśnięto klawisz ENTER
	cmp	al,	0x0D
	jne	.no_enter

	; zapisz kod ASCII klawisza
	call	keyboard_key_save

	; koniec
	jmp	.end

.no_enter:
	; sprawdź czy naciśnięto klawisz BACKSPACE
	cmp	al,	0x08
	jne	.no_backspace

	; zapisz kod ASCII klawisza
	call	keyboard_key_save

	; koniec
	jmp	.end

.no_backspace:
	; sprawdź czy naciśnięto klawisz ESC
	cmp	al,	0x1B
	jne	.no_esc

	; kod ASCII klawisza
	call	keyboard_key_save

	; koniec
	jmp	.end

.no_esc:
	; sprawdź czy naciśnięto klawisz TAB
	cmp	al,	0x09
	jne	.no_tab

	; kod ASCII klawisza
	call	keyboard_key_save

	; koniec
	jmp	.end

.no_tab:
	; sprawdź czy naciśnięto klawisz CTRL
	cmp	al,	0x1D
	jne	.no_ctrl_press

	; kod ASCII klawisza
	call	keyboard_key_save

	; koniec
	jmp	.end

.no_ctrl_press:
	; sprawdź czy puszczono klawisz CTRL
	cmp	al,	0x1D + 0x80
	jne	.no_ctrl_release

	; kod ASCII klawisza
	call	keyboard_key_save

	; koniec
	jmp	.end

.no_ctrl_release:
	; sprawdź czy kod ASCII klawisza jest możliwy do wyświetlenia

	; test pierwszy
	cmp	al,	0x20
	jb	.end

	; test drugi
	cmp	al,	0x7E
	ja	.end

.save:
	; kod ASCII klawisza jest możliwy do wyświetlenia
	call	keyboard_key_save

.end:
	; wyślij informacje o zakończeniu przerwania sprzętowego
	mov	al,	0x20
	out	0x20,	al

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rax

	; powrót z przerwania
	iretq
