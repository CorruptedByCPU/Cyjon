;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
kernel_init_font:
	; wyświetl typ nazwę wykorzystanej czcionki
	mov	ecx,	kernel_init_string_video_font_end - kernel_init_string_video_font
	mov	rsi,	kernel_init_string_video_font
	call	kernel_video_string
	mov	ecx,	kernel_font_string_name_end - kernel_font_string_name
	mov	rsi,	kernel_font_string_name
	call	kernel_video_string

	; przesuń kursor do nowej linii
	mov	eax,	STATIC_ASCII_NEW_LINE
	mov	ecx,	1
	call	kernel_video_char
