;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

; ;===============================================================================
; service_desu_cursor_flush:
; 	; zachowaj oryginalne rejestry
; 	push	rax
; 	push	rsi
;
; 	;-----------------------------------------------------------------------
; 	; wyświetlić nową zawartość macierzy kursora?
; 	;-----------------------------------------------------------------------
; 	test	qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_flush
; 	jz	.no	; nie
;
; 	; zarejestruj strefę kursora
; 	mov	rsi,	service_desu_object_cursor
; 	call	service_desu_zone_insert_by_object
; 	call	service_desu_zone
; 	call	service_desu_fill
;
; 	; obiekt kursora został wyświetlony
; 	and	qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	~SERVICE_DESU_OBJECT_FLAG_flush
;
; .no:
; 	; przywróć oryginalne rejestry
; 	pop	rsi
; 	pop	rax
;
; 	; powrót z procedury
; 	ret

;===============================================================================
service_desu_cursor:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	r8
	push	r9
	push	r10
	push	r11

	;-----------------------------------------------------------------------
	; pobierz pozycje wskaźnika myszy
	mov	r8d,	dword [driver_ps2_mouse_x]
	mov	r9d,	dword [driver_ps2_mouse_y]

	; delta osi X
	mov	r10,	r8
	sub	r10,	qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.x]

	; delta osi Y
	mov	r11,	r9
	sub	r11,	qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.y]

