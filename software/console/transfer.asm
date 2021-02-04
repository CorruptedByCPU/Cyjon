;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
console_transfer:
	; ustaw wskaźnik na komunikat
	mov	rsi,	console_ipc_data

	; typ komunikatu: klawiatura
	mov	byte [rsi + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_KEYBOARD

	; kod klawisza
	mov	word [rsi + KERNEL_IPC_STRUCTURE.data],	dx

	; wyślij komunikat do powłoki
	mov	rax,	KERNEL_SERVICE_PROCESS_ipc_send
	mov	rbx,	qword [console_shell_pid]
	xor	ecx,	ecx	; domyślny rozmiar komunikatu
	int	KERNEL_SERVICE

	; powrót z procedury
	ret
