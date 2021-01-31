;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	%include	"software/console/config.asm"
	;-----------------------------------------------------------------------

;===============================================================================
console:
	; inicjalizacja przestrzeni konsoli
	%include	"software/console/init.asm"

.loop:
	; uzupełnij strumień wejścia procesu o meta dane okna
	call	console_meta

	; zwolnij pozostały czas procesora
	mov	ax,	KERNEL_SERVICE_PROCESS_release
	int	KERNEL_SERVICE

	; proces powłoki jest uruchomiony?
	mov	ax,	KERNEL_SERVICE_PROCESS_check
	mov	rcx,	qword [console_shell_pid]
	int	KERNEL_SERVICE
	jnc	.exist	; tak

.close:
	; zakończ działanie konsoli
	xor	ax,	ax
	int	KERNEL_SERVICE

.exist:
	; sprawdź przychodzące zdarzenia
	mov	rsi,	console_window
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu_event
	jc	.input	; brak wyjątku związanego z klawiaturą

	; prześlij kod klawisza do powłoki
	call	console_transfer

.input:
	; pobierz ciąg z strumienia
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_in
	mov	ecx,	STATIC_EMPTY	; pobierz całą zawartość
	mov	rdi,	qword [console_cache_address]
	int	KERNEL_SERVICE
	jz	.loop	; brak danych

	; wyświetl zawartość
	xor	eax,	eax
	mov	rsi,	rdi

	; przywróć wskaźnik do struktury terminala
	mov	r8,	console_terminal_table

	; wyłącz kursor w terminalu
	macro_library	LIBRARY_STRUCTURE_ENTRY.terminal_cursor_disable

.parse:
	; koniec ciągu?
	test	rcx,	rcx
	jz	.flush	; tak

	; przetworzono sekwencje?
	call	console_sequence
	jnc	.parse	; tak

	; pobierz znak z ciągu
	lodsb

	; brak znaku?
	test	al,	al
	jz	.next	; tak

	; zachowaj licznik
	push	rcx

	; wyświetl znak
	mov	ecx,	1
	macro_library	LIBRARY_STRUCTURE_ENTRY.terminal_char

	; przywróć licznik
	pop	rcx

.next:
	; wyświetlić pozostałe znaki z ciągu?
	dec	rcx
	jnz	.parse	; tak

.flush:
	; włącz kursor w terminalu
	macro_library	LIBRARY_STRUCTURE_ENTRY.terminal_cursor_enable

	; aktualizuj zawartość okna
	mov	al,	KERNEL_WM_WINDOW_update
	mov	rsi,	console_window
	or	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush
	int	KERNEL_WM_IRQ

	; zatrzymaj dalsze wykonywanie kodu
	jmp	.loop

	macro_debug	"software: console"

	;-----------------------------------------------------------------------
	%include	"software/console/data.asm"
	%include	"software/console/transfer.asm"
	%include	"software/console/sequence.asm"
	%include	"software/console/meta.asm"
	;-----------------------------------------------------------------------
