;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

;===============================================================================
console_transfer:
	; wyślij komunikat do powłoki
	mov	rax,	KERNEL_SERVICE_PROCESS_ipc_send
	mov	rbx,	qword [console_shell_pid]
	xor	ecx,	ecx	; domyślny rozmiar komunikatu
	mov	rsi,	console_ipc_data
	int	KERNEL_SERVICE

	; powrót z procedury
	ret
