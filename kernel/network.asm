;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

KERNEL_NETWORK_MAC_mask				equ	0x0000FFFFFFFFFFFF

KERNEL_NETWORK_PORT_SIZE_page			equ	0x01	; tablica przechowująca stan portów
KERNEL_NETWORK_PORT_FLAG_empty			equ	0x00
KERNEL_NETWORK_PORT_FLAG_ready			equ	0x01

KERNEL_NETWORK_STACK_SIZE_page			equ	0x01	; ilość stron przeznaczonych na stos
KERNEL_NETWORK_STACK_FLAG_busy			equ	10000000b

KERNEL_NETWORK_FRAME_ETHERNET_TYPE_arp		equ	0x0608	; 0x0806
KERNEL_NETWORK_FRAME_ETHERNET_TYPE_ip		equ	0x0008	; 0x0800

KERNEL_NETWORK_FRAME_ARP_HTYPE_ethernet		equ	0x0100	; 0x0001
KERNEL_NETWORK_FRAME_ARP_PTYPE_ipv4		equ	0x0008	; 0x0800
KERNEL_NETWORK_FRAME_ARP_HAL_mac		equ	0x06	; xx:xx:xx:xx:xx:xx
KERNEL_NETWORK_FRAME_ARP_PAL_ipv4		equ	0x04	; x.x.x.x
KERNEL_NETWORK_FRAME_ARP_OPCODE_request		equ	0x0100
KERNEL_NETWORK_FRAME_ARP_OPCODE_answer		equ	0x0200

KERNEL_NETWORK_FRAME_IP_HEADER_LENGTH_default	equ	0x05
KERNEL_NETWORK_FRAME_IP_HEADER_LENGTH_mask	equ	0x0F
KERNEL_NETWORK_FRAME_IP_VERSION_mask		equ	0xF0
KERNEL_NETWORK_FRAME_IP_VERSION_4		equ	0x40
KERNEL_NETWORK_FRAME_IP_PROTOCOL_ICMP		equ	0x01
KERNEL_NETWORK_FRAME_IP_PROTOCOL_TCP		equ	0x06
KERNEL_NETWORK_FRAME_IP_PROTOCOL_UDP		equ	0x11
KERNEL_NETWORK_FRAME_IP_TTL_default		equ	0x40
KERNEL_NETWORK_FRAME_IP_F_AND_F_do_not_fragment	equ	0x0040

KERNEL_NETWORK_FRAME_ICMP_TYPE_REQUEST		equ	0x08
KERNEL_NETWORK_FRAME_ICMP_TYPE_REPLY		equ	0x00

KERNEL_NETWORK_FRAME_TCP_OPTION_MSS_default	equ	0xB4050402	; Big-Endian
KERNEL_NETWORK_FRAME_TCP_WINDOW_SIZE_default	equ	0x05B4	; Little-Endian
KERNEL_NETWORK_FRAME_TCP_PROTOCOL_default	equ	0x06

KERNEL_NETWORK_FRAME_TCP_HEADER_LENGTH_default	equ	0x40	; 8 * 0x04 = 20 Bajtów
KERNEL_NETWORK_FRAME_TCP_FLAGS_fin		equ	0000000000000001b
KERNEL_NETWORK_FRAME_TCP_FLAGS_syn		equ	0000000000000010b
KERNEL_NETWORK_FRAME_TCP_FLAGS_rst		equ	0000000000000100b
KERNEL_NETWORK_FRAME_TCP_FLAGS_psh		equ	0000000000001000b
KERNEL_NETWORK_FRAME_TCP_FLAGS_ack		equ	0000000000010000b
KERNEL_NETWORK_FRAME_TCP_FLAGS_urg		equ	0000000000100000b
KERNEL_NETWORK_FRAME_TCP_FLAGS_bsy		equ	0000100000000000b	; flaga prywatna
KERNEL_NETWORK_FRAME_TCP_FLAGS_bsy_bit		equ	11
KERNEL_NETWORK_FRAME_TCP_OPTION_MSS_default	equ	0xB4050402	; Big-Endian
KERNEL_NETWORK_FRAME_TCP_OPTION_KIND_mss	equ	0x02	; Max Segment Size
KERNEL_NETWORK_FRAME_TCP_WINDOW_SIZE_default	equ	0x05B4	; Little-Endian


