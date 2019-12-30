;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

SERVICE_NETWORK_RECEIVE_PUSH_WAIT_limit			equ	3

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
	.cr3_and_flags					resb	8
	.tcp_connection					resb	8
	.size						resb	8
	.address					resb	8
	.SIZE:
endstruc

service_network_pid					dq	STATIC_EMPTY

service_network_rx_count				dq	STATIC_EMPTY
service_network_tx_count				dq	STATIC_EMPTY

service_network_port_table				dq	STATIC_EMPTY

service_network_stack_address				dq	STATIC_EMPTY

service_network_ipc_message:
	times	KERNEL_IPC_STRUCTURE_LIST.SIZE		db	STATIC_EMPTY

;===============================================================================
; THREAD
;===============================================================================
; wejście:
;	rsi - wskaźnik do pakietu przychodzącego
service_network:
	; upewnij się by nie korzystać z stron zarezerwowanych
	xor	ebp,	ebp

	; pobierz własny PID
	call	kernel_task_active
	mov	rax,	qword [rdi + KERNEL_STRUCTURE_TASK.pid]

	; zachowaj informacje o własnym PID dla pozostałych procesów
	mov	qword [service_network_pid],	rax

.loop:
	; pobierz wiadomość do nas
	mov	rdi,	service_network_ipc_message
	call	kernel_ipc_receive
	jc	.loop	; brak, sprawdź raz jeszcze

%ifdef	DEBUG
	; debug
	push	rcx
	push	rsi
	mov	ecx,	kernel_debug_string_network_end - kernel_debug_string_network
	mov	rsi,	kernel_debug_string_network
	call	kernel_video_string
	pop	rsi
	pop	rcx
%endif

	; pobierz rozmiar i wskaźnik do przestrzeni
	mov	rcx,	qword [rdi + KERNEL_IPC_STRUCTURE_LIST.size]
	mov	rsi,	qword [rdi + KERNEL_IPC_STRUCTURE_LIST.pointer]

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

;===============================================================================
; wejście:
;	rbx - identyfikator portu
;	rcx - rozmiar danych w Bajtach
;	rsi - wskaźnik do przestrzeni danych
service_network_tcp_port_send:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	rdi

	; przygotuj przestrzeń pod odpowiedź
	call	kernel_memory_alloc_page
	jc	.end	; brak miejsca

	; zachowaj rozmiar i wskaźnik do przestrzeni danych
	push	rcx
	push	rdi

	; dołącz dane odpowiedzi
	add	rdi,	SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.SIZE
	rep	movsb

	; przywróć rozmiar i wskaźnik do przestrzeni danych
	pop	rdi
	pop	rcx

	inc	dword [rbx + SERVICE_NETWORK_STRUCTURE_TCP_STACK.host_sequence]
	mov	byte [rbx + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags],	SERVICE_NETWORK_FRAME_TCP_FLAGS_psh | SERVICE_NETWORK_FRAME_TCP_FLAGS_ack

	; wypełnij ramki pakietu
	add	rcx,	SERVICE_NETWORK_STRUCTURE_FRAME_TCP.SIZE + 0x01
	mov	rsi,	rbx
	mov	bl,	SERVICE_NETWORK_FRAME_TCP_HEADER_LENGTH_default
	call	service_network_tcp_wrap

	; wyślij pakiet
	mov	rax,	rcx
	add	rax,	SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE
	call	service_network_transfer

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rsi - wskaźnik do pakietu przychodzącego
service_network_ip:
%ifdef	DEBUG
	; debug
	push	rcx
	push	rsi
	mov	ecx,	kernel_debug_string_ip_end - kernel_debug_string_ip
	mov	rsi,	kernel_debug_string_ip
	call	kernel_video_string
	pop	rsi
	pop	rcx
%endif

	; protokół ICMP?
	cmp	byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.protocol],	SERVICE_NETWORK_FRAME_IP_PROTOCOL_ICMP
	je	service_network_icmp	; tak

	; ; protokół TCP?
	; cmp	byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.protocol],	SERVICE_NETWORK_FRAME_IP_PROTOCOL_TCP
	; je	service_network_tcp	; tak

.end:
	; powrót z procedury
	jmp	service_network.end

	macro_debug	"service_network_ip"

