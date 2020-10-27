;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
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
