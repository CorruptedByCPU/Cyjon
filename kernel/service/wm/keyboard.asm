;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wyjście:
;	Flaga ZF - jeśli brak klawisza (lub okno nie było do tego uprawnione)
;	ax - kod ASCII klawisza lub jego sekwencja
kernel_wm_keyboard:
	; pobierz kod klawisza z bufora
	call	driver_ps2_keyboard_read
	jz	.end	; brak

	; pobierz wskaźnik do aktywnego obiektu, który otrzyma komunikat
	mov	rsi,	qword [kernel_wm_object_selected_pointer]

	; brak wybranego obiektu?
	test	rsi,	rsi
	jz	.leave	; tak, zignoruj klawisz

	; wyślij do procesu będącego właścicielem obiektu informacje o klawiaturze
	call	kernel_wm_ipc_keyboard

.leave:
	; naciśnięto klawisz lewy ALT?
	cmp	ax,	DRIVER_PS2_KEYBOARD_PRESS_ALT_LEFT
	jne	.no_press_alt_left	; nie

	; ustaw flagę
	mov	byte [kernel_wm_keyboard_alt_left_semaphore],	STATIC_TRUE

.no_press_alt_left:
	; puszczono klawisz lewy ALT?
	cmp	ax,	DRIVER_PS2_KEYBOARD_RELEASE_ALT_LEFT
	jne	.end	; nie

	; wyłącz flagę
	mov	byte [kernel_wm_keyboard_alt_left_semaphore],	STATIC_FALSE

.end:
	; powrót z procedury
	ret

	; informacja dla Bochs
	macro_debug	"kernel_wm_keyboard"