;===============================================================================
; wejście:
;	rsi - wskaźnik do pakietu przychodzącego
service_network_tcp:
	; zachowaj oryginalne rejestry
	push	rax

	; pobierz numer portu docelowego
	movzx	eax,	word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.port_target]
	rol	ax,	STATIC_REPLACE_AL_WITH_HIGH_shift

	; port wspierany?
	cmp	ax,	512
	jnb	.end	; nie, zignoruj pakiet

	; port docelowy jest pusty?
	shl	eax,	STATIC_MULTIPLE_BY_32_shift
	add	rax,	qword [service_network_port_table]
	cmp	qword [rax],	STATIC_EMPTY
	je	.end	; tak, zignoruj pakiet

	; prośba o nawiązanie połączenia?
	cmp	byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.flags],	SERVICE_NETWORK_FRAME_TCP_FLAGS_syn
	je	service_network_tcp_syn	; tak

	; odszukaj połączenie dotyczące pakietu
	call	service_network_tcp_find
	jc	.end	; brak nawiązanego połączenia z danym pakietem

	; akceptacja wysłanych danych?
	cmp	byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.flags],	SERVICE_NETWORK_FRAME_TCP_FLAGS_ack
	je	service_network_tcp_ack	; tak

	; zakończenie połączenia?
	test	byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.flags],	SERVICE_NETWORK_FRAME_TCP_FLAGS_fin
	jnz	service_network_tcp_fin	; tak

	; przesłanie danych bezpośrednio do procesu?
	test	byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.flags],	SERVICE_NETWORK_FRAME_TCP_FLAGS_psh | SERVICE_NETWORK_FRAME_TCP_FLAGS_ack
	jnz	service_network_tcp_psh_ack	; tak

.end:
	; przywróć oryginalne rejestry
	pop	rax

	; usuń kod błędu z stosu
	add	rsp,	STATIC_QWORD_SIZE_byte

	; powrót z procedury
	jmp	service_network.end

	macro_debug	"service_network_tcp"

;===============================================================================
; wejście:
;	rbx - rozmiar nagłówka IP
;	rsi - wskaźnik do pakietu przychodzącego
;	rdi - wskaźnik do połączenia na stosie
service_network_tcp_psh_ack:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rdi
	push	rsi

	; pobierz rozmiar danych w ramce TCP
	movzx	ecx,	word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.total_length]
	rol	cx,	STATIC_REPLACE_AL_WITH_HIGH_shift	; Little-Endian
	sub	cx,	bx	; koryguj rozmiar o nagłówek IP

	; zachowaj rozmiar danych ramki TCP w zmiennej lokalnej
	push	rcx

	; pobierz numer portu docelowego
	movzx	eax,	word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + rbx + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.port_target]
	rol	ax,	STATIC_REPLACE_AL_WITH_HIGH_shift	; Little-Endian
	shl	rax,	STATIC_MULTIPLE_BY_32_shift	; zamień na przesunięcie wew. tablicy portów

	; oblicz rozmiar nagłówka TCP
	movzx	edx,	byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + rbx + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.header_length]
	shr	dl,	STATIC_MOVE_AL_HALF_TO_HIGH_shift	; przesuń ilość podwójnych słów na młodszą pozycję
	shl	dx,	STATIC_MULTIPLE_BY_4_shift	; zamień ilość podwójnych słów na Bajty

	; przesuń na początek przestrzeni pakietu
	mov	rdi,	rsi

	; zawartość danych ramki TCP
	add	rsi,	SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE
	add	rsi,	rbx
	add	rsi,	rdx

	; wykonaj
	rep	movsb

	; wyczyść pozostałą przestrzeń ramki
	mov	rcx,	KERNEL_PAGE_SIZE_byte
	sub	rcx,	qword [rsp]
	rep	stosb

	; ustaw wskaźnik na wpis dla portu w tablicy
	mov	rsi,	qword [service_network_port_table]
	add	rsi,	rax

	; ilość czasu jaką odczekany na wykonanie poniższej operacji
	mov	cl,	SERVICE_NETWORK_RECEIVE_PUSH_WAIT_limit

