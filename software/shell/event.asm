;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

;===============================================================================
shell_event:
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

	; prześlij komunikat do powłoki
	mov	rax,	KERNEL_SERVICE_PROCESS_ipc_send
	mov	rbx,	rcx
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