struc	KERNEL_NETWORK_STRUCTURE_MAC
	.0					resb	1
	.1					resb	1
	.2					resb	1
	.3					resb	1
	.4					resb	1
	.5					resb	1
	.SIZE:
endstruc

struc	KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET
	.target					resb	0x06
	.source					resb	0x06
	.type					resb	0x02
	.SIZE:
endstruc

struc	KERNEL_NETWORK_STRUCTURE_FRAME_ARP
	.htype					resb	0x02
	.ptype					resb	0x02
	.hal					resb	0x01
	.pal					resb	0x01
	.opcode					resb	0x02
	.source_mac				resb	0x06
	.source_ip				resb	0x04
	.target_mac				resb	0x06
	.target_ip				resb	0x04
	.SIZE:
endstruc

struc	KERNEL_NETWORK_STRUCTURE_FRAME_IP
	.version_and_ihl			resb	0x01
	.dscp_and_ecn				resb	0x01
	.total_length				resb	0x02
	.identification				resb	0x02
	.f_and_f				resb	0x02
	.ttl					resb	0x01
	.protocol				resb	0x01
	.checksum				resb	0x02
	.source_address				resb	0x04
	.destination_address			resb	0x04
	.SIZE:
endstruc

struc	KERNEL_NETWORK_STRUCTURE_FRAME_ICMP
	.type					resb	0x01
	.code					resb	0x01
	.checksum				resb	0x02
	.reserved				resb	0x04
	.SIZE:
endstruc

struc	KERNEL_NETWORK_STRUCTURE_FRAME_UDP
	.port_source				resb	0x02
	.port_target				resb	0x02
	.length					resb	0x02
	.checksum				resb	0x02
	.SIZE:
endstruc

struc	KERNEL_NETWORK_STRUCTURE_FRAME_TCP
	.port_source				resb	0x02
	.port_target				resb	0x02
	.sequence				resb	0x04
	.acknowledgement			resb	0x04
	.header_length				resb	0x01
	.flags					resb	0x01
	.window_size				resb	0x02
	.checksum_and_urgent_pointer:
	.checksum				resb	0x02
	.urgent_pointer				resb	0x02
	.SIZE:
	.options:
endstruc

struc	KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER
	.source_ipv4				resb	4
	.target_ipv4				resb	4
	.reserved				resb	1
	.protocol				resb	1
	.segment_length				resb	2
	.SIZE:
endstruc

struc	KERNEL_NETWORK_STRUCTURE_TCP_STACK
	.source_mac						resb	8
	.source_ipv4						resb	4
	.source_sequence					resb	4
	.sequence						resb	4
	.acknowledgement					resb	4
	.window_size						resb	2
	.source_port						resb	2
	.host_port						resb	2
	.status							resb	2
	.flags							resb	2
	.sequence_request					resb	4
	.identification						resb	2
	.SIZE:
endstruc

kernel_network_rx_count				dq	STATIC_EMPTY
kernel_network_tx_count				dq	STATIC_EMPTY

align	STATIC_QWORD_SIZE_byte
kernel_network_packet_arp_reply:
						; Ethernet
						db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00
						db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00
						dw	KERNEL_NETWORK_FRAME_ETHERNET_TYPE_arp
						; ARP
						dw	KERNEL_NETWORK_FRAME_ARP_HTYPE_ethernet
						dw	KERNEL_NETWORK_FRAME_ARP_PTYPE_ipv4
						db	KERNEL_NETWORK_FRAME_ARP_HAL_mac
						db	KERNEL_NETWORK_FRAME_ARP_PAL_ipv4
						dw	KERNEL_NETWORK_FRAME_ARP_OPCODE_answer
						db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00
						db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00
						db	0x00, 0x00, 0x00, 0x00
						db	0x00, 0x00, 0x00, 0x00
