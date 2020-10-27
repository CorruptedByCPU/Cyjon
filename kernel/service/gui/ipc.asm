;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
kernel_gui_ipc:
	; zachowaj oryginalne rejestry
	push	rax
	push	rsi
	push	rdi
	push	r8
	push	r9

	; pobierz wiadomość
	mov	rdi,	kernel_gui_ipc_data
	call	kernel_ipc_receive
	jc	.end	; brak wiadomości

	; wiadomość od menedżera okien?
	mov	rax,	qword [kernel_wm_pid]
	cmp	qword [rdi + KERNEL_IPC_STRUCTURE.pid_source],	rax
	jne	.no_desu	; nie, zignoruj

	; obsłuż komunikat
	call	kernel_gui_ipc_wm

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

	macro_debug	"kernel_gui_ipc"

	;-----------------------------------------------------------------------
	%include	"kernel/service/gui/ipc/wm.asm"
	;-----------------------------------------------------------------------