.wait:
	; czekaj na zwolnienie danych na porcie
	bts	word [rsi + SERVICE_NETWORK_STRUCTURE_PORT.cr3_and_flags],	SERVICE_NETWORK_PORT_FLAG_BIT_empty
	jnc	.empty	; w porcie znajdują się już dane, czekaj

	; odczekaj kolejkę
	hlt

	; koniec oczekiwania?
	dec	cl
	jnz	.wait	; nie

	; port w dalszym ciągu zapełniony danymi

	; zwolnij zmienną lokalną
	add	rsp,	STATIC_QWORD_SIZE_byte

	; koniec obsługi
	jmp	.end

.empty:
	; uzupełnij wpis o

	; identyfikator połączenia
	mov	rax,	qword [rsp + STATIC_QWORD_SIZE_byte * 0x02]
	mov	qword [rsi + SERVICE_NETWORK_STRUCTURE_PORT.tcp_connection],	rax

	; rozmair danych przestrzeni
	pop	qword [rsi + SERVICE_NETWORK_STRUCTURE_PORT.size]

	; wskaźnik do danych przestrzeni
	mov	rax,	qword [rsp]
	mov	qword [rsi + SERVICE_NETWORK_STRUCTURE_PORT.address],	rax

	; oznacz port flagą: dane otrzymane
	or	byte [rsi + SERVICE_NETWORK_STRUCTURE_PORT.cr3_and_flags],	SERVICE_NETWORK_PORT_FLAG_received

	; przestrzeń przekazana do procesu
	mov	qword [rsp],	STATIC_EMPTY

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	jmp	service_network_tcp.end

	macro_debug	"service_network_tcp_psh_ack"

;===============================================================================
; wejście:
;	rbx - rozmiar nagłówka IP
;	rsi - wskaźnik do pakietu przychodzącego
;	rdi - wskaźnik do połączenia na stosie
service_network_tcp_fin:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	rdi

	; ustaw wskaźnik do połączenia w rejestrze źródłowym
	xchg	rsi,	rdi

	; usuń flagę ACK nawet, jeśli nie była oczekiwana
	and	byte [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags_request],	~SERVICE_NETWORK_FRAME_TCP_FLAGS_ack

	;-----------------------------------------------------------------------

	; zachowaj numer sekwencji nadawcy
	mov	eax,	dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + rbx + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.sequence]
	bswap	eax	; zachowaj w formacie Little-Endian
	inc	eax	; potwierdź otrzymanie chęci zakończenia połączenia
	mov	dword [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_sequence],	eax

	;-----------------------------------------------------------------------

	; nasz numer sekwencji
	mov	eax,	dword [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.request_acknowledgement]
	inc	eax
	mov	dword [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.host_sequence],	eax

	; nasz identyfikator
	inc	eax
	mov	dword [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.request_acknowledgement],	eax

	;-----------------------------------------------------------------------

	; zamknięcie połączenia
	mov	word [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags],	SERVICE_NETWORK_FRAME_TCP_FLAGS_ack | SERVICE_NETWORK_FRAME_TCP_FLAGS_fin

	; oczekuj flagi ACK w odpowiedzi
	mov	word [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags_request],	SERVICE_NETWORK_FRAME_TCP_FLAGS_ack

	;-----------------------------------------------------------------------
	; wyślij odpowiedź
	;-----------------------------------------------------------------------

	; przygotuj miejsce na odpowiedź
	call	kernel_memory_alloc_page
	jc	.error

	; spakuj dane ramki TCP
	mov	bl,	(SERVICE_NETWORK_STRUCTURE_FRAME_TCP.SIZE >> STATIC_DIVIDE_BY_4_shift) << STATIC_MOVE_AL_HALF_TO_HIGH_shift
	mov	ecx,	SERVICE_NETWORK_STRUCTURE_FRAME_TCP.SIZE
	call	service_network_tcp_wrap

	; wyślij pakiet
	mov	ax,	SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.SIZE + STATIC_DWORD_SIZE_byte
	call	service_network_transfer

	; połączenie zatwierdzone
	jmp	.end

.error:
	; wyrejestruj połączenie
	mov	byte [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.status],	STATIC_EMPTY

.end:
	; przywóć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	jmp	service_network_tcp.end

	macro_debug	"service_network_tcp_fin"

