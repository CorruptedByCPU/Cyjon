;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

SERVICE_NETWORK_MAC_mask				equ	0x0000FFFFFFFFFFFF

SERVICE_NETWORK_PORT_SIZE_page				equ	0x01	; tablica przechowująca stan portów
SERVICE_NETWORK_PORT_FLAG_empty				equ	000000001b
SERVICE_NETWORK_PORT_FLAG_received			equ	000000010b
SERVICE_NETWORK_PORT_FLAG_send				equ	000000100b
SERVICE_NETWORK_PORT_FLAG_BIT_empty			equ	0
SERVICE_NETWORK_PORT_FLAG_BIT_received			equ	1
SERVICE_NETWORK_PORT_FLAG_BIT_send			equ	2

SERVICE_NETWORK_STACK_SIZE_page				equ	0x01	; ilość stron przeznaczonych na stos
SERVICE_NETWORK_STACK_FLAG_busy				equ	10000000b

SERVICE_NETWORK_FRAME_ETHERNET_TYPE_arp			equ	0x0608	; 0x0806
SERVICE_NETWORK_FRAME_ETHERNET_TYPE_ip			equ	0x0008	; 0x0800

SERVICE_NETWORK_FRAME_ARP_HTYPE_ethernet		equ	0x0100	; 0x0001
SERVICE_NETWORK_FRAME_ARP_PTYPE_ipv4			equ	0x0008	; 0x0800
SERVICE_NETWORK_FRAME_ARP_HAL_mac			equ	0x06	; xx:xx:xx:xx:xx:xx
SERVICE_NETWORK_FRAME_ARP_PAL_ipv4			equ	0x04	; x.x.x.x
SERVICE_NETWORK_FRAME_ARP_OPCODE_request		equ	0x0100
SERVICE_NETWORK_FRAME_ARP_OPCODE_answer			equ	0x0200

SERVICE_NETWORK_FRAME_IP_HEADER_LENGTH_default		equ	0x05
SERVICE_NETWORK_FRAME_IP_HEADER_LENGTH_mask		equ	0x0F
SERVICE_NETWORK_FRAME_IP_VERSION_mask			equ	0xF0
SERVICE_NETWORK_FRAME_IP_VERSION_4			equ	0x40
SERVICE_NETWORK_FRAME_IP_PROTOCOL_ICMP			equ	0x01
SERVICE_NETWORK_FRAME_IP_PROTOCOL_TCP			equ	0x06
SERVICE_NETWORK_FRAME_IP_PROTOCOL_UDP			equ	0x11
SERVICE_NETWORK_FRAME_IP_TTL_default			equ	0x40
SERVICE_NETWORK_FRAME_IP_F_AND_F_do_not_fragment	equ	0x0040

SERVICE_NETWORK_FRAME_ICMP_TYPE_REQUEST			equ	0x08
SERVICE_NETWORK_FRAME_ICMP_TYPE_REPLY			equ	0x00

SERVICE_NETWORK_FRAME_TCP_HEADER_LENGTH_default		equ	0x50	; 5 * 0x04 = 20 Bajtów
SERVICE_NETWORK_FRAME_TCP_FLAGS_fin			equ	0000000000000001b
SERVICE_NETWORK_FRAME_TCP_FLAGS_syn			equ	0000000000000010b
SERVICE_NETWORK_FRAME_TCP_FLAGS_rst			equ	0000000000000100b
SERVICE_NETWORK_FRAME_TCP_FLAGS_psh			equ	0000000000001000b
SERVICE_NETWORK_FRAME_TCP_FLAGS_ack			equ	0000000000010000b
SERVICE_NETWORK_FRAME_TCP_FLAGS_urg			equ	0000000000100000b
SERVICE_NETWORK_FRAME_TCP_FLAGS_bsy			equ	0000100000000000b	; flaga prywatna
SERVICE_NETWORK_FRAME_TCP_FLAGS_bsy_bit			equ	11
SERVICE_NETWORK_FRAME_TCP_OPTION_MSS_default		equ	0xB4050402	; Big-Endian
SERVICE_NETWORK_FRAME_TCP_OPTION_KIND_mss		equ	0x02	; Max Segment Size
SERVICE_NETWORK_FRAME_TCP_PROTOCOL_default		equ	0x06
SERVICE_NETWORK_FRAME_TCP_WINDOW_SIZE_default		equ	0x05B4	; Little-Endian

struc	SERVICE_NETWORK_STRUCTURE_MAC
	.0						resb	1
	.1						resb	1
	.2						resb	1
	.3						resb	1
	.4						resb	1
	.5						resb	1
	.SIZE:
endstruc

struc	SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET
	.target						resb	0x06
	.source						resb	0x06
	.type						resb	0x02
	.SIZE:
endstruc

struc	SERVICE_NETWORK_STRUCTURE_FRAME_ARP
	.htype						resb	0x02
	.ptype						resb	0x02
	.hal						resb	0x01
	.pal						resb	0x01
	.opcode						resb	0x02
	.source_mac					resb	0x06
	.source_ip					resb	0x04
	.target_mac					resb	0x06
	.target_ip					resb	0x04
	.SIZE:
endstruc

struc	SERVICE_NETWORK_STRUCTURE_FRAME_IP
	.version_and_ihl				resb	0x01
	.dscp_and_ecn					resb	0x01
	.total_length					resb	0x02
	.identification					resb	0x02
	.f_and_f					resb	0x02
	.ttl						resb	0x01
	.protocol					resb	0x01
	.checksum					resb	0x02
	.source_address					resb	0x04
	.destination_address				resb	0x04
	.SIZE:
endstruc

struc	SERVICE_NETWORK_STRUCTURE_FRAME_ICMP
	.type						resb	0x01
	.code						resb	0x01
	.checksum					resb	0x02
	.reserved					resb	0x04
	.data						resb	0x20
	.SIZE:
endstruc

struc	SERVICE_NETWORK_STRUCTURE_FRAME_UDP
	.port_source					resb	0x02
	.port_target					resb	0x02
	.length						resb	0x02
	.checksum					resb	0x02
	.SIZE:
endstruc

struc	SERVICE_NETWORK_STRUCTURE_FRAME_TCP
	.port_source					resb	0x02
	.port_target					resb	0x02
	.sequence					resb	0x04
	.acknowledgement				resb	0x04
	.header_length					resb	0x01
	.flags						resb	0x01
	.window_size					resb	0x02
	.checksum_and_urgent_pointer:
	.checksum					resb	0x02
	.urgent_pointer					resb	0x02
	.SIZE:
	.options:
endstruc

struc	SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER
	.source_ipv4					resb	4
	.target_ipv4					resb	4
	.reserved					resb	1
	.protocol					resb	1
	.segment_length					resb	2
	.SIZE:
endstruc

struc	SERVICE_NETWORK_STRUCTURE_TCP_STACK
	.source_mac					resb	8
	.source_ipv4					resb	4
	.source_sequence				resb	4
	.host_sequence					resb	4
	.request_acknowledgement			resb	4
	.window_size					resb	2
	.source_port					resb	2
	.host_port					resb	2
	.status						resb	2
	.flags						resb	2
	.flags_request					resb	2
	.identification					resb	2
	.SIZE:
endstruc

struc	SERVICE_NETWORK_STRUCTURE_PORT
	.pid						resb	8
	.SIZE:
endstruc
