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
	; zachowaj oryginalne rejestry
	push	rax
	push	rsi

	; pobierz kod klawisza z bufora
	call	driver_ps2_keyboard_read
	jz	.end	; brak

	; pobierz wskaźnik do aktywnego obiektu, który otrzyma komunikat
	mov	rsi,	qword [kernel_wm_object_active_pointer]

	; brak wybranego obiektu?
	test	rsi,	rsi
	jz	.end	; tak, zignoruj klawisz

	; wyślij do procesu będącego właścicielem obiektu informacje o klawiaturze
	call	kernel_wm_ipc_keyboard

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rax

	; powrót z procedury
	ret

	; informacja dla Bochs
	macro_debug	"kernel_wm_keyboard"