;===============================================================================
; wejście:
;	rsi - wskaźnik do pakietu przychodzącego
;	rdi - wskaźnik do połączenia na stosie
service_network_tcp_ack:
	; zachowaj oryginalne rejestry
	push	rsi
	push	rdi

	xchg	bx,bx

	; oczekiwaliśmy potwierdzenia?
	test	word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags_request],	SERVICE_NETWORK_FRAME_TCP_FLAGS_ack
	jz	.end	; nie

	; usuń oczekiwaną flagę z stosu
	and	word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags_request],	~SERVICE_NETWORK_FRAME_TCP_FLAGS_ack

	; połączenie zostało zakończone?
	test	word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags],	SERVICE_NETWORK_FRAME_TCP_FLAGS_fin | SERVICE_NETWORK_FRAME_TCP_FLAGS_ack
	jz	.end	; nie

	; zwolnij wpis na stosie dotyczący połączenia
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags],	STATIC_EMPTY

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi

	; powrót z procedury
	jmp	service_network_tcp.end

	macro_debug	"service_network_tcp_ack"

;===============================================================================
; wejście:
;	rsi - wskaźnik do pakietu przychodzącego
; wyjście:
;	rbx - rozmiar nagłówka ramki IP
;	rdi - wskaźnik do połączenia
service_network_tcp_find:
 	; zachowaj oryginalne rejestry
 	push	rax
 	push	rcx
	push	rbx
 	push	rdi

	; rozmiar nagłówka ramki IP
	movzx	ebx,	byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.version_and_ihl]
	and	bl,	SERVICE_NETWORK_FRAME_IP_HEADER_LENGTH_mask
	shl	bl,	STATIC_MULTIPLE_BY_4_shift

	; przeszukaj stos TCP
	mov	rcx,	(SERVICE_NETWORK_STACK_SIZE_page << KERNEL_PAGE_SIZE_shift) / SERVICE_NETWORK_STRUCTURE_TCP_STACK.SIZE
	mov	rdi,	qword [service_network_stack_address]

.loop:
	; adres MAC klienta, poprawny?
	mov	eax,	dword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.source]
	rol	rax,	STATIC_REPLACE_EAX_WITH_HIGH_shift
	mov	ax,	word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.source + SERVICE_NETWORK_STRUCTURE_MAC.4]
	ror	rax,	STATIC_REPLACE_EAX_WITH_HIGH_shift
	cmp	qword [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_mac],	rax
	jne	.next	; nie, następny wpis

	; adres IPv4 klienta, poprawny?
	mov	eax,	dword [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_ipv4]
	cmp	dword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.source_address],	eax
	jne	.next	; nie, następny wpis

	; port docelowy poprawny?
	mov	ax,	word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.host_port]
	cmp	word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + rbx + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.port_target],	ax
	jne	.next	; nie, następny wpis

	; port źródłowy, porawny?
	mov	ax,	word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_port]
	cmp	word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + rbx + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.port_source],	ax
	je	.found	; nie, następny wpis

.next:
	; przesuń wskaźnik na następny wpis
	add	rdi,	SERVICE_NETWORK_STRUCTURE_TCP_STACK.SIZE

	; koniec stosu?
	dec	rcx
	jnz	.loop	; nie

	; brak zarejestrowanego połączenia dla pakietu przychodzącego
 	stc

 	; koniec procedury
 	jmp	.end

.found:
	; zwróć rozmiar nagłówka IPv4
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	rbx

	; zwróć wskaźnik do połączenia
	mov	qword [rsp],	rdi

.end:
 	; przywróć oryginalne rejestry
 	pop	rdi
	pop	rbx
 	pop	rcx
 	pop	rax

 	; powrót z procedury
 	ret

	macro_debug	"service_network_tcp_find"

;===============================================================================
; wejście:
;	rsi - wskaźnik do pakietu przychodzącego
service_network_tcp_syn:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	rdi

	; przeszukaj stos TCP
	mov	rcx,	(SERVICE_NETWORK_STACK_SIZE_page << KERNEL_PAGE_SIZE_shift) / SERVICE_NETWORK_STRUCTURE_TCP_STACK.SIZE
	mov	rdi,	qword [service_network_stack_address]

