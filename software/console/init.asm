;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	; przygotuj przestrzeń pod dane przychodzące z standardowego wejścia
	mov	ax,	KERNEL_SERVICE_PROCESS_memory_alloc
	mov	ecx,	KERNEL_STREAM_SIZE_byte
	int	KERNEL_SERVICE
	jc	console.close	; brak wystarczającej przestrzeni pamięci

	; zachowaj adres bufora
	mov	qword [console_cache_address],	rdi

	; utwórz okno
	mov	rsi,	console_window
	call	library_bosu
	jc	console.close	; brak wystarczającej przestrzeni pamięci

	; wylicz adres wskaźnika przestrzeni danych elementu "terminal"
	mov	rax,	qword [console_window.element_terminal + LIBRARY_BOSU_STRUCTURE_ELEMENT_DRAW.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
	mul	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	add	rax,	qword [console_window.element_terminal + LIBRARY_BOSU_STRUCTURE_ELEMENT_DRAW.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x]
	shl	rax,	KERNEL_VIDEO_DEPTH_shift
	add	rax,	qword [console_window + LIBRARY_BOSU_STRUCTURE_WINDOW.address]

	; uzupełnij tablicę "terminal" o adres przestrzeni
	mov	qword [console_terminal_table + LIBRARY_TERMINAL_STRUCTURE.address],	rax

	; uzupełnij tablicę "terminal" o scanline okna
	mov	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.scanline_byte]
	mov	qword [console_terminal_table + LIBRARY_TERMINAL_STRUCTURE.scanline_byte],	rax

	; inicjalizuj przestrzeń elementu "terminal"
	mov	r8,	console_terminal_table
	call	library_terminal

	; uruchom powłokę systemu
	mov	ax,	KERNEL_SERVICE_PROCESS_run
	mov	bl,	KERNEL_SERVICE_PROCESS_RUN_FLAG_out_to_in_parent	; przekieruj wyjście potomka na wejście rodzica
	mov	ecx,	console_shell_file_end - console_shell_file
	mov	rsi,	console_shell_file
	int	KERNEL_SERVICE
	jc	console.close	; nie udało się uruchomić procesu powłoki

	; wyświetl okno
	mov	al,	KERNEL_WM_WINDOW_update
	or	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush
	int	KERNEL_WM_IRQ

	; zachowaj PID powłoki
	mov	qword [console_shell_pid],	rcx
