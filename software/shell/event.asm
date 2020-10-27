;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rdi - wskaźnik do komunikatu
shell_event:
	; koniec pracy?
	call	shell_event_close
	jnc	.end	; nie

	; odpowiedz twierdząco
	mov	ax,	KERNEL_SERVICE_PROCESS_ipc_send_to_parent
	xor	ecx,	ecx	; domyślny rozmiar komunikatu
	mov	rsi,	shell_ipc_data
	int	KERNEL_SERVICE

	; zakończ pracę
	xor	ax,	ax
	int	KERNEL_SERVICE

.end:
	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rdi - wskaźnik do komunikatu
; wyjście:
;	Flaga CF - jeśli koniec pracy
shell_event_close:
	; zachowaj oryginalne rejestry
	push	rax

	; komunikat od rodzica?
	mov	rax,	qword [rdi + KERNEL_IPC_STRUCTURE.pid_source]
	cmp	rax,	qword [shell_pid_parent]
	jne	.end	; nie, zignoruj

	; rodzic przesyła komunikat systemowy?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.type],	KERNEL_IPC_TYPE_SYSTEM
	jne	.end	; nie, brak obsługi

	; koniec pracy rodzica?
	cmp	qword [rdi + KERNEL_IPC_STRUCTURE.data],	KERNEL_IPC_DATA_SYSTEM_kill
	jne	.end	; nie, brak obsługi

	; koniec pracy rodzica
	stc

.end:
	; przywróć oryginalne rejestry
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rcx - PID procesu docelowego
shell_event_transfer:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdi
	push	rsi

	; pobierz wiadomość
	mov	ax,	KERNEL_SERVICE_PROCESS_ipc_receive
	mov	rdi,	shell_ipc_data
	int	KERNEL_SERVICE
	jc	.end	; brak wiadomości

	; koniec pracy?
	call	shell_event_close
	jnc	.transfer	; nie

	; debug
	xchg	bx,bx

.transfer:
	; prześlij komunikat do powłoki
	mov	rax,	KERNEL_SERVICE_PROCESS_ipc_send_to_parent
	xor	ecx,	ecx	; domyślny rozmiar komunikatu
	mov	rsi,	shell_ipc_data
	int	KERNEL_SERVICE

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret
