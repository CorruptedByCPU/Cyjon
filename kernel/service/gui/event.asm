;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

;===============================================================================
kernel_gui_event_console:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rsi

	; uruchom program "Console"
	mov	ax,	KERNEL_SERVICE_PROCESS_run
	mov	ebx,	KERNEL_SERVICE_PROCESS_RUN_FLAG_default
	mov	ecx,	kernel_gui_event_console_file_end - kernel_gui_event_console_file
	mov	rsi,	kernel_gui_event_console_file
	int	KERNEL_SERVICE

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rbx

	; powrót z procedury obsługi akcji
	ret
