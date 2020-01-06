;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

service_tx_pid					dq	STATIC_EMPTY

service_tx_ipc_message:
	times	KERNEL_IPC_STRUCTURE_LIST.SIZE	db	STATIC_EMPTY

;===============================================================================
service_tx:
	; pobierz własny PID
	call	kernel_task_active
	mov	rax,	qword [rdi + KERNEL_STRUCTURE_TASK.pid]

	; udostepnij własny PID dla pozostałych procesów
	mov	qword [service_tx_pid],	rax

.loop:
	; pobierz wiadomość
	mov	rdi,	service_tx_ipc_message
	call	kernel_ipc_receive
	jc	.loop	; brak, sprawdź raz jeszcze

	; pobierz rozmiar danych pakietu
	mov	rcx,	qword [rdi + KERNEL_IPC_STRUCTURE_LIST.size]

	; brak danych?
	test	rcx,	rcx
	jz	.loop	; tak, zignoruj

 	; wyślij
 	mov	rax,	rcx
 	mov	rdi,	qword [rdi + KERNEL_IPC_STRUCTURE_LIST.pointer]
 	call	driver_nic_i82540em_transfer

	; zwolnij przesterzeń
	call	library_page_from_size
	call	kernel_memory_release

	; powrót do pętli głównej
	jmp	.loop

	macro_debug	"service_tx"
