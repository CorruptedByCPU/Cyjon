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
	; brak obsługi

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rcx - PID procesu docelowego
shell_event_transfer:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi

	; prześlij komunikat do procesu potomnego
	mov	rax,	KERNEL_SERVICE_PROCESS_ipc_send
	mov	rbx,	rcx
	xor	ecx,	ecx	; domyślny rozmiar komunikatu
	mov	rsi,	shell_ipc_data
	int	KERNEL_SERVICE

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret
