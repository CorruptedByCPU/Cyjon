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
	mov	r8d,	dword [driver_ps2_mouse_x]
	mov	r9d,	dword [driver_ps2_mouse_y]

	; delta osi X
	mov	r14,	r8
	sub	r14,	qword [kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x]

	; delta osi Y
	mov	r15,	r9
	sub	r15,	qword [kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y]

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
	jc	.no_mouse_button_left_action	; brak obiektu

	; ustaw obiekt jako aktywny
	mov	qword [kernel_wm_object_selected_pointer],	rsi

	; wyślij komunikat do procesu "naciśnięcie lewego klawisza myszki"
	mov	cl,	KERNEL_WM_IPC_MOUSE_btn_left_press
	call	kernel_wm_ipc_mouse

	; obiekt powinien zachować swoją warstwę?
	test	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_fixed_z
	jnz	.fixed_z	; tak

	; przesuń obiekt na koniec listy
	mov	rax,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.pid]
	call	kernel_wm_object_up

	; aktualizuj wskaźnik obiektu aktywnego
	mov	qword [kernel_wm_object_selected_pointer],	rsi

	; tutaj można by się pokusić o sprawdzenie, który fragment obiektu nie jest widoczny
	; zamiast przerysowywać cały... todo
	;
	; można przyjąć, że część obiektów będzie na tyle mała...
	; szybciej przerysujemy cały, niż znajdziemy fragmenty niewidoczne

	; wyświetl ponownie zawartość obiektu
	or	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_flush

	; wyświetl ponownie zawartość obiektu kursora (przysłoniony przez obiekt)
	or	qword [kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_flush

.fixed_z:
	; ukryj obiekty z flagą "kruchy"
	call	kernel_wm_object_hide

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

	; ukryj "kruche" obiekty
	call	kernel_wm_object_hide

	; wyślij komunikat do procesu "naciśnięcie prawego klawisza myszki"
	mov	cl,	KERNEL_WM_IPC_MOUSE_btn_right_press
	call	kernel_wm_ipc_mouse

.no_mouse_button_right_action:
	; puszczono prawy przycisk myszki?
	bt	word [driver_ps2_mouse_state],	DRIVER_PS2_DEVICE_MOUSE_PACKET_RMB_bit
	jc	.no_mouse_button_right_release	; nie

	; usuń ten stan
	mov	byte [kernel_wm_mouse_button_right_semaphore],	STATIC_FALSE

.no_mouse_button_right_release:
	; przesunięcie wskaźnika kursora na osi X
	test	r14,	r14
	jnz	.move	; tak

	; przesunięcie wskaźnika kursora na osi Y
	test	r15,	r15
	jz	.end	; nie

.move:
	; przetwórz strefę zajętą przez obiekt kursora
	mov	rsi,	kernel_wm_object_cursor
	call	kernel_wm_zone_insert_by_object

	; aktualizuj specyfikacje obiektu kursora
	add	qword [kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x],	r14
	add	qword [kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y],	r15

	; obiekt kursora został zaaktualizowany
	or	qword [kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_flush

	;-----------------------------------------------------------------------

	; jeśli wraz z przyciśniętym lewym klawiszem myszki
	cmp	byte [kernel_wm_mouse_button_left_semaphore],	STATIC_FALSE
	je	.end	; niestety, nie

	; został wybrany obiekt aktywny/widoczny
	cmp	qword [kernel_wm_object_selected_pointer],	STATIC_EMPTY
	je	.end	; też nie

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
