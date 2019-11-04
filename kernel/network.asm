;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

KERNEL_NETWORK_MAC_mask				equ	0x0000FFFFFFFFFFFF

KERNEL_NETWORK_PORT_SIZE_page			equ	0x01	; tablica przechowująca stan portów
KERNEL_NETWORK_PORT_FLAG_empty			equ	0x00
KERNEL_NETWORK_PORT_FLAG_ready			equ	0x01

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

struc	KERNEL_NETWORK_STRUCTURE_PORT
	.cr3_and_flags				resb	0x08
	.data_address				resb	0x08
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

;===============================================================================
; wejście:
;	rsi - wskaźnik do pakietu
kernel_network:
	; protokół ARP?
	cmp	word [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.type],	KERNEL_NETWORK_FRAME_ETHERNET_TYPE_arp
	je	kernel_network_arp	; tak

	; protokół IP?
	cmp	word [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.type],	KERNEL_NETWORK_FRAME_ETHERNET_TYPE_ip
	je	kernel_network_ip	; tak

	; protokół nieobsługiwany

.end:
	; powrót z procedury
	ret

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

	; zwróć w odpowiedzi nasz adres IPv4
	mov	dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.source_ip],	eax

	; zwróć do nadawcy ramkę ARP i Ethernet
	mov	rax,	qword [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.source_mac]
	mov	dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.target],	eax
	mov	dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.target_mac],	eax
	shr	rax,	STATIC_MOVE_HIGH_TO_EAX_shift
	mov	word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.target + KERNEL_NETWORK_STRUCTURE_MAC.4],	ax
	mov	word [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.target_mac + KERNEL_NETWORK_STRUCTURE_MAC.4],	ax

	; zwróć w odpowiedzi IPv4 nadawcy
	mov	eax,	dword [rsi + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.source_ip]
	mov	dword [rdi + KERNEL_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + KERNEL_NETWORK_STRUCTURE_FRAME_ARP.target_ip],	eax

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
	je	kernel_network_ip_icmp	; tak

	; powrót z procedury
	jmp	kernel_network.end

;===============================================================================
; wejście:
;	rsi - wskaźnik do pakietu przychodzącego
kernel_network_ip_icmp:
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
