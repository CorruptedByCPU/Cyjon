;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty, makra
	;-----------------------------------------------------------------------
	%include	"config.asm"
	%include	"kernel/config.asm"
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
 	; wyślij do rodzica zapytanie o właściwości przestrzeni znakowej
	mov	ax,	KERNEL_SERVICE_PROCESS_ipc_send_to_parent
	mov	rsi,	shell_ipc_data
	mov	byte [rsi + KERNEL_IPC_STRUCTURE.data],	KERNEL_IPC_TYPE_GRAPHICS
 	int	KERNEL_SERVICE

.answer:
	; odbierz odpowiedź
	mov	ax,	KERNEL_SERVICE_PROCESS_ipc_receive
	mov	rdi,	rsi
	int	KERNEL_SERVICE
	jc	.answer	; brak odpowiedzi

	jmp	$

	; domyślnie, znak zachęty od nowej linii
 	mov	ecx,	shell_string_prompt_end - shell_string_prompt_with_new_line
 	mov	rsi,	shell_string_prompt_with_new_line

; 	; kursor znajduje się w pierwszej kolumnie?
; 	cmp	ebx,	STATIC_EMPTY
; 	jne	.prompt	; nie
;
; 	; znak zachęty bez nowej linii
; 	mov	ecx,	shell_string_prompt_end - shell_string_prompt
; 	mov	rsi,	shell_string_prompt
;
; .prompt:
; 	; wyświetl znak zachęty
; 	mov	ax,	KERNEL_SERVICE_VIDEO_string
; 	int	KERNEL_SERVICE
;
; .restart:
; 	; zawartość bufora: pusty
; 	xor	ebx,	ebx
;
; 	; maksymalny rozmiar bufora
; 	mov	ecx,	SHELL_CACHE_SIZE_byte
;
; 	; ustaw wskaźnik na początek bufora
; 	mov	rsi,	shell_cache
;
; 	; pobierz polecenie
; 	call	library_input
; 	jc	shell	; bufor pusty lub przerwano wprowadzanie
;
; 	; usuń białe znaki z początku i końca bufora
; 	call	library_string_trim
; 	jc	shell	; bufor pusty lub przerwano wprowadzanie
;
; 	; zachowaj rozmiar zawarości bufora
; 	push	rcx
;
; 	; zawartość bufora na początku?
; 	cmp	rsi,	shell_cache
; 	je	.begin	; tak
;
; 	; przesuń zawartość bufora na początek
; 	mov	rdi,	shell_cache
; 	rep	movsb
;
; .begin:
; 	; przywróć rozmiar zawartości bufora
; 	pop	rcx
;
; 	; znajdź nazwę polecenia
; 	mov	rsi,	shell_cache
; 	call	library_string_word_next
;
; 	; przetwórz polecenie
; 	jmp	shell_prompt
;
	;-----------------------------------------------------------------------
	%include	"software/shell/data.asm"
; 	%include	"software/shell/prompt.asm"
	;-----------------------------------------------------------------------
; 	%include	"library/input.asm"
; 	%include	"library/string_trim.asm"
; 	%include	"library/string_word_next.asm"
; 	%include	"library/string_compare.asm"
	;-----------------------------------------------------------------------