kernel_network_packet_arp_reply_end:

align	STATIC_QWORD_SIZE_byte
kernel_network_packet_icmp_reply:
						; Ethernet
						db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00
						db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00
						dw	KERNEL_NETWORK_FRAME_ETHERNET_TYPE_ip
						; IPv4
						db	KERNEL_NETWORK_FRAME_IP_HEADER_LENGTH_default | KERNEL_NETWORK_FRAME_IP_VERSION_4
						db	0x00
						dw	(KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ICMP.SIZE >> STATIC_REPLACE_AL_WITH_HIGH_shift) | (KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ICMP.SIZE << STATIC_REPLACE_AL_WITH_HIGH_shift)
						dw	0x0000
						dw	0x0000
						db	KERNEL_NETWORK_FRAME_IP_TTL_default
						db	KERNEL_NETWORK_FRAME_IP_PROTOCOL_ICMP
						dw	0x0000	; suma kontrolna
						dd	0x00000000
						dd	0x00000000
						; ICMP
						db	KERNEL_NETWORK_FRAME_ICMP_TYPE_REPLY
						db	0x00
						dw	0x0000	; suma kontrolna
						dd	0x00000000
kernel_network_packet_icmp_reply_end:

kernel_network_port_table			dq	STATIC_EMPTY

kernel_network_stack_address			dq	STATIC_EMPTY

;===============================================================================
; wejście:
;	rsi - wskaźnik do pakietu
kernel_network_tcp:
	; zachowaj oryginalne rejestry
	push	rax

	; pobierz numer portu docelowego
	movzx	eax,	word [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.port_target]
	rol	ax,	STATIC_REPLACE_AL_WITH_HIGH_shift

	; port wspierany?
	cmp	ax,	512
	jnb	.end	; nie, zignoruj pakiet

	; port docelowy jest pusty?
	shl	eax,	STATIC_MULTIPLE_BY_8_shift
	add	rax,	qword [kernel_network_port_table]
	cmp	qword [rax],	STATIC_EMPTY
	je	.end	; tak, zignoruj pakiet

	; prośba o nawiązanie połączenia?
	cmp	byte [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.flags],	KERNEL_NETWORK_FRAME_TCP_FLAGS_syn
	je	kernel_network_tcp_syn	; tak

.end:
	; przywróć oryginalne rejestry
	pop	rax

	; usuń kod błędu z stosu
	add	rsp,	STATIC_QWORD_SIZE_byte

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rsi - wskaźnik do pakietu
kernel_network_tcp_syn:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi
	push	rdi

	; przeszukaj stos TCP
	mov	rcx,	(KERNEL_NETWORK_STACK_SIZE_page << KERNEL_PAGE_SIZE_shift) / KERNEL_NETWORK_STRUCTURE_TCP_STACK.SIZE
	mov	rdi,	qword [kernel_network_stack_address]

.search:
	; za wolnym miejscem
	lock	bts word [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.status],	KERNEL_NETWORK_STACK_FLAG_busy
	jnc	.found	; znaleziono

	; przesuń wskaźnik na następny wpis połączenia
	add	rdi,	KERNEL_NETWORK_STRUCTURE_TCP_STACK.SIZE

	; przeszukano cały stos TCP?
	dec	rcx
	jnz	.search	; nie, szukaj dalej

	; brak miejsca na zarejestrowanie nowego połączenia
	jmp	.end

