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
service_network_arp:
	; zachowaj oryginalny rejestr
	push	rax

	; adresowanie sprzętowe typu Ethernet?
	cmp	word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.htype],	SERVICE_NETWORK_FRAME_ARP_HTYPE_ethernet
	jne	.omit	; nie

	; protokół typu IPv4?
	cmp	word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.ptype],	SERVICE_NETWORK_FRAME_ARP_PTYPE_ipv4
	jne	.omit	; nie

	; rozmiar adresu MAC prawidłowy?
	cmp	byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.hal],	SERVICE_NETWORK_FRAME_ARP_HAL_mac
	jne	.omit	; nie

	; rozmiar adresu IPv4 prawidłowy?
	cmp	byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.pal],	SERVICE_NETWORK_FRAME_ARP_PAL_ipv4
	jne	.omit	; nie

	; czy zapytanie dotyczy naszego adresu IP?
	mov	eax,	dword [driver_nic_i82540em_ipv4_address]
	cmp	eax,	dword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.target_ip]
	jne	.omit	; nie

	; zachowaj oryginalne rejestry
	push	rdi

	; przygotuj przesterzeń pod odpowiedź
	call	kernel_memory_alloc_page
	jc	.error	; brak wolnego miejsca, nie odpowiadaj

	;-----------------------------------------------------------------------
	; wypełnij ramki domyślnymi wartościami
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.type],	SERVICE_NETWORK_FRAME_ETHERNET_TYPE_arp
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.htype],	SERVICE_NETWORK_FRAME_ARP_HTYPE_ethernet
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.ptype],	SERVICE_NETWORK_FRAME_ARP_PTYPE_ipv4
	mov	byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.hal],	SERVICE_NETWORK_FRAME_ARP_HAL_mac
	mov	byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.pal],	SERVICE_NETWORK_FRAME_ARP_PAL_ipv4
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.opcode],	SERVICE_NETWORK_FRAME_ARP_OPCODE_answer

	; zwróć w odpowiedzi IPv4 kontrolera sieciowego
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.source_ip],	eax

	; zwróć w odpowiedzi IPv4 nadawcy
	mov	eax,	dword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.source_ip]
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.target_ip],	eax

	; uzupełnij ramki ARP i Ethernet o adres MAC kontrolera sieciowego
	mov	rax,	qword [driver_nic_i82540em_mac_address]
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.source],	eax
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.source_mac],	eax
	shr	rax,	STATIC_MOVE_HIGH_TO_EAX_shift
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.source + SERVICE_NETWORK_STRUCTURE_MAC.4],	ax
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.source_mac + SERVICE_NETWORK_STRUCTURE_MAC.4],	ax

	; uzupełnij ramkę ARP o adres MAC adresata
	mov	rax,	qword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.source_mac]
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.target_mac],	eax
	shr	rax,	STATIC_MOVE_HIGH_TO_EAX_shift
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.target_mac + SERVICE_NETWORK_STRUCTURE_MAC.4],	ax

	; zpakuj ramkę ARP
	mov	rax,	qword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.source_mac]
	mov	cx,	SERVICE_NETWORK_FRAME_ETHERNET_TYPE_arp
	call	service_network_ethernet_wrap

	; wyślij odpowiedź
	mov	eax,	SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_ARP.SIZE
	call	service_network_transfer

.error:
	; przywróć oryginalne rejestry
	pop	rdi

.omit:
	; przywróć oryginalny rejestr
	pop	rax

	; powrót z procedury
	jmp	service_network.end

	macro_debug	"service_network_arp"