.search:
	; za wolnym miejscem
	lock	bts word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.status],	SERVICE_NETWORK_STACK_FLAG_busy
	jnc	.found	; znaleziono

	; przesuń wskaźnik na następny wpis połączenia
	add	rdi,	SERVICE_NETWORK_STRUCTURE_TCP_STACK.SIZE

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
	movzx	ecx,	byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.version_and_ihl]
	and	cl,	SERVICE_NETWORK_FRAME_IP_HEADER_LENGTH_mask
	shl	cl,	STATIC_MULTIPLE_BY_4_shift

	; zamień na adres względny ramki TCP
	add	ecx,	SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE

	;-----------------------------------------------------------------------

	; zachowaj numer portu usługi
	mov	ax,	word [rsi + rcx + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.port_target]
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.host_port],	ax

	; zachowaj numer portu nadawcy
	mov	ax,	word [rsi + rcx + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.port_source]
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_port],	ax

	; zachowaj numer sekwencji nadawcy
	mov	eax,	dword [rsi + rcx + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.sequence]
	bswap	eax	; zachowaj w formacie Little-Endian
	inc	eax	; potwierdź otrzymanie chęci nawiązania połączenia
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_sequence],	eax

	; zachowaj adres MAC nadawcy
	mov	rcx,	qword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.source]
	shl	rcx,	STATIC_MOVE_AX_TO_HIGH_shift
	shr	rcx,	STATIC_MOVE_HIGH_TO_AX_shift
	mov	qword [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_mac],	rcx

	; zachowaj adres IPv4 nadawcy
	mov	ecx,	dword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.source_address]
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_ipv4],	ecx

	;-----------------------------------------------------------------------

	; nasz identyfikator
	mov	word [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.request_acknowledgement],	STATIC_EMPTY + 0x01

	; nasz numer sekwencji
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.host_sequence],	STATIC_EMPTY

	; domyślny rozmiar okna
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.window_size],	SERVICE_NETWORK_FRAME_TCP_WINDOW_SIZE_default

	;-----------------------------------------------------------------------

	; akceptuj połączenie
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags],	SERVICE_NETWORK_FRAME_TCP_FLAGS_syn | SERVICE_NETWORK_FRAME_TCP_FLAGS_ack

	; oczekuj flagi ACK w odpowiedzi
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags_request],	SERVICE_NETWORK_FRAME_TCP_FLAGS_ack

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
	mov	bl,	(SERVICE_NETWORK_STRUCTURE_FRAME_TCP.SIZE >> STATIC_DIVIDE_BY_4_shift) << STATIC_MOVE_AL_HALF_TO_HIGH_shift
	mov	ecx,	SERVICE_NETWORK_STRUCTURE_FRAME_TCP.SIZE
	call	service_network_tcp_wrap

	; wyślij pakiet
	mov	ax,	SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.SIZE + STATIC_DWORD_SIZE_byte
	call	service_network_transfer

	; połączenie zatwierdzone
	jmp	.end

.error:
	; wyrejestruj połączenie
	mov	byte [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.status],	STATIC_EMPTY

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	jmp	service_network_tcp.end

	macro_debug	"service_network_tcp_syn"

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
;	ecx - rozmiar ramki TCP w Bajtach
;	rsi - wskaźnik do właściwości połączenia
;	rdi - wskaźnik do przestrzeni pakietu do wysłania
; wyjście:
;	eax - suma kontrolna pseudo nagłówka
service_network_tcp_pseudo_header:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdi

	; konfiguruj pseudo nagłówek

	; nadawca
	mov	eax,	dword [driver_nic_i82540em_ipv4_address]
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE - SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.source_ipv4],	eax

	; adresat
	mov	eax,	dword [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_ipv4]
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE - SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.target_ipv4],	eax

	; wyczyść wartość zarezerwowaną
	mov	byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE - SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.reserved],	STATIC_EMPTY

	; protokół
	mov	byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE - SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.protocol],	SERVICE_NETWORK_FRAME_TCP_PROTOCOL_default

	; rozmiar ramki TCP
	rol	cx,	STATIC_REPLACE_AL_WITH_HIGH_shift	; zamień na Big-Endian
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE - SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.segment_length],	cx

	; oblicz sumę kontrolną pseudo nagłówka
	xor	eax,	eax
	mov	ecx,	SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE >> STATIC_DIVIDE_BY_2_shift
	add	rdi,	SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE - SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE
	call	service_network_checksum_part

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx

	; powrót z podprocedury
	ret

	macro_debug	"service_network_tcp_pseudo_header"

