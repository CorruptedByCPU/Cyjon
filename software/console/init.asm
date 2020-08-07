;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

	; utwórz okno
	mov	rsi,	console_window
	call	library_bosu

	; wylicz adres wskaźnika przestrzeni danych elementu "terminal"
	mov	rax,	qword [console_window.element_terminal + LIBRARY_BOSU_STRUCTURE_ELEMENT_DRAW.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
	mul	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.scanline]
	add	rax,	qword [console_window + LIBRARY_BOSU_STRUCTURE_WINDOW.address]

	; uzupełnij tablicę "terminal" o dany wskaźnik
	mov	qword [console_terminal_table + LIBRARY_TERMINAL_STRUCTURE.address],	rax

	; inicjalizuj przestrzeń elementu "terminal"
	mov	r8,	console_terminal_table
	call	library_terminal

	; wyświetl okno
	mov	al,	KERNEL_WM_WINDOW_update
	or	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush
	int	KERNEL_WM_IRQ

	; uruchom powłokę systemu
	mov	ax,	KERNEL_SERVICE_PROCESS_run
	mov	bl,	KERNEL_SERVICE_PROCESS_RUN_FLAG_out_to_in_parent
	mov	ecx,	console_shell_file_end - console_shell_file
	mov	rsi,	console_shell_file
	int	KERNEL_SERVICE

	; zachowaj PID powłoki
	mov	qword [console_shell_pid],	rcx
