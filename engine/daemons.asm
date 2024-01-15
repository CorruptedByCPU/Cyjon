;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; 64 Bitowy kod programu
[BITS 64]

; procedura zostanie usunięta z pamięci po wykonaniu
daemons:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdx
	push	rdi

	; ustaw wskaźnik do tablicy demonów
	mov	rdi,	table_daemon

.run:
	; sprawdź czy koniec listy demonów do uruchomienia
	cmp	qword [rdi],	VARIABLE_EMPTY
	je	.end

	; ilość znaków w nazwie demona
	mov	rcx,	qword [rdi]
	; adres procedury demona
	mov	rdx,	qword [rdi + VARIABLE_QWORD_SIZE]
	; wskaźnik do nazwy demona
	mov	rsi,	qword [rdi + VARIABLE_QWORD_SIZE * 2]

	; uruchom
	call	cyjon_process_init_daemon

	; następny rekord w tablicy
	add	rdi,	VARIABLE_QWORD_SIZE * 3
	jmp	.run

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rdx
	pop	rcx

	; powrót z procedury
	ret

table_daemon:
	dq	VARIABLE_DAEMON_GARBAGE_COLLECTOR_NAME_COUNT
	dq	daemon_garbage_collector
	dq	variable_daemon_garbage_collector_name

	dq	VARIABLE_DAEMON_NETWORK_LOOPBACK_NAME_COUNT
	dq	daemon_network_loopback
	dq	variable_daemon_network_loopback_name

	dq	VARIABLE_DAEMON_ETHERNET_NAME_COUNT
	dq	daemon_ethernet
	dq	variable_daemon_ethernet_name

	dq	VARIABLE_DAEMON_TCP_IP_STACK_NAME_COUNT
	dq	daemon_tcp_ip_stack
	dq	variable_daemon_tcp_ip_stack_name

	dq	VARIABLE_DAEMON_IDE_IO_NAME_COUNT
	dq	daemon_ide_io
	dq	variable_daemon_ide_io_name

	; koniec rekordów
	dq	VARIABLE_EMPTY
