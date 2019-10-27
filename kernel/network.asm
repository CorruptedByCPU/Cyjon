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

struc	KERNEL_STRUCTURE_NETWORK_FRAME_ETHER
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

kernel_network_ip_identification		dw	0x0001

kernel_network_port_table			dq	STATIC_EMPTY

;===============================================================================
; wejście:
;	rsi - wskaźnik do pakietu
kernel_network:
	; protokół nieobsługiwany

.end:
	; powrót z procedury
	ret
