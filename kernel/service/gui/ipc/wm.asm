;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
kernel_gui_ipc_wm:
	; komunikat niezwiązany z myszką?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_MOUSE
	jne	.end	; tak

	; pobierz identyfikator okna i koordynary wskaźnika kursora
	mov	rax,	qword [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_WM_STRUCTURE_IPC.id]
	mov	r8,	qword [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_WM_STRUCTURE_IPC.value0]
	mov	r9,	qword [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_WM_STRUCTURE_IPC.value1]

	; naciśnięcie prawego klawisza myszki?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_WM_STRUCTURE_IPC.action],	KERNEL_WM_IPC_MOUSE_btn_right_press
	je	.right_mouse_button	; tak

	; akcja dotyczy okna "menu"?
	cmp	rax,	qword [kernel_gui_window_menu + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.id]
	jne	.left_mouse_button_no_menu	; nie

	; okno jest widoczne?
	test	qword [kernel_gui_window_menu + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_visible
	jz	.end	; nie, zignoruj akcję

	; okno zostało automatycznie ukryte, usuń informację
	and	qword [kernel_gui_window_menu + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	~LIBRARY_BOSU_WINDOW_FLAG_visible

	; sprawdź, którego elementu okna dotyczny akcja
	mov	rsi,	kernel_gui_window_menu
	call	library_bosu_element
	jc	.end	; brak akcji

	; element posiada przypisaną procedurę obsługi akcji?
	cmp	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.event],	STATIC_EMPTY
	je	.end	; nie, koniec obsługi akcji

	; wykonaj procedurę powiązaną z elementem
	push	.end	; powrót z procedury
	push	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.event]
	ret	; call

.left_mouse_button_no_menu:
	; akcja dotyczy okna "taskbar"?
	cmp	rax,	qword [kernel_gui_window_taskbar + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.id]
	jne	.end	; nie

	; wykonaj działanie związane z paskiem zadań
	call	kernel_gui_taskbar_event

	; koniec obsługi komunikatu
	jmp	.end

.right_mouse_button:
	; akcja dotyczy okna "taskbar"?
	cmp	rax,	qword [kernel_gui_window_taskbar + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.id]
	je	.end	; tak, brak akcji cdn.

	; akcja dotyczy okna "background"?
	cmp	rax,	qword [kernel_gui_window_workbench + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.id]
	jne	.end	; nie

	; koryguj pozycje okna "menu"
	mov	rbx,	qword [kernel_gui_window_menu + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.id]
	call	kernel_wm_object_by_id

	; czy pozycja wskaźnika kursora pozwala na wyświetlenie okna "menu"?
	mov	rax,	r8
	add	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	cmp	rax,	qword [kernel_gui_window_workbench + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	jl	.y	; tak na osi X

	; wyświetl okno "menu" po lewej stronie wskaźnika kursora
	sub	r8,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]

.y:
	; czy pozycja wskaźnika kursora pozwala na wyświetlenie okna "menu"? (uwzględniając wysokość okna "taskbar")
	mov	rax,	r9
	add	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	cmp	rax,	qword [kernel_gui_window_taskbar + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
	jl	.visible	; tak na osi Y

	; wyświetl okno "menu" nad oknem "taskbar"
	mov	r9,	qword [kernel_gui_window_taskbar + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
	sub	r9,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	dec	r9	; zachowaj 1 piksel odstępu między oknami "menu" i "taskbar" (rzecz gustu)

.visible:
	; ustaw nową pozycję okna "menu"
	mov	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.x],	r8
	mov	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.y],	r9

	; ustaw flagi "widoczne" oraz "odśwież" dla okna "menu"
	or	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush

	; zapamiętaj
	or	qword [kernel_gui_window_menu + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush

.end:
	; powrót z procedury
	ret

	macro_debug	"kernel_gui_ipc_wm"