;===============================================================================
; wejście:
;	cx - numer portu
; wyjście:
;	Flags CF, jeśli zajęty
service_network_tcp_port_assign:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi

	; numer portu obsługiwany?
	cmp	cx,	512
	jnb	.error	; nie

	; zamień numer portu na wskaźnik pośredni
	and	ecx,	STATIC_WORD_mask
	shl	cx,	STATIC_MULTIPLE_BY_32_shift

	; pobierz PID procesu
	mov	rax,	cr3

	; załaduj do tablicy portów identyfikator właściciela (zarazem wyczyść flagi)
	mov	rdi,	qword [service_network_port_table]
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

	macro_debug	"service_network_tcp_port_assign"

;===============================================================================
; wejście:
;	ecx - numer portu do sprawdzenia
; wyjście:
;	Flaga CF, jeśli brak danych na porcie
;	rbx - identyfikator połączenia
;	ecx - rozmiar danych w przestrzeni
;	rsi - wskaźnik do przestrzeni danych
service_network_tcp_port_receive:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi

	; zamień numer portu na wskaźnik pośredni
	and	ecx,	STATIC_WORD_mask
	shl	cx,	STATIC_MULTIPLE_BY_32_shift

	; ustaw wskaźnik wpis portu w tablicy
	mov	rsi,	qword [service_network_port_table]
	add	rsi,	rcx

	; pobierz CR3 procesu
	mov	rax,	cr3

	; port należy do procesu?
	mov	rcx,	qword [rsi + SERVICE_NETWORK_STRUCTURE_PORT.cr3_and_flags]
	and	cx,	KERNEL_PAGE_mask
	cmp	rcx,	rax
	jne	.error	; nie

	; port zawiera dane do przetworzenia?
	test	word [rsi + SERVICE_NETWORK_STRUCTURE_PORT.cr3_and_flags],	SERVICE_NETWORK_PORT_FLAG_empty | SERVICE_NETWORK_PORT_FLAG_received
	jz	.error	; nie

	; wyłącz flagę: dane przychodzące
	and	word [rsi + SERVICE_NETWORK_STRUCTURE_PORT.cr3_and_flags],	~SERVICE_NETWORK_PORT_FLAG_BIT_received

	; zwróć identyfikator połączenia
	mov	rbx,	qword [rsi + SERVICE_NETWORK_STRUCTURE_PORT.tcp_connection]

	; zwróć rozmiar danych w przestrzeni
	mov	rcx,	qword [rsi + SERVICE_NETWORK_STRUCTURE_PORT.size]
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	rcx

	; zwróć wskaźnik do przestrzeni danych
	mov	rsi,	qword [rsi + SERVICE_NETWORK_STRUCTURE_PORT.address]
	mov	qword [rsp],	rsi

	; zwróć do procesu informacje
	jmp	.end

.error:
	; flaga, błąd
	stc

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"service_network_tcp_port_receive"

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

%ifdef	DEBUG
	; debug
	push	rcx
	push	rsi
	mov	ecx,	kernel_debug_string_arp_end - kernel_debug_string_arp
	mov	rsi,	kernel_debug_string_arp
	call	kernel_video_string
	pop	rsi
	pop	rcx
%endif

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

%ifdef	DEBUG
	; debug
	push	rcx
	push	rsi
	mov	ecx,	kernel_debug_string_icmp_end - kernel_debug_string_icmp
	mov	rsi,	kernel_debug_string_icmp
	call	kernel_video_string
	pop	rsi
	pop	rcx
%endif

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
;	rax - pusty lub kontynuacja poprzedniej sumy kontrolnej
;	rcx - rozmiar przestrzeni w słowach (po 2 Bajty)
;	rdi - wskaźnik do przeliczanej przestrzeni
; wyjście:
;	ax - suma kontrolna (Little-Endian)
service_network_checksum:
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

	macro_debug	"service_network_checksum"

;===============================================================================
; wejście:
;	rax - pusty lub kontynuacja poprzedniej sumy kontrolnej
;	ecx - rozmiar przestrzeni w słowach (po 2 Bajty)
;	rdi - wskaźnik do przeliczanej przestrzeni
; wyjście:
;	ax - suma kontrolna (Little-Endian)
service_network_checksum_part:
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

	macro_debug	"service_network_checksum_part"