.found:
	;-----------------------------------------------------------------------
	; zarejestruj połączenie na stosie
	;-----------------------------------------------------------------------

	; oblicz względną pozycję ramki TCP
	movzx	ecx,	byte [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.version_and_ihl]
	and	cl,	KERNEL_NETWORK_FRAME_IP_HEADER_LENGTH_mask
	shl	cl,	STATIC_MULTIPLE_BY_4_shift

	; zamień na adres względny ramki TCP
	add	ecx,	KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE

	;-----------------------------------------------------------------------

	; zachowaj numer portu usługi
	mov	ax,	word [rsi + rcx + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.port_target]
	mov	word [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.host_port],	ax

	; zachowaj numer portu nadawcy
	mov	ax,	word [rsi + rcx + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.port_source]
	mov	word [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.source_port],	ax

	; zachowaj numer sekwencji nadawcy
	mov	eax,	dword [rsi + rcx + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.sequence]
	bswap	eax	; zachowaj w formacie Little-Endian
	inc	eax	; potwierdź otrzymanie chęci nawiązania połączenia
	mov	dword [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.source_sequence],	eax

	; zachowaj adres MAC nadawcy
	mov	rcx,	qword [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.source]
	mov	qword [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.source_mac],	rcx

	; zachowaj adres IPv4 nadawcy
	mov	ecx,	dword [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.source_address]
	mov	dword [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.source_ipv4],	ecx

	;-----------------------------------------------------------------------

	; nasz identyfikator
	mov	word [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.identification],	STATIC_EMPTY

	; nasz numer sekwencji
	mov	dword [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.sequence],	STATIC_EMPTY

	; domyślny rozmiar okna
	mov	word [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.window_size],	KERNEL_NETWORK_FRAME_TCP_WINDOW_SIZE_default

	; oczekuj danego numeru sekwencji
	mov	dword [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.sequence_request],	eax

	;-----------------------------------------------------------------------

	; akceptuj połączenie
	mov	word [rdi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.flags],	KERNEL_NETWORK_FRAME_TCP_FLAGS_syn | KERNEL_NETWORK_FRAME_TCP_FLAGS_ack

	;-----------------------------------------------------------------------
	; połączenie zarejestrowane
	;-----------------------------------------------------------------------
	mov	rsi,	rdi

	;-----------------------------------------------------------------------
	; wyślij odpowiedź
	;-----------------------------------------------------------------------

	; przygotuj miejsce na odpowiedź
	call	kernel_memory_alloc_page
	jc	.error

	; spakuj dane ramki TCP
	mov	bl,	(KERNEL_NETWORK_STRUCTURE_FRAME_TCP.SIZE >> STATIC_DIVIDE_BY_4_shift) << STATIC_MOVE_AL_HALF_TO_HIGH_shift
	mov	ecx,	KERNEL_NETWORK_STRUCTURE_FRAME_TCP.SIZE
	call	kernel_network_tcp_wrap

	; wyślij pakiet
	mov	ax,	KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.SIZE + STATIC_DWORD_SIZE_byte
	call	driver_nic_i82540em_transfer

	jmp	.end

.error:
	; wyrejestruj połączenie
	mov	byte [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.status],	STATIC_EMPTY

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx

	; powrót z procedury
	jmp	kernel_network_tcp.end

