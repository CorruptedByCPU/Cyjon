;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
console_window_close:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rdi

	; poinformuj proces potomny o konieczności zakończenia pracy
	mov	byte [console_ipc_data + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_SYSTEM
	mov	byte [console_ipc_data + KERNEL_IPC_STRUCTURE.data],	KERNEL_IPC_DATA_SYSTEM_kill
	call	console_transfer

.wait:
	; pobierz odpowiedź
	mov	ax,	KERNEL_SERVICE_PROCESS_ipc_receive
	mov	rdi,	console_ipc_data
	int	KERNEL_SERVICE
	jc	.wait	; brak wiadomości, czekaj dalej

	; komunikat od procesu potomnego?
	mov	rbx,	qword [console_shell_pid]
	cmp	qword [rdi + KERNEL_IPC_STRUCTURE.pid_source],	rbx
	jne	.wait	; nie, czekaj dalej

	; koniec procesu
	jmp	console.close

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rbx
	pop	rax

	; powrót z procedury
	ret
