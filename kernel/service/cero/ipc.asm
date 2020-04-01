;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
service_cero_ipc:
	; zachowaj oryginalne rejestry
	push	rax
	push	rsi
	push	rdi
	push	r8
	push	r9

	; pobierz wiadomość
	mov	rdi,	service_cero_ipc_data
	call	kernel_ipc_receive
	jc	.end	; brak wiadomości

	; wiadomość od menedżera okien?
	mov	rax,	qword [service_desu_pid]
	cmp	qword [rdi + KERNEL_IPC_STRUCTURE.pid_source],	rax
	jne	.no_desu	; nie, zignoruj

	call	service_cero_ipc_desu

.no_desu:

.end:
	; przywróć oryginalne rejestry
	pop	r9
	pop	r8
	pop	rdi
	pop	rsi
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"service_cero_ipc"

	;-----------------------------------------------------------------------
	%include	"kernel/service/cero/ipc/desu.asm"
	;-----------------------------------------------------------------------
