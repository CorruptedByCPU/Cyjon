;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
service_cero_ipc:
	; zachowaj oryginalne rejestry
	push	rax
	push	rsi
	push	rdi
	push	r8
	push	r9

	; pobierz wiadomość
	mov	rdi,	service_cero_ipc_data
	call	kernel_ipc_receive
	jc	.end	; brak wiadomości

	; wiadomość od menedżera okien?
	mov	rax,	qword [service_desu_pid]
	cmp	qword [rdi + KERNEL_IPC_STRUCTURE.pid_source],	rax
	jne	.end	; nie, zignoruj

	; pobierz identyfikator okna i koordynary wskaźnika kursora
	mov	rax,	qword [rdi + KERNEL_IPC_STRUCTURE.data + SERVICE_DESU_STRUCTURE_IPC.id]
	mov	r8,	qword [rdi + KERNEL_IPC_STRUCTURE.data + SERVICE_DESU_STRUCTURE_IPC.value0]
	mov	r9,	qword [rdi + KERNEL_IPC_STRUCTURE.data + SERVICE_DESU_STRUCTURE_IPC.value1]

	; naciśnięcie prawego klawisza myszki?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.data + SERVICE_DESU_STRUCTURE_IPC.type],	SERVICE_DESU_IPC_MOUSE_BUTTON_RIGHT_press
	jne	.end	; nie

	; akcja dotyczy okna "taskbar"?
	cmp	rax,	qword [service_cero_window_taskbar + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.id]
	je	.end	; tak, brak akcji cdn.

.no_taskbar:
	; akcja dotyczy okna "background"?
	cmp	rax,	qword [service_cero_window_workbench + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.id]
	jne	.end	; nie

	; koryguj pozycje okna "menu"
	mov	rsi,	qword [service_cero_window_menu_pointer]

	; czy pozycja wskaźnika kursora pozwala na wyświetlenie okna "menu"?
	mov	rax,	r8
	add	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	cmp	rax,	qword [service_cero_window_workbench + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	jl	.y	; tak na osi X

	; wyświetl okno "menu" po lewej stronie wskaźnika kursora
	sub	r8,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]

.y:
	; czy pozycja wskaźnika kursora pozwala na wyświetlenie okna "menu"? (uwzględniając wysokość okna "taskbar")
	mov	rax,	r9
	add	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	cmp	rax,	qword [service_cero_window_taskbar + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
	jl	.visible	; tak na osi Y

	; wyświetl okno "menu" nad oknem "taskbar"
	mov	r9,	qword [service_cero_window_taskbar + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
	sub	r9,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	dec	r9	; zachowaj 1 piksel odstępu między oknami "menu" i "taskbar" (rzecz gustu)

.visible:
	; ustaw nową pozycję okna "menu"
	mov	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.x],	r8
	mov	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.y],	r9

	; ustaw flagi "widoczne" oraz "odśwież" dla okna "menu"
	or	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush

	; koniec obsługi prawego przycisku myszki
	jmp	.end

.end:
	; przywróć oryginalne rejestry
	pop	r9
	pop	r8
	pop	rdi
	pop	rsi
	pop	rax

	; powrót z procedury
	ret
