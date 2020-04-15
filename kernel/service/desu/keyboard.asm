;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
; wyjście:
;	Flaga ZF - jeśli brak klawisza (lub okno nie było do tego uprawnione)
;	ax - kod ASCII klawisza lub jego sekwencja
service_desu_keyboard:
	; pobierz kod klawisza z bufora
	call	driver_ps2_keyboard_read
	jz	.end	; brak

	; pobierz wskaźnik do aktywnego obiektu, który otrzyma komunikat
	mov	rsi,	qword [service_desu_object_selected_pointer]

	; brak wybranego obiektu?
	test	rsi,	rsi
	jz	.leave	; tak, zignoruj klawisz

	; wyślij do procesu będącego właścicielem obiektu informacje o klawiaturze
	mov	cl,	SERVICE_DESU_IPC_KEYBOARD
	call	service_desu_ipc_keyboard

.leave:
	; naciśnięto klawisz lewy ALT?
	cmp	ax,	DRIVER_PS2_KEYBOARD_PRESS_ALT_LEFT
	jne	.no_press_alt_left	; nie

	; ustaw flagę
	mov	byte [service_desu_keyboard_alt_left_semaphore],	STATIC_TRUE

.no_press_alt_left:
	; puszczono klawisz lewy ALT?
	cmp	ax,	DRIVER_PS2_KEYBOARD_RELEASE_ALT_LEFT
	jne	.end	; nie

	; wyłącz flagę
	mov	byte [service_desu_keyboard_alt_left_semaphore],	STATIC_FALSE

.end:
	; powrót z procedury
	ret

	; informacja dla Bochs
	macro_debug	"service_desu_keyboard"