;===============================================================================
; wejście:
;	bl - rozmiar nagłówka TCP
;	ecx - rozmiar ramki TCP w Bajtach
;	rsi - wskaźnik do właściwości połączenia
;	rdi - wskaźnik do przestrzeni pakietu do wysłania
kernel_network_tcp_wrap:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdi

	; ustaw port źródłowy(usługi) i docelowy
	mov	ax,	word [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.host_port]
	mov	word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.port_source],	ax
	mov	ax,	word [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.source_port]
	mov	word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.port_target],	ax

	; nasz numer sekwencji
	mov	eax,	dword [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.sequence]
	bswap	eax	; zamień na Big-Endian
	mov	dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.sequence],	eax

	; numer sekwencji oczekiwany przez adresata
	mov	eax,	dword [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.source_sequence]
	bswap	eax	; zamień na Big-Endian
	mov	dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.acknowledgement],	eax

	; rozmiar nagłówka ramki TCP
	mov	byte [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.header_length],	bl

	; zwróć aktualny stan flag
	mov	al,	byte [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.flags]
	mov	byte [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.flags],	al

	; rozmiar okna
	mov	ax,	word [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.window_size]
	rol	ax,	STATIC_REPLACE_AL_WITH_HIGH_shift	; zamień na Big-Endian
	mov	word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.window_size],	ax

	; wyczyść sumę kontrolną i pole urgent pointer
	mov	dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.checksum_and_urgent_pointer],	STATIC_EMPTY

	; konfiguruj pseudo nagłówek TCP
	call	kernel_network_tcp_pseudo_header

	; suma kontrolna ramki TCP
	shr	ecx,	STATIC_DIVIDE_BY_2_shift	; zamień na słowa
	add	rdi,	KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE
	call	kernel_network_checksum
	rol	ax,	STATIC_REPLACE_AL_WITH_HIGH_shift	; zamień na Big-Endian
	mov	word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_TCP.checksum],	ax

	; spakuj dane ramki IP
	mov	rax,	qword [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.source_mac]
	mov	bl,	KERNEL_NETWORK_FRAME_IP_PROTOCOL_TCP
	shl	ecx,	STATIC_MULTIPLE_BY_2_shift	; zamień na Bajty
	sub	rdi,	KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE ; cofnij wskaźnik na przestrzeń pakietu do wysłania
	call	kernel_network_ip_wrap

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rax - adres MAC odbiorcy
;	bl - typ protokołu
;	cx - rozmiar danych w Bajtach
;	rsi - wskaźnik do właściwości połączenia
;	rdi - wskaźnik do przestrzeni pakietu do wysłania
kernel_network_ip_wrap:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rax

	; wersja IP
	mov	byte [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.version_and_ihl],	KERNEL_NETWORK_FRAME_IP_VERSION_4 | KERNEL_NETWORK_FRAME_IP_HEADER_LENGTH_default

	; wyczyść opcje niewykorzystywane
	mov	byte [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.dscp_and_ecn],	STATIC_EMPTY

	; ustaw rozmiar ramki IP
	add	cx,	KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE
	rol	cx,	STATIC_REPLACE_AL_WITH_HIGH_shift
	mov	word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.total_length],	cx

	; ustaw identyfikator
	mov	ax,	word [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.identification]
	mov	word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.identification],	ax

	; ustaw domyślne flagi
	mov	word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.f_and_f],	KERNEL_NETWORK_FRAME_IP_F_AND_F_do_not_fragment

	; standardowy rozmiar TTL
	mov	byte [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.ttl],	KERNEL_NETWORK_FRAME_IP_TTL_default

	; typ protokołu
	mov	byte [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.protocol],	bl

	; wyczyść sumę kontrolną
	mov	word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.checksum],	STATIC_EMPTY

	; ustaw nadawcę (ja)
	mov	eax,	dword [driver_nic_i82540em_ipv4_address]
	mov	dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.source_address],	eax

	; ustaw adresata
	mov	eax,	dword [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.source_ipv4]
	mov	dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.destination_address],	eax

	; ustaw sumę kontrolną ramki IP
	xor	eax,	eax
	mov	ecx,	KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE >> STATIC_DIVIDE_BY_2_shift
	add	rdi,	KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE
	call	kernel_network_checksum
	rol	ax,	STATIC_REPLACE_AL_WITH_HIGH_shift	; zamień na Big-Endian
	sub	rdi,	KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE
	mov	word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.checksum],	ax

	; spakuj ramkę IP
	pop	rax
	mov	cx,	KERNEL_NETWORK_FRAME_ETHERNET_TYPE_ip
	call	kernel_network_ethernet_wrap

	; przywróć oryginalne rejestry
	pop	rcx

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	ecx - rozmiar ramki TCP w Bajtach
;	rsi - wskaźnik do właściwości połączenia
;	rdi - wskaźnik do przestrzeni pakietu do wysłania
; wyjście:
;	eax - suma kontrolna pseudo nagłówka
kernel_network_tcp_pseudo_header:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdi

	; konfiguruj pseudo nagłówek

	; nadawca
	mov	eax,	dword [driver_nic_i82540em_ipv4_address]
	mov	dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE - KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.source_ipv4],	eax

	; adresat
	mov	eax,	dword [rsi + KERNEL_NETWORK_STRUCTURE_TCP_STACK.source_ipv4]
	mov	dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE - KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.target_ipv4],	eax

	; wyczyść wartość zarezerwowaną
	mov	byte [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE - KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.reserved],	STATIC_EMPTY

	; protokół
	mov	byte [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE - KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.protocol],	KERNEL_NETWORK_FRAME_TCP_PROTOCOL_default

	; rozmiar ramki TCP
	rol	cx,	STATIC_REPLACE_AL_WITH_HIGH_shift	; zamień na Big-Endian
	mov	word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE - KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.segment_length],	cx

	; oblicz sumę kontrolną pseudo nagłówka
	xor	eax,	eax
	mov	ecx,	KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE >> STATIC_DIVIDE_BY_2_shift
	add	rdi,	KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE - KERNEL_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE
	call	kernel_network_checksum_part

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx

	; powrót z podprocedury
	ret

