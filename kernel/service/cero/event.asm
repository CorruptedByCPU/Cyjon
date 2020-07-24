;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

;===============================================================================
service_cero_event_console:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi

	; uruchom program "Console"
	mov	ax,	KERNEL_SERVICE_PROCESS_run
	mov	ecx,	service_cero_event_console_file_end - service_cero_event_console_file
	mov	rsi,	service_cero_event_console_file
	int	KERNEL_SERVICE

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx

	; powrót z procedury obsługi akcji
	ret
