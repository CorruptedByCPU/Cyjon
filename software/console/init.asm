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
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu
	jc	console.close	; brak wystarczającej przestrzeni pamięci

	; uzupełnij tablicę "terminal" o adres przestrzeni
	mov	rax,	qword [console_window.element_terminal + LIBRARY_BOSU_STRUCTURE_ELEMENT_DRAW.address]
	mov	qword [console_terminal_properties + LIBRARY_TERMINAL_STRUCTURE.address],	rax

	; uzupełnij tablicę "terminal" o scanline okna
	mov	eax,	dword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.scanline_byte]
	mov	qword [console_terminal_properties + LIBRARY_TERMINAL_STRUCTURE.scanline_byte],	rax

	; inicjalizuj przestrzeń elementu "terminal"
	mov	r8,	console_terminal_properties
	macro_library	LIBRARY_STRUCTURE_ENTRY.terminal

	; pobierz rozmiar listy argumentów przesłanych do procesu
	pop	rcx

	; przesłano argumenty do procesu?
	test	rcx,	rcx
	jz	.shell	; nie

	; ustaw wskaźnik na listę argumentów
	mov	rsi,	rsp

	; usuń z początku i końca listy wszystkie białe znaki
	macro_library	LIBRARY_STRUCTURE_ENTRY.string_trim
	jnc	.run	; uruchom przekazany program

.shell:
	; nie przekazano argumentów - uruchom domyślnie powłokę systemu
	mov	ecx,	console_shell_file_end - console_shell_file
	mov	rsi,	console_shell_file

.run:
	; uruchom powłokę systemu
	mov	ax,	KERNEL_SERVICE_PROCESS_run
	mov	bl,	KERNEL_SERVICE_PROCESS_RUN_FLAG_out_to_in_parent	; przekieruj wyjście potomka na wejście rodzica
	xor	r8,	r8	; brak przesyłanych argumentów
	int	KERNEL_SERVICE
	jc	console.close	; nie udało się uruchomić procesu powłoki

	; zachowaj PID uruchomionego procesu w konsoli
	mov	qword [console_process_pid],	rcx

	; wyświetl okno
	mov	al,	KERNEL_WM_WINDOW_update
	or	qword [console_window + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush
	int	KERNEL_WM_IRQ