; 	;-----------------------------------------------------------------------
; 	; naciśnięto lewy przycisk myszki?
; 	bt	word [driver_ps2_mouse_state],	DRIVER_PS2_DEVICE_MOUSE_PACKET_LMB_bit
; 	jnc	.no_mouse_button_left_action	; nie
;
; 	; lewy przycisk myszki był już naciśnięty?
; 	cmp	byte [service_desu_mouse_button_left_semaphore],	STATIC_TRUE
; 	je	.no_mouse_button_left_action	; tak, zignoruj
;
; 	; zapamiętaj ten stan
; 	mov	byte [service_desu_mouse_button_left_semaphore],	STATIC_TRUE
;
; 	; jest już wybrany obiekt aktywny?
; 	cmp	qword [service_desu_object_selected_pointer],	STATIC_EMPTY
; 	jne	.no_mouse_button_left_action	; tak, zignoruj przytrzymanie lewego klawisza myszki na innym obiekcie
;
; 	; sprawdź, który obiekt znajduje się pod wskaźnikiem kursora
;  	call	service_desu_object_find
; 	jc	.no_mouse_button_left_action	; brak obiektu
;
; 	; ustaw obiekt jako aktywny
; 	mov	qword [service_desu_object_selected_pointer],	rsi
;
; 	; ukryj "kruche" obiekty
; 	call	service_desu_object_hide
;
; 	; jest to pierwszy obiekt z listy?
; 	cmp	rsi,	qword [service_desu_object_list_address]
; 	je	.privileged	; tak
;
; 	; obiekt powinien zachować swoją warstwę?
; 	test	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_fixed_z
; 	jnz	.fixed_z	; tak
;
; 	; przesuń obiekt na koniec listy (wierzch pulpitu)
; 	; call	service_desu_object_move_top
;
; 	; aktualizuj wskaźnik obiektu aktywnego
; 	mov	qword [service_desu_object_selected_pointer],	rsi
;
; .fixed_z:
; 	; wyświetl ponownie zawartość obiektu okna
; 	or	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_flush
;
; 	; wyświetl ponownie zawartość obiektu kursora (przysłonił go aktywny obiekt)
; 	or	qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_flush
;
; 	;-----------------------------------------------------------------------
;
; .privileged:
; 	; ; pobierz ID okna i PID
; 	; mov	rax,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.id]
; 	; mov	rbx,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.pid]
; 	;
; 	; ; skomponuj komunikat dla procesu
; 	; mov	rsi,	service_desu_message
; 	;
; 	; ; wyślij informacje o typie akcji
; 	; mov	byte [rsi + SERVICE_DESU_STRUCTURE_MESSAGE.type],	SERVICE_DESU_MESSAGE_TYPE_MOUSE_BUTTON_left_press
; 	;
; 	; ; wyślij informacje o ID okna biorącego udział
; 	; mov	qword [rsi + SERVICE_DESU_STRUCTURE_MESSAGE.id],	rax
; 	;
; 	; ; wyślij informacje o pozycji wskaźnika kursora
; 	; mov	qword [rsi + SERVICE_DESU_STRUCTURE_MESSAGE.value0],	r8	; x
; 	; mov	qword [rsi + SERVICE_DESU_STRUCTURE_MESSAGE.value1],	r9	; y
; 	;
; 	; ; wyślij komunikat
; 	; call	kernel_ipc_send
;
; .no_mouse_button_left_action:
; 	; puszczono lewy przycisk myszki?
; 	bt	word [driver_ps2_mouse_state],	DRIVER_PS2_DEVICE_MOUSE_PACKET_LMB_bit
; 	jc	.no_mouse_button_left_release	; nie
;
; .no_mouse_button_left_action_release:
; 	; usuń stan
; 	mov	byte [service_desu_mouse_button_left_semaphore],	STATIC_FALSE
;
; .no_mouse_button_left_action_release_selected:
; 	; usuń informacje o aktywnym obiekcie
; 	mov	qword [service_desu_object_selected_pointer],	STATIC_EMPTY
;
; .no_mouse_button_left_release:
; 	;-----------------------------------------------------------------------
; 	; naciśnięto prawy przycisk myszki?
; 	bt	word [driver_ps2_mouse_state],	DRIVER_PS2_DEVICE_MOUSE_PACKET_RMB_bit
; 	jnc	.no_mouse_button_right_action	; nie
;
; 	; prawy przycisk myszki był już naciśnięty?
; 	cmp	byte [service_desu_mouse_button_right_semaphore],	STATIC_TRUE
; 	je	.no_mouse_button_right_action	; tak, zignoruj
;
; 	; zapamiętaj ten stan
; 	mov	byte [service_desu_mouse_button_right_semaphore],	STATIC_TRUE
;
; 	; sprawdź, który obiekt znajduje się pod wskaźnikiem kursora
;  	call	service_desu_object_find
; 	jc	.no_mouse_button_right_action	; brak obiektu pod wskaźnikiem
;
; 	; ukryj "kruche" obiekty
; 	call	service_desu_object_hide
;
; 	; ; pobierz ID okna i PID
; 	; mov	rax,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.id]
; 	; mov	rbx,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.pid]
; 	;
; 	; ; skomponuj komunikat dla procesu
; 	; mov	rsi,	service_desu_message
; 	;
; 	; ; wyślij informacje o typie akcji
; 	; mov	byte [rsi + SERVICE_DESU_STRUCTURE_MESSAGE.type],	SERVICE_DESU_MESSAGE_TYPE_MOUSE_BUTTON_right_press
; 	;
; 	; ; wyślij informacje o ID okna biorącego udział
; 	; mov	qword [rsi + SERVICE_DESU_STRUCTURE_MESSAGE.id],	rax
; 	;
; 	; ; wyślij informacje o pozycji wskaźnika kursora
; 	; mov	qword [rsi + SERVICE_DESU_STRUCTURE_MESSAGE.value0],	r8	; x
; 	; mov	qword [rsi + SERVICE_DESU_STRUCTURE_MESSAGE.value1],	r9	; y
; 	;
; 	; ; wyślij komunikat
; 	; call	kernel_ipc_send
;
; .no_mouse_button_right_action:
; 	; puszczono prawy przycisk myszki?
; 	bt	word [driver_ps2_mouse_state],	DRIVER_PS2_DEVICE_MOUSE_PACKET_RMB_bit
; 	jc	.no_mouse_button_right_release	; nie
;
; 	; usuń ten stan
; 	mov	byte [service_desu_mouse_button_right_semaphore],	STATIC_FALSE
;
; .no_mouse_button_right_release:
	;-----------------------------------------------------------------------
	; wystąpiło przesunięcie wskaźnika kursora? (delty)
	test	r10,	r10
	jnz	.moved	; tak
	test	r11,	r11
	jz	.end	; nie

.moved:
	; przetwórz strefę zajętą przez obiekt kursora
	mov	rsi,	service_desu_object_cursor
	call	service_desu_zone_insert_by_object
	call	service_desu_zone

	; aktualizuj specyfikacje obiektu kursora
	mov	qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.x],	r8
	mov	qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.y],	r9

	call	service_desu_fill_insert_by_object
	call	service_desu_fill

	; obiekt kursora został zaaktualizowany
	; or	qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_flush

; 	;-----------------------------------------------------------------------
;
; 	; jeśli wraz z przyciśniętym lewym klawiszem myszki
; 	cmp	byte [service_desu_mouse_button_left_semaphore],	STATIC_FALSE
; 	je	.end	; niestety, nie
;
; 	; został wybrany obiekt aktywny/widoczny
; 	cmp	qword [service_desu_object_selected_pointer],	STATIC_EMPTY
; 	je	.end	; też nie
;
; 	; przemieść obiekt wraz z wskaźnikiem kursora
; 	; call	service_desu_object_move
;
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

	; informacja dla Bochs
	macro_debug	"service desu cursor"
