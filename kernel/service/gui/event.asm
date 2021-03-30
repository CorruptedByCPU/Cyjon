;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
kernel_gui_event_console:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rsi

	; uruchom program "Console"
	mov	ax,	KERNEL_SERVICE_PROCESS_run
	mov	ebx,	KERNEL_SERVICE_PROCESS_RUN_FLAG_out_default
	mov	ecx,	kernel_gui_event_console_file_end - kernel_gui_event_console_file
	mov	rsi,	kernel_gui_event_console_file
	xor	r8,	r8	; brak przesyłanych argumentów
	int	KERNEL_SERVICE

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rbx

	; powrót z procedury obsługi akcji
	ret

	macro_debug	"kernel_gui_event_console"

;===============================================================================
kernel_gui_event_soler:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rsi

	; uruchom program "Console"
	mov	ax,	KERNEL_SERVICE_PROCESS_run
	mov	ebx,	KERNEL_SERVICE_PROCESS_RUN_FLAG_out_default
	mov	ecx,	kernel_gui_event_soler_file_end - kernel_gui_event_soler_file
	mov	rsi,	kernel_gui_event_soler_file
	xor	r8,	r8	; brak przesyłanych argumentów
	int	KERNEL_SERVICE

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rbx

	; powrót z procedury obsługi akcji
	ret

	macro_debug	"kernel_gui_event_soler"

;===============================================================================
kernel_gui_event_taris:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rsi

	; uruchom program "Taris"
	mov	ax,	KERNEL_SERVICE_PROCESS_run
	mov	ebx,	KERNEL_SERVICE_PROCESS_RUN_FLAG_out_default
	mov	ecx,	kernel_gui_event_taris_file_end - kernel_gui_event_taris_file
	mov	rsi,	kernel_gui_event_taris_file
	xor	r8,	r8	; brak przesyłanych argumentów
	int	KERNEL_SERVICE

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rbx

	; powrót z procedury obsługi akcji
	ret

	macro_debug	"kernel_gui_event_taris"

;===============================================================================
kernel_gui_event_mural:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rsi

	; uruchom program "Mural"
	mov	ax,	KERNEL_SERVICE_PROCESS_run
	mov	ebx,	KERNEL_SERVICE_PROCESS_RUN_FLAG_out_default
	mov	ecx,	kernel_gui_event_mural_file_end - kernel_gui_event_mural_file
	mov	rsi,	kernel_gui_event_mural_file
	xor	r8,	r8	; brak przesyłanych argumentów
	int	KERNEL_SERVICE

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rbx

	; powrót z procedury obsługi akcji
	ret

	macro_debug	"kernel_gui_event_mural"
