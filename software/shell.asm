;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty, makra
	;-----------------------------------------------------------------------
	%include	"config.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/config.asm"
	%include	"kernel/header/stream.inc"
	%include	"kernel/header/service.inc"
	%include	"kernel/header/ipc.inc"
	%include	"kernel/header/wm.inc"
	%include	"kernel/macro/debug.asm"
	;-----------------------------------------------------------------------
	%include	"software/console/header.inc"
	;-----------------------------------------------------------------------
	%include	"software/shell/config.asm"
	;-----------------------------------------------------------------------

; 64 bitowy kod programu
[bits 64]

; adresowanie względne
[default rel]

; położenie kodu programu w pamięci logicznej
[org SOFTWARE_base_address]

;===============================================================================
shell:
	; pobierz PID rodzica
	mov	ax,	KERNEL_SERVICE_PROCESS_pid_parent
	int	KERNEL_SERVICE

	; zachowaj PID rodzica
	mov	qword [shell_pid_parent],	rcx

.restart:
	; pobierz informacje o strumieniu wyjścia
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_meta
	mov	bl,	KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_get | KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_out
	mov	ecx,	CONSOLE_STRUCTURE_STREAM_META.SIZE
	mov	rdi,	shell_stream_meta
	int	KERNEL_SERVICE
	jc	shell.restart	; brak aktualnych informacji

	; domyślnie, znak zachęty od nowej linii
 	mov	ecx,	shell_string_prompt_end - shell_string_prompt_with_new_line
 	mov	rsi,	shell_string_prompt_with_new_line

	; kursor znajduje się w pierwszej kolumnie?
	cmp	word [rdi + CONSOLE_STRUCTURE_STREAM_META.x],	STATIC_EMPTY
	jne	.prompt	; nie

.prompt_no_new_line:
	; znak zachęty bez nowej linii
 	mov	ecx,	shell_string_prompt_end - shell_string_prompt
 	mov	rsi,	shell_string_prompt

.prompt:
	; wyświetl znak zachęty
 	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
 	int	KERNEL_SERVICE

	; zawartość bufora: pusty
	xor	ebx,	ebx

	; maksymalny rozmiar bufora
	mov	ecx,	SHELL_CACHE_SIZE_byte

	; ustaw wskaźnik na początek bufora
	mov	rsi,	shell_cache

.continue:
	; pobierz polecenie
	mov	rbx,	SHELL_CACHE_SIZE_byte
	xor	ecx,	ecx	; bufor pusty
	mov	rdx,	shell_event
	mov	rsi,	shell_cache
	mov	rdi,	shell_ipc_data
	call	library_input
	jc	shell.restart	; bufor pusty lub przerwano wprowadzanie

	; usuń białe znaki z początku i końca bufora
	call	library_string_trim
	jc	shell.restart	; bufor pusty lub przerwano wprowadzanie

	; zachowaj rozmiar zawarości bufora
	push	rcx

	; zawartość bufora na początku?
	cmp	rsi,	shell_cache
	je	.begin	; tak

	; przesuń zawartość bufora na początek
	mov	rdi,	shell_cache
	rep	movsb

.begin:
	; przywróć rozmiar zawartości bufora
	pop	rcx

	; znajdź nazwę polecenia
	xor	bl,	bl	; brak specjalnego separatora
	mov	rsi,	shell_cache
	call	library_string_word_next

	; przetwórz polecenie
	jmp	shell_prompt

	macro_debug	"shell"

	;-----------------------------------------------------------------------
	%include	"software/shell/data.asm"
	%include	"software/shell/prompt.asm"
	%include	"software/shell/event.asm"
	;-----------------------------------------------------------------------
	%include	"library/input.asm"
	%include	"library/string_trim.asm"
	%include	"library/string_word_next.asm"
	%include	"library/string_compare.asm"
	;-----------------------------------------------------------------------
