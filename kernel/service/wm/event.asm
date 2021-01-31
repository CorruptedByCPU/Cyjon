;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
kernel_wm_event:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	r8
	push	r9
	push	r10
	push	r11

	; sprawdź stan bufora klawiatury
	call	kernel_wm_keyboard

	;-----------------------------------------------------------------------
	; pobierz pozycje wskaźnika myszy
	mov	r8w,	word [driver_ps2_mouse_x]
	mov	r9w,	word [driver_ps2_mouse_y]

	; delta osi X
	mov	r14w,	r8w
	sub	r14w,	word [kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x]

	; delta osi Y
	mov	r15w,	r9w
	sub	r15w,	word [kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y]

	;-----------------------------------------------------------------------
	; naciśnięto lewy przycisk myszki?
	bt	word [driver_ps2_mouse_state],	DRIVER_PS2_DEVICE_MOUSE_PACKET_LMB_bit
	jnc	.no_mouse_button_left_action	; nie

	; lewy przycisk myszki był już naciśnięty?
	cmp	byte [kernel_wm_mouse_button_left_semaphore],	STATIC_TRUE
	je	.no_mouse_button_left_action	; tak, zignoruj

	; zapamiętaj ten stan
	mov	byte [kernel_wm_mouse_button_left_semaphore],	STATIC_TRUE

	; sprawdź, który obiekt znajduje się pod wskaźnikiem kursora
 	call	kernel_wm_object_find
	jc	.no_mouse_button_left_action	; brak elementu opisującego rekord w tablicy obiektów

	; zapamiętaj wskaźnik wybranego obiektu
	mov	qword [kernel_wm_object_selected_pointer],	rsi
	mov	qword [kernel_wm_object_active_pointer],	rsi

	; wyślij komunikat do procesu "naciśnięcie lewego klawisza myszki"
	mov	cl,	KERNEL_IPC_MOUSE_EVENT_left_press
	call	kernel_wm_ipc_mouse

	; obiekt powinien zachować swoją warstwę?
	test	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_fixed_z
	jnz	.fixed_z	; tak

	; przesuń obiekt na koniec listy
	call	kernel_wm_object_up

	; tutaj można by się pokusić o sprawdzenie, który fragment obiektu nie jest widoczny
	; zamiast przerysowywać cały... todo
	;
	; można przyjąć, że część obiektów będzie na tyle mała...
	; szybciej przerysujemy cały, niż znajdziemy fragmenty niewidoczne

	; wyświetl ponownie zawartość obiektu
	or	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_flush

	; wyświetl ponownie zawartość obiektu kursora (przysłoniony przez obiekt)
	or	word [kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_flush

.fixed_z:
	; ukryj obiekty oznaczone flagą FRAGILE
	call	kernel_wm_object_hide_fragile

.no_mouse_button_left_action:
	; puszczono lewy przycisk myszki?
	bt	word [driver_ps2_mouse_state],	DRIVER_PS2_DEVICE_MOUSE_PACKET_LMB_bit
	jc	.no_mouse_button_left_release	; nie

.no_mouse_button_left_action_release:
	; usuń stan
	mov	byte [kernel_wm_mouse_button_left_semaphore],	STATIC_FALSE

.no_mouse_button_left_action_release_selected:
	; usuń informacje o aktywnym obiekcie
	; mov	qword [kernel_wm_object_selected_pointer],	STATIC_EMPTY

.no_mouse_button_left_release:
	;-----------------------------------------------------------------------
	; naciśnięto prawy przycisk myszki?
	bt	word [driver_ps2_mouse_state],	DRIVER_PS2_DEVICE_MOUSE_PACKET_RMB_bit
	jnc	.no_mouse_button_right_action	; nie

	; prawy przycisk myszki był już naciśnięty?
	cmp	byte [kernel_wm_mouse_button_right_semaphore],	STATIC_TRUE
	je	.no_mouse_button_right_action	; tak, zignoruj

	; zapamiętaj ten stan
	mov	byte [kernel_wm_mouse_button_right_semaphore],	STATIC_TRUE

	; sprawdź, który obiekt znajduje się pod wskaźnikiem kursora
 	call	kernel_wm_object_find
	jc	.no_mouse_button_right_action	; brak obiektu pod wskaźnikiem

	; ukryj obiekty oznaczone flagą FRAGILE
	call	kernel_wm_object_hide_fragile

	; wyślij komunikat do procesu "naciśnięcie prawego klawisza myszki"
	mov	cl,	KERNEL_IPC_MOUSE_EVENT_right_press
	call	kernel_wm_ipc_mouse

.no_mouse_button_right_action:
	; puszczono prawy przycisk myszki?
	bt	word [driver_ps2_mouse_state],	DRIVER_PS2_DEVICE_MOUSE_PACKET_RMB_bit
	jc	.no_mouse_button_right_release	; nie

	; usuń ten stan
	mov	byte [kernel_wm_mouse_button_right_semaphore],	STATIC_FALSE

.no_mouse_button_right_release:
	; przesunięcie wskaźnika kursora na osi X
	test	r14w,	r14w
	jnz	.move	; tak

	; przesunięcie wskaźnika kursora na osi Y
	test	r15w,	r15w
	jz	.end	; nie

.move:
	; przetwórz strefę zajętą przez obiekt kursora
	mov	rax,	kernel_wm_object_cursor
	call	kernel_wm_zone_insert_by_object

	; aktualizuj specyfikacje obiektu kursora
	add	word [kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x],	r14w
	add	word [kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y],	r15w

	; obiekt kursora został zaaktualizowany
	or	word [kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_flush

	;-----------------------------------------------------------------------

	; jeśli wraz z przyciśniętym lewym klawiszem myszki
	cmp	byte [kernel_wm_mouse_button_left_semaphore],	STATIC_FALSE
	je	.end	; niestety, nie

	; został wybrany obiekt aktywny/widoczny
	cmp	qword [kernel_wm_object_selected_pointer],	STATIC_EMPTY
	je	.end	; też nie

	; oraz przytrzymano lewy klawisz ALT
	cmp	byte [kernel_wm_keyboard_alt_left_semaphore],	STATIC_FALSE
	je	.end	; nawet nie

	; przemieść obiekt wraz z wskaźnikiem kursora
	call	kernel_wm_object_move

.end:
	; przywróć oryginalne rejestry
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_event"
