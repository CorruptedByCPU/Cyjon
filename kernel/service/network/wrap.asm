;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rax - adres MAC odbiorcy
;	cx - typ protokołu
;	rdi - wskaźnik do przestrzeni pakietu do wysłania
service_network_ethernet_wrap:
	; zachowaj oryginalne rejestry
	push	rax

	; adres MAC odbiorcy
	mov	qword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.target],	rax

	; adres MAC nadawcy
	mov	rax,	qword [driver_nic_i82540em_mac_address]
	mov	qword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.source],	rax

	; typ protokołu
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.type],	cx

	; przywróć oryginalne rejestry
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"service_network_ethernet_wrap"

;===============================================================================
; wejście:
;	rax - adres MAC odbiorcy
;	bl - typ protokołu
;	cx - rozmiar danych w Bajtach
;	rsi - wskaźnik do właściwości połączenia
;	rdi - wskaźnik do przestrzeni pakietu do wysłania
service_network_ip_wrap:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rax

	; wersja IP
	mov	byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.version_and_ihl],	SERVICE_NETWORK_FRAME_IP_VERSION_4 | SERVICE_NETWORK_FRAME_IP_HEADER_LENGTH_default

	; wyczyść opcje niewykorzystywane
	mov	byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.dscp_and_ecn],	STATIC_EMPTY

	; ustaw rozmiar ramki IP
	add	cx,	SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE
	rol	cx,	STATIC_REPLACE_AL_WITH_HIGH_shift
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.total_length],	cx

	; ustaw identyfikator
	inc	word [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.identification]
	mov	ax,	word [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.identification]
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.identification],	ax

	; ustaw domyślne flagi
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.f_and_f],	SERVICE_NETWORK_FRAME_IP_F_AND_F_do_not_fragment

	; standardowy rozmiar TTL
	mov	byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.ttl],	SERVICE_NETWORK_FRAME_IP_TTL_default

	; typ protokołu
	mov	byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.protocol],	bl

	; wyczyść sumę kontrolną
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.checksum],	STATIC_EMPTY

	; ustaw nadawcę (ja)
	mov	eax,	dword [driver_nic_i82540em_ipv4_address]
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.source_address],	eax

	; ustaw adresata
	mov	eax,	dword [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_ipv4]
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.destination_address],	eax

	; ustaw sumę kontrolną ramki IP
	xor	eax,	eax
	mov	ecx,	SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE >> STATIC_DIVIDE_BY_2_shift
	add	rdi,	SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE
	call	service_network_checksum
	rol	ax,	STATIC_REPLACE_AL_WITH_HIGH_shift	; zamień na Big-Endian
	sub	rdi,	SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.checksum],	ax

	; spakuj ramkę IP
	pop	rax
	mov	cx,	SERVICE_NETWORK_FRAME_ETHERNET_TYPE_ip
	call	service_network_ethernet_wrap

	; przywróć oryginalne rejestry
	pop	rcx

	; powrót z procedury
	ret

	macro_debug	"service_network_ip_wrap"

;===============================================================================
; wejście:
;	bl - rozmiar nagłówka TCP
;	ecx - rozmiar ramki TCP w Bajtach
;	rsi - wskaźnik do właściwości połączenia
;	rdi - wskaźnik do przestrzeni pakietu do wysłania
service_network_tcp_wrap:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdi

	; ustaw port źródłowy(usługi) i docelowy
	mov	ax,	word [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.host_port]
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.port_source],	ax
	mov	ax,	word [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_port]
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.port_target],	ax

	; nasz numer sekwencji
	mov	eax,	dword [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.host_sequence]
	bswap	eax	; zamień na Big-Endian
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.sequence],	eax

	; numer sekwencji oczekiwany przez adresata
	mov	eax,	dword [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_sequence]
	bswap	eax	; zamień na Big-Endian
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.acknowledgement],	eax

	; rozmiar nagłówka ramki TCP
	mov	byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.header_length],	bl

	; zwróć aktualny stan flag
	mov	al,	byte [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags]
	mov	byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.flags],	al

	; rozmiar okna
	mov	ax,	word [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.window_size]
	rol	ax,	STATIC_REPLACE_AL_WITH_HIGH_shift	; zamień na Big-Endian
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.window_size],	ax

	; wyczyść sumę kontrolną i pole urgent pointer
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.checksum_and_urgent_pointer],	STATIC_EMPTY

	; konfiguruj pseudo nagłówek TCP
	call	service_network_tcp_pseudo_header

	; suma kontrolna ramki TCP
	shr	ecx,	STATIC_DIVIDE_BY_2_shift	; zamień na słowa
	add	rdi,	SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE
	call	service_network_checksum
	rol	ax,	STATIC_REPLACE_AL_WITH_HIGH_shift	; zamień na Big-Endian
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.checksum],	ax

	; spakuj dane ramki IP
	mov	rax,	qword [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_mac]
	mov	bl,	SERVICE_NETWORK_FRAME_IP_PROTOCOL_TCP
	shl	ecx,	STATIC_MULTIPLE_BY_2_shift	; zamień na Bajty
	sub	rdi,	SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE ; cofnij wskaźnik na przestrzeń pakietu do wysłania
	call	service_network_ip_wrap

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"service_network_tcp_wrap"
