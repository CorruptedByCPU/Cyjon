;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

kernel_debug_string_welcome	db	STATIC_COLOR_ASCII_MAGENTA_LIGHT, "Press ESC key to enter GOD mode.", STATIC_ASCII_NEW_LINE
kernel_debug_string_welcome_end:

;===============================================================================
; wejście:
;	WSZYSTKO :)
kernel_debug:
	; zachowaj wszystkie rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	rbp
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15

	; włącz spowrotem przerwania
	sti

	; wyświetl informacje
	mov	ecx,	kernel_debug_string_welcome_end - kernel_debug_string_welcome
	mov	rsi,	kernel_debug_string_welcome
	call	kernel_video_string

.any:
	; pobierz klawisz z bufora klawiatury
	call	driver_ps2_keyboard_read
	jz	.any	; brak, sprawdź raz jeszcze

	; klawisz ESC?
	cmp	ax,	STATIC_ASCII_ESCAPE
	jne	.any	; nie, czekaj dalej

	; wyczyść przestrzeń konsoli
	call	kernel_video_drain

	jmp	$

	macro_debug	"kernel_debug"
