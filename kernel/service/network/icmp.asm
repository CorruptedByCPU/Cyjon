;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rsi - wskaźnik do pakietu przychodzącego
service_network_icmp:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	rdi

	; zapytanie?
	cmp	byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.type],	SERVICE_NETWORK_FRAME_ICMP_TYPE_REQUEST
	jne	.end	; nie, brak obsługi

	; rozmiar nagłówka ramki IP
	movzx	ebx,	byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.version_and_ihl]
	and	bl,	SERVICE_NETWORK_FRAME_IP_HEADER_LENGTH_mask
	shl	bl,	STATIC_MULTIPLE_BY_4_shift

	; przygotuj przestrzeń pod odpowiedź
	call	kernel_memory_alloc_page
	jc	.end	; brak wolnego miejsca, nie odpowiadaj

	; wypełnij ramki domyślnymi wartościami
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.type],	SERVICE_NETWORK_FRAME_ETHERNET_TYPE_ip
	mov	byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.version_and_ihl],	SERVICE_NETWORK_FRAME_IP_HEADER_LENGTH_default | SERVICE_NETWORK_FRAME_IP_VERSION_4
	mov	byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.dscp_and_ecn],	STATIC_EMPTY
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.total_length],	(SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.SIZE >> STATIC_REPLACE_AL_WITH_HIGH_shift) | (SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.SIZE << STATIC_REPLACE_AL_WITH_HIGH_shift)
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.identification],	STATIC_EMPTY
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.f_and_f],	STATIC_EMPTY
	mov	byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.ttl],	SERVICE_NETWORK_FRAME_IP_TTL_default
	mov	byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.protocol],	SERVICE_NETWORK_FRAME_IP_PROTOCOL_ICMP
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.type],	SERVICE_NETWORK_FRAME_ICMP_TYPE_REPLY
	mov	byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.code],	STATIC_EMPTY
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.reserved],	STATIC_EMPTY

	; przesuń wskaźnik na ramkę ICMP
	add	rdi,	SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE

	; zwróć identyfikator i sekwencję
	mov	eax,	dword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.reserved]
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.reserved],	eax

	; wyczyść starą sumę kontrolną ramki ICMP
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.checksum],	STATIC_EMPTY

	; zachowaj wskaźniki
	push	rsi
	push	rdi

	; zwróć dane ramki ICMP klienta
	mov	ecx,	SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.SIZE - SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.data
	add	rsi,	SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.data
	add	rdi,	SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.data
	rep	movsb

	; przywróć wskaźniki
	pop	rdi
	pop	rsi

	;-----------------------------------------------------------------------
	; wylicz sumę kontrolną
	xor	eax,	eax
	mov	ecx,	SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.SIZE >> STATIC_DIVIDE_BY_2_shift
	call	service_network_checksum

	; ustaw sumę kontrolną ramki ICMP
	rol	ax,	STATIC_REPLACE_AL_WITH_HIGH_shift	; Big-Endian
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.checksum],	ax

	; przesuń wskaźnik na ramkę IPv4
	sub	rdi,	SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE

	; ustaw docelowy adres IPv4
	mov	eax,	dword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.source_address]
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_IP.destination_address],	eax

	; zwróć nasz adres IPv4
	mov	eax,	dword [driver_nic_i82540em_ipv4_address]
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_IP.source_address],	eax

	; wyczyść starą sumę kontrolną ramki IPv4
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_IP.checksum],	STATIC_EMPTY

	; wylicz sumę kontrolną ------------------------------------------------
	xor	eax,	eax
	mov	ecx,	(SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.SIZE) >> STATIC_DIVIDE_BY_2_shift
	call	service_network_checksum
	rol	ax,	STATIC_REPLACE_AL_WITH_HIGH_shift	; Big-Endian
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_IP.checksum],	ax

	; spakuj ramkę IP
	sub	rdi,	SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE
	mov	rax,	qword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.source]
	mov	cx,	SERVICE_NETWORK_FRAME_ETHERNET_TYPE_ip
	call	service_network_ethernet_wrap

	; wyślij odpowiedź -----------------------------------------------------
	mov	eax,	SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ICMP.SIZE
	call	service_network_transfer

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	jmp	service_network_ip.end

	macro_debug	"service_network_icmp"