;===============================================================================
; wejście:
;	cx - numer portu
; wyjście:
;	Flags CF, jeśli zajęty
kernel_network_tcp_port_assign:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi

	; numer portu obsługiwany?
	cmp	cx,	512
	jnb	.error	; nie

	; zamień numer portu na wskaźnik pośredni
	and	ecx,	STATIC_WORD_mask
	shl	cx,	STATIC_MULTIPLE_BY_8_shift

	; pobierz PID procesu
	call	kernel_task_active_pid

	; załaduj do tablicy portów identyfikator właściciela
	mov	rdi,	qword [kernel_network_port_table]
	mov	qword [rdi + rcx],	rax

	; zarejestrowano
	jmp	.end

.error:
	; port niedostępny
	stc

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; THREAD
;===============================================================================
; wejście:
;	rsi - wskaźnik do pakietu
kernel_network:
	; upewnij się by nie korzystać z stron zarezerwowanych
	xor	ebp,	ebp

	; protokół ARP?
	cmp	word [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.type],	KERNEL_NETWORK_FRAME_ETHERNET_TYPE_arp
	je	kernel_network_arp	; tak

	; protokół IP?
	cmp	word [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.type],	KERNEL_NETWORK_FRAME_ETHERNET_TYPE_ip
	je	kernel_network_ip	; tak

	; protokół nieobsługiwany

.end:
	; zwolnij przestrzeń pakietu
	mov	rdi,	rsi
	call	kernel_memory_release_page

	; pobierz wskaźnik do wątku w kolejce zadań
	jmp	kernel_task_kill_me

