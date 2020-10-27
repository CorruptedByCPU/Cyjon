;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	%include	"kernel/service/network/config.asm"
	%include	"kernel/service/network/data.asm"
	%include	"kernel/service/network/checksum.asm"
	%include	"kernel/service/network/arp.asm"
	%include	"kernel/service/network/icmp.asm"
	%include	"kernel/service/network/tcp.asm"
	;-----------------------------------------------------------------------

;===============================================================================
service_network:
	; upewnij się by nie korzystać z stron zarezerwowanych
	xor	ebp,	ebp

	; pobierz własny PID
	call	kernel_task_active
	mov	rax,	qword [rdi + KERNEL_TASK_STRUCTURE.pid]

	; zachowaj informacje o własnym PID dla pozostałych procesów
	mov	qword [service_network_pid],	rax

.loop:
	; pobierz wiadomość do nas
	mov	rdi,	service_network_ipc_message
	call	kernel_ipc_receive
	jc	.loop	; brak, sprawdź raz jeszcze

	; pobierz rozmiar i wskaźnik do przestrzeni
	mov	rcx,	qword [rdi + KERNEL_IPC_STRUCTURE.size]
	mov	rsi,	qword [rdi + KERNEL_IPC_STRUCTURE.pointer]

	; protokół ARP?
	cmp	word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.type],	SERVICE_NETWORK_FRAME_ETHERNET_TYPE_arp
	je	service_network_arp	; tak

	; protokół IP?
	cmp	word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.type],	SERVICE_NETWORK_FRAME_ETHERNET_TYPE_ip
	je	service_network_ip	; tak

	; protokół nieobsługiwany
	xchg	bx,bx

.end:
	; przestrzeń pakietu została przekazana do innego procesu?
	test	rsi,	rsi
	jz	.loop	; tak

	; zwolnij przestrzeń danych pakietu
	mov	rdi,	rsi
	call	kernel_memory_release_page

	; powrót do pętli głównej
	jmp	.loop

	macro_debug	"service_network"

;===============================================================================
; wejście:
;	rsi - wskaźnik do pakietu przychodzącego
service_network_ip:
	; protokół ICMP?
	cmp	byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.protocol],	SERVICE_NETWORK_FRAME_IP_PROTOCOL_ICMP
	je	service_network_icmp	; tak

	; protokół TCP?
	cmp	byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.protocol],	SERVICE_NETWORK_FRAME_IP_PROTOCOL_TCP
	je	service_network_tcp	; tak

.end:
	; powrót z procedury
	jmp	service_network.end

	macro_debug	"service_network_ip"

;===============================================================================
; wejście:
;	rax - rozmiar pakietu w Bajtach
;	rdi - wskaźnik do przestrzeni padanych pakietu
; wyjście:
;	Flaga CF, jeśli nie udało się wysłać
service_network_transfer:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rsi

	; usługa wysyłania danych przez interfejs sieciowy gotowa?
	mov	rbx,	qword [service_tx_pid]
	test	rbx,	rbx
	jz	.error	; usługa nie gotowa

	; rejestry na swoje miejsce
	mov	rcx,	rax
	mov	rsi,	rdi
	call	kernel_ipc_insert
	jnc	.end	; wysłano wiadomość

.error:
	; flaga, błąd
	stc

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rbx

	; powrót z procedury
	ret
