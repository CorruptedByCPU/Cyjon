;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
service_cero_event_console:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi

	; uruchom program "Console"
	mov	ecx,	service_cero_event_console_file_end - service_cero_event_console_file
	mov	rsi,	service_cero_event_console_file
	call	kernel_vfs_path_resolve
	call	kernel_vfs_file_find
	call	kernel_exec

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx

	; powrót z procedury obsługi akcji
	ret