;===============================================================================
; wejście:
;	rsi - wskaźnik do pakietu przychodzącego
kernel_network_arp:
	; zachowaj oryginalny rejestr
	push	rax

	; adresowanie sprzętowe typu Ethernet?
	cmp	word [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.htype],	KERNEL_NETWORK_FRAME_ARP_HTYPE_ethernet
	jne	.omit	; nie

	; protokół typu IPv4?
	cmp	word [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.ptype],	KERNEL_NETWORK_FRAME_ARP_PTYPE_ipv4
	jne	.omit	; nie

	; rozmiar adresu MAC prawidłowy?
	cmp	byte [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.hal],	KERNEL_NETWORK_FRAME_ARP_HAL_mac
	jne	.omit	; nie

	; rozmiar adresu IPv4 prawidłowy?
	cmp	byte [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.pal],	KERNEL_NETWORK_FRAME_ARP_PAL_ipv4
	jne	.omit	; nie

	; czy zapytanie dotyczy naszego adresu IP?
	mov	eax,	dword [driver_nic_i82540em_ipv4_address]
	cmp	eax,	dword [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.target_ip]
	jne	.omit	; nie

	; zachowaj oryginalne rejestry
	push	rdi

	; ustaw wskaźnik na pakiet zwrotny
	mov	rdi,	kernel_network_packet_arp_reply

	; zwróć w odpowiedzi IPv4 kontrolera sieciowego
	mov	dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.source_ip],	eax

	; zwróć w odpowiedzi IPv4 nadawcy
	mov	eax,	dword [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.source_ip]
	mov	dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.target_ip],	eax

	; uzupełnij ramki ARP i Ethernet o adres MAC kontrolera sieciowego
	mov	rax,	qword [driver_nic_i82540em_mac_address]
	mov	dword [kernel_network_packet_arp_reply + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.source],	eax
	mov	dword [kernel_network_packet_arp_reply + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.source_mac],	eax
	shr	rax,	STATIC_MOVE_HIGH_TO_EAX_shift
	mov	word [kernel_network_packet_arp_reply + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.source + KERNEL_NETWORK_STRUCTURE_MAC.4],	ax
	mov	word [kernel_network_packet_arp_reply + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.source_mac + KERNEL_NETWORK_STRUCTURE_MAC.4],	ax

	; uzupełnij ramkę ARP o adres MAC adresata
	mov	rax,	qword [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.source_mac]
	mov	dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.target_mac],	eax
	shr	rax,	STATIC_MOVE_HIGH_TO_EAX_shift
	mov	word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.target_mac + KERNEL_NETWORK_STRUCTURE_MAC.4],	ax

	; zpakuj ramkę ARP
	mov	rax,	qword [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.source_mac]
	mov	cx,	KERNEL_NETWORK_FRAME_ETHERNET_TYPE_arp
	call	kernel_network_ethernet_wrap

	; wyślij odpowiedź
	mov	eax,	kernel_network_packet_arp_reply_end - kernel_network_packet_arp_reply
	call	driver_nic_i82540em_transfer

	; przywróć oryginalne rejestry
	pop	rdi

.omit:
	; przywróć oryginalny rejestr
	pop	rax

	; powrót z procedury
	jmp	kernel_network.end

;===============================================================================
; wejście:
;	rsi - wskaźnik do pakietu przychodzącego
kernel_network_ip:
	; protokół ICMP?
	cmp	byte [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.protocol],	KERNEL_NETWORK_FRAME_IP_PROTOCOL_ICMP
	je	kernel_network_icmp	; tak

	; protokół TCP?
	cmp	byte [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.protocol],	KERNEL_NETWORK_FRAME_IP_PROTOCOL_TCP
	je	kernel_network_tcp	; tak

	; powrót z procedury
	jmp	kernel_network.end

;===============================================================================
; wejście:
;	rsi - wskaźnik do pakietu przychodzącego
kernel_network_icmp:
	; zachowaj oryginalne rejestry
	push	rsi

	; zapytanie?
	cmp	byte [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ICMP.type],	KERNEL_NETWORK_FRAME_ICMP_TYPE_REQUEST
	jne	.end	; nie, brak obsługi

	;-----------------------------------------------------------------------
	; przygotuj odpowiedź
	;-----------------------------------------------------------------------
	mov	rdi,	kernel_network_packet_icmp_reply + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE

	; zwróć identyfikator i sekwencję
	mov	eax,	dword [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ICMP.reserved]
	mov	dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ICMP.reserved],	eax

	; wyczyść starą sumę kontrolną ramki ICMP
	mov	word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ICMP.checksum],	STATIC_EMPTY

	;-----------------------------------------------------------------------
	; wylicz sumę kontrolną
	xor	eax,	eax
	mov	ecx,	KERNEL_NETWORK_STRUCTURE_FRAME_ICMP.SIZE >> STATIC_DIVIDE_BY_2_shift
	call	kernel_network_checksum

	; ustaw sumę kontrolną ramki ICMP
	rol	ax,	STATIC_REPLACE_AL_WITH_HIGH_shift	; Big-Endian
	mov	word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ICMP.checksum],	ax

	; przesuń wskaźnik na ramkę IPv4
	sub	rdi,	KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE

	; ustaw docelowy adres IPv4
	mov	eax,	dword [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_IP.source_address]
	mov	dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_IP.destination_address],	eax

	; zwróć nasz adres IPv4
	mov	eax,	dword [driver_nic_i82540em_ipv4_address]
	mov	dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_IP.source_address],	eax

	; wyczyść starą sumę kontrolną ramki IPv4
	mov	word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_IP.checksum],	STATIC_EMPTY

	; wylicz sumę kontrolną ------------------------------------------------
	xor	eax,	eax
	mov	ecx,	(KERNEL_NETWORK_STRUCTURE_FRAME_IP.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ICMP.SIZE) >> STATIC_DIVIDE_BY_2_shift
	call	kernel_network_checksum
	rol	ax,	STATIC_REPLACE_AL_WITH_HIGH_shift	; Big-Endian
	mov	word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_IP.checksum],	ax

	; spakuj ramkę IP
	sub	rdi,	KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE
	mov	rax,	qword [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.source]
	mov	cx,	KERNEL_NETWORK_FRAME_ETHERNET_TYPE_ip
	call	kernel_network_ethernet_wrap

	; wyślij odpowiedź -----------------------------------------------------
	mov	eax,	kernel_network_packet_icmp_reply_end - kernel_network_packet_icmp_reply
	call	driver_nic_i82540em_transfer

