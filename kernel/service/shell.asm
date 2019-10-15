;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

service_shell:
	; wyświetl znak zachęty
	mov	ecx,	service_shell_string_prompt_end - service_shell_string_prompt
	mov	rsi,	service_shell_string_prompt
	call	kernel_video_string

.read_key:
	; pobierz znak z bufora klawiatury
	call	driver_ps2_keyboard_read
	jz	.read_key

	; znak drukowalny?
	cmp	ax,	STATIC_ASCII_SPACE
	jb	.read_key	; nie
	cmp	ax,	STATIC_ASCII_TILDE
	ja	.read_key	; nie

	; wyświetl znak z bufora na ekran
	mov	ecx,	0x01	; jedna kopia
	call	kernel_video_char

	; wróć do głównej pętli
	jmp	.read_key

	;-----------------------------------------------------------------------
	%include	"kernel/service/shell/data.asm"
	;-----------------------------------------------------------------------
