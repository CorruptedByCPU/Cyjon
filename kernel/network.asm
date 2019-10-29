;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

KERNEL_NETWORK_MAC_mask				equ	0x0000FFFFFFFFFFFF

KERNEL_NETWORK_PORT_SIZE_page			equ	0x01	; tablica przechowująca stan portów
KERNEL_NETWORK_PORT_FLAG_empty			equ	0x00
KERNEL_NETWORK_PORT_FLAG_ready			equ	0x01

KERNEL_NETWORK_FRAME_ETHER_TYPE_arp		equ	0x0608	; 0x0806
KERNEL_NETWORK_FRAME_ETHER_TYPE_ip		equ	0x0008	; 0x0800

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

KERNEL_NETWORK_FRAME_ICMP_TYPE_PING		equ	0x08
KERNEL_NETWORK_FRAME_ICMP_TYPE_REPLY		equ	0x00

struc	KERNEL_STRUCTURE_NETWORK_MAC
	.0					resb	1
	.1					resb	1
	.2					resb	1
	.3					resb	1
	.4					resb	1
	.5					resb	1
	.SIZE:
endstruc

struc	KERNEL_STRUCTURE_NETWORK_FRAME_ETHERNET
	.target					resb	0x06
	.source					resb	0x06
	.type					resb	0x02
	.SIZE:
endstruc

struc	KERNEL_STRUCTURE_NETWORK_FRAME_ARP
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

struc	KERNEL_STRUCTURE_NETWORK_FRAME_IP
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

struc	KERNEL_STRUCTURE_NETWORK_FRAME_ICMP
	.type					resb	0x01
	.code					resb	0x01
	.checksum				resb	0x02
	.identifier				resb	0x02
	.sequence				resb	0x02
	.SIZE:
endstruc

struc	KERNEL_STRUCTURE_NETWORK_FRAME_UDP
	.port_source				resb	0x02
	.port_target				resb	0x02
	.length					resb	0x02
	.checksum				resb	0x02
	.SIZE:
endstruc

struc	KERNEL_STRUCTURE_NETWORK_PORT
	.cr3_and_flags				resb	8
	.data_address				resb	8
	.SIZE:
endstruc

kernel_network_rx_count				dq	STATIC_EMPTY
kernel_network_tx_count				dq	STATIC_EMPTY

align	STATIC_QWORD_SIZE_byte
kernel_network_packet_arp_answer:
						; Ethernet
						db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00
						db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00
						dw	KERNEL_NETWORK_FRAME_ETHER_TYPE_arp
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

;===============================================================================
; wejście:
;	rsi - wskaźnik do pakietu
kernel_network:
	; protokół ARP?
	cmp	word [rsi + KERNEL_STRUCTURE_NETWORK_FRAME_ETHERNET.type],	KERNEL_NETWORK_FRAME_ETHER_TYPE_arp
	je	kernel_network_arp	; tak

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
	cmp	word [rsi + KERNEL_STRUCTURE_NETWORK_FRAME_ETHERNET.SIZE + KERNEL_STRUCTURE_NETWORK_FRAME_ARP.htype],	KERNEL_NETWORK_FRAME_ARP_HTYPE_ethernet
	jne	.omit	; nie

	; protokół typu IPv4?
	cmp	word [rsi + KERNEL_STRUCTURE_NETWORK_FRAME_ETHERNET.SIZE + KERNEL_STRUCTURE_NETWORK_FRAME_ARP.ptype],	KERNEL_NETWORK_FRAME_ARP_PTYPE_ipv4
	jne	.omit	; nie

	; rozmiar adresu MAC prawidłowy?
	cmp	byte [rsi + KERNEL_STRUCTURE_NETWORK_FRAME_ETHERNET.SIZE + KERNEL_STRUCTURE_NETWORK_FRAME_ARP.hal],	KERNEL_NETWORK_FRAME_ARP_HAL_mac
	jne	.omit	; nie

	; rozmiar adresu IPv4 prawidłowy?
	cmp	byte [rsi + KERNEL_STRUCTURE_NETWORK_FRAME_ETHERNET.SIZE + KERNEL_STRUCTURE_NETWORK_FRAME_ARP.pal],	KERNEL_NETWORK_FRAME_ARP_PAL_ipv4
	jne	.omit	; nie

	; czy zapytanie dotyczy naszego adresu IP?
	mov	eax,	dword [driver_nic_i82540em_ipv4_address]
	cmp	eax,	dword [rsi + KERNEL_STRUCTURE_NETWORK_FRAME_ETHERNET.SIZE + KERNEL_STRUCTURE_NETWORK_FRAME_ARP.target_ip]
	jne	.omit	; nie

	; zachowaj oryginalne rejestry
	push	rdi

	; ustaw wskaźnik na pakiet zwrotny
	mov	rdi,	kernel_network_packet_arp_answer

	; zwróć w odpowiedzi nasz adres IPv4
	mov	dword [rdi + KERNEL_STRUCTURE_NETWORK_FRAME_ETHERNET.SIZE + KERNEL_STRUCTURE_NETWORK_FRAME_ARP.source_ip],	eax

	; zwróć do nadawcy ramkę ARP i Ethernet
	mov	rax,	qword [rsi + KERNEL_STRUCTURE_NETWORK_FRAME_ARP.source_mac]
	mov	dword [rdi + KERNEL_STRUCTURE_NETWORK_FRAME_ETHERNET.target],	eax
	mov	dword [rdi + KERNEL_STRUCTURE_NETWORK_FRAME_ETHERNET.SIZE + KERNEL_STRUCTURE_NETWORK_FRAME_ARP.target_mac],	eax
	shr	rax,	STATIC_MOVE_HIGH_TO_EAX_shift
	mov	word [rdi + KERNEL_STRUCTURE_NETWORK_FRAME_ETHERNET.target + KERNEL_STRUCTURE_NETWORK_MAC.4],	ax
	mov	word [rdi + KERNEL_STRUCTURE_NETWORK_FRAME_ETHERNET.SIZE + KERNEL_STRUCTURE_NETWORK_FRAME_ARP.target_mac + KERNEL_STRUCTURE_NETWORK_MAC.4],	ax

	; zwróć w odpowiedzi IPv4 nadawcy
	mov	eax,	dword [rsi + KERNEL_STRUCTURE_NETWORK_FRAME_ARP.source_ip]
	mov	dword [rdi + KERNEL_STRUCTURE_NETWORK_FRAME_ETHERNET.SIZE + KERNEL_STRUCTURE_NETWORK_FRAME_ARP.target_ip],	eax

	; wyślij odpowiedź
	mov	eax,	KERNEL_STRUCTURE_NETWORK_FRAME_ETHERNET.SIZE + KERNEL_STRUCTURE_NETWORK_FRAME_ARP.SIZE
	call	driver_nic_i82540em_transfer

	; przywróć oryginalne rejestry
	pop	rdi

.omit:
	; przywróć oryginalny rejestr
	pop	rax

	; powrót z procedury obsługi pakietu ARP
	jmp	kernel_network.end
