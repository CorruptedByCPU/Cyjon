;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty, makra
	;-----------------------------------------------------------------------
	%include	"kernel/service/shell/config.asm"	; globalne
	;-----------------------------------------------------------------------

service_shell:
	; domyślnie, znak zachęty od nowej linii
	mov	ecx,	service_shell_string_prompt_end - service_shell_string_prompt_with_new_line
	mov	rsi,	service_shell_string_prompt_with_new_line

	; kursor znajduje się w pierwszej kolumnie?
	cmp	dword [kernel_video_cursor.x],	STATIC_EMPTY
	jne	.prompt	; nie

	; znak zachęty bez nowej linii
	mov	ecx,	service_shell_string_prompt_end - service_shell_string_prompt
	mov	rsi,	service_shell_string_prompt

.prompt:
	; wyświetl znak zachęty
	call	kernel_video_string

.restart:
	; zawartość bufora: pusty
	xor	ebx,	ebx

	; maksymalny rozmiar bufora
	mov	ecx,	SERVICE_SHELL_CACHE_SIZE_byte

	; ustaw wskaźnik na początek bufora
	mov	rsi,	service_shell_cache

	; pobierz polecenie
	call	library_input
	jc	service_shell	; bufor pusty lub przerwano wprowadzanie

	; usuń białe znaki z początku i końca bufora
	call	library_string_trim
	jc	service_shell	; bufor pusty lub przerwano wprowadzanie

	; znajdź nazwę polecenia
	call	library_string_word_next

	; przetwórz polecenie
	jmp	service_shell_prompt

	;-----------------------------------------------------------------------
	%include	"kernel/service/shell/data.asm"
	%include	"kernel/service/shell/prompt.asm"
	;-----------------------------------------------------------------------