.end:
	; przywróć oryginalne rejestry
	pop	rsi

	; powrót z procedury
	jmp	kernel_network.end

;===============================================================================
; wejście:
;	rax - adres MAC odbiorcy
;	cx - typ protokołu
;	rdi - wskaźnik do przestrzeni pakietu do wysłania
kernel_network_ethernet_wrap:
	; zachowaj oryginalne rejestry
	push	rax

	; adres MAC odbiorcy
	mov	qword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.target],	rax

	; adres MAC nadawcy
	mov	rax,	qword [driver_nic_i82540em_mac_address]
	mov	qword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.source],	rax

	; typ protokołu
	mov	word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.type],	cx

	; przywróć oryginalne rejestry
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rax - pusty lub kontynuacja poprzedniej sumy kontrolnej
;	rcx - rozmiar przestrzeni w słowach (po 2 Bajty)
;	rdi - wskaźnik do przeliczanej przestrzeni
; wyjście:
;	ax - suma kontrolna (Little-Endian)
kernel_network_checksum:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rdi

	; ustaw wynik wstępny
	xor	ebx,	ebx
	xchg	rbx,	rax

.calculate:
	; pobierz 2 Bajty z przeliczanej przestrzeni
	mov	ax,	word [rdi]
	rol	ax,	STATIC_REPLACE_AL_WITH_HIGH_shift	; Big-Endian

	; dodaj do akumulatora
	add	rbx,	rax

	; przesuń wskaźnik na następny fragment
	add	rdi,	STATIC_WORD_SIZE_byte

	; przetwórz pozostałą przestrzeń
	loop	.calculate

	; koryguj sumę kontrolną o przepełnienie
	mov	ax,	bx
	shr	ebx,	STATIC_MOVE_HIGH_TO_AX_shift
	add	rax,	rbx

	; zwróć wynik w odwrotnej notacji
	not	ax

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rbx

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rax - pusty lub kontynuacja poprzedniej sumy kontrolnej
;	ecx - rozmiar przestrzeni w słowach (po 2 Bajty)
;	rdi - wskaźnik do przeliczanej przestrzeni
; wyjście:
;	ax - suma kontrolna (Little-Endian)
kernel_network_checksum_part:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rdi

	xor	ebx,	ebx

.calculate:
	; pobierz 2 Bajty z przeliczanej przestrzeni
	mov	bx,	word [rdi]
	rol	bx,	STATIC_REPLACE_AL_WITH_HIGH_shift	; Big-Endian

	; dodaj do akumulatora
	add	rax,	rbx

	; przesuń wskaźnik na następny fragment
	add	rdi,	STATIC_WORD_SIZE_byte

	; przetwórz pozostałą przestrzeń
	loop	.calculate

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rbx

	; powrót z procedury
	ret
