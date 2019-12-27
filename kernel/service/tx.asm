;===============================================================================
; Copyright (C) by Andrzej Adamczyk at Blackend.dev
;===============================================================================

SERVICE_TX_CACHE_SIZE_page	equ	1

struc	SERVICE_TX_STRUCTURE_CACHE
	.size			resb	8
	.address		resb	8
	.SIZE:
endstruc

service_tx_pid			dq	STATIC_EMPTY

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

	; wiadomość od usługi sieciowej?
	mov	rbx,	qword [rdi + KERNEL_IPC_STRUCTURE_LIST.pid_source]
	cmp	rbx,	qword [service_network_pid]
	je	.send	; tak, przetwórz

	; pobierz adres przestrzeni
	call	library_page_from_size
	mov	rdi,	qword [rdi + KERNEL_IPC_STRUCTURE_LIST.pointer]
	call	kernel_memory_release

	; powrót do pętli głównej
	jmp	.loop

.send:
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
