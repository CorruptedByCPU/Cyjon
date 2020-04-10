;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
service_cero_event_console:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi

	; uruchom program "Console"
	mov	ecx,	kernel_init_vfs_files.console_end - kernel_init_vfs_files.console
	mov	rsi,	kernel_init_vfs_files.console
	call	kernel_vfs_path_resolve
	call	kernel_vfs_file_find
	call	kernel_exec

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx

	; powrót z procedury obsługi akcji
	ret
