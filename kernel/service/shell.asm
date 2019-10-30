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

	; zresetuj wskaźnik bufora polecenia i ilość znaków w nim
	mov	rdi,	service_shell_cache

.reset:
	; zawartość bufora: pusty
	xor	ebx,	ebx

.read_key:
	; pobierz znak z bufora klawiatury
	call	driver_ps2_keyboard_read
	jz	.read_key

	; znak "Backspace"?
	cmp	ax,	STATIC_ASCII_BACKSPACE
	jne	.no_backspace	; nie

	; bufor pusty?
	dec	bx
	js	.reset	; tak

	; cofnij wskaźnik
	dec	rdi

	; wyświetl "Backspace"
	jmp	.show

.no_backspace:
	; znak "Enter"?
	cmp	ax,	STATIC_ASCII_ENTER
	je	service_shell	; restart znaku zachęty

	; znak drukowalny?
	cmp	ax,	STATIC_ASCII_SPACE
	jb	.read_key	; nie
	cmp	ax,	STATIC_ASCII_TILDE
	ja	.read_key	; nie

	; bufor pełny?
	cmp	bx,	SERVICE_SHELL_CACHE_SIZE_byte
	je	.read_key	; tak, zignoruj klawisz

	; ilość znaków w buforze
	inc	bx

.show:
	; wyświetl znak z bufora na ekran
	mov	ecx,	0x01	; jedna kopia
	call	kernel_video_char

	; wróć do głównej pętli
	jmp	.read_key

	;-----------------------------------------------------------------------
	%include	"kernel/service/shell/data.asm"
	;-----------------------------------------------------------------------
