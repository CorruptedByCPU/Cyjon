;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

VARIABLE_DAEMON_TCP_IP_STACK_NAME_COUNT		equ	20
variable_daemon_tcp_ip_stack_name		db	"network tcp/ip stack"

; flaga, demon ethernet został prawidłowo uruchomiony
variable_daemon_tcp_ip_stack_semaphore		db	VARIABLE_FALSE

; miejsce na przetwarzane pakiety
VARIABLE_DAEMON_TCP_IP_STACK_CACHE_SIZE		equ	8	; max 256
VARIABLE_DAEMON_TCP_IP_STACK_CACHE_FLAG_EMPTY	equ	VARIABLE_FALSE
VARIABLE_DAEMON_TCP_IP_STACK_CACHE_FLAG_READY	equ	VARIABLE_TRUE
variable_daemon_tcp_ip_stack_cache_in		dq	VARIABLE_EMPTY
variable_daemon_tcp_ip_stack_cache_out		dq	VARIABLE_EMPTY

struc	STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_IN
	.flag	resb	1
	.data	resb	VARIABLE_MEMORY_PAGE_SIZE - VARIABLE_BYTE_SIZE
	.SIZE	resb	1
endstruc

struc	STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_OUT
	.flag	resb	1
	.id	resb	8
	.size	resb	8
	.data	resb	VARIABLE_MEMORY_PAGE_SIZE - VARIABLE_BYTE_SIZE
	.SIZE	resb	1
endstruc

; stos TCP/IP
VARIABLE_DAEMON_TCP_IP_STACK_SIZE		equ	1
variable_daemon_tcp_ip_stack			dq	VARIABLE_EMPTY
variable_daemon_tcp_ip_stack_count		dq	VARIABLE_DAEMON_TCP_IP_STACK_SIZE * VARIABLE_MEMORY_PAGE_SIZE / STRUCTURE_DAEMON_TCP_IP_STACK.SIZE

struc	STRUCTURE_DAEMON_TCP_IP_STACK
	.ethernet_source			resb	6
	.ip_source_address			resb	4
	.tcp_source_port			resb	2
	.tcp_destination_port			resb	2
	.tcp_sequence_number			resb	4
	.tcp_acknowledgement_number		resb	4
	.tcp_acknowledgement_number_remote	resb	4
	.SIZE					resb	1
endstruc

; obsługa pierwszych 256 portów [0..255], VARIABLE_DAEMON_TCP_IP_STACK_TABLE_PORT.SIZE -> Bajtów na opis jednego rekordu/portu
VARIABLE_DAEMON_TCP_IP_STACK_TABLE_PORT_SIZE	equ	VARIABLE_MEMORY_PAGE_SIZE
variable_daemon_tcp_ip_stack_table_port		dq	VARIABLE_EMPTY

; struktura rekordu opisującego zajęty port tcp
struc STRUCTURE_DAEMON_TCP_IP_STACK_TABLE_PORT
	.cr3	resq	1
	.size	resq	1
	.rdi	resq	1
	.SIZE	resb	1
endstruc

; miejsce na przygotowywanie pakietów zwrotnych
variable_daemon_tcp_ip_stack_respond		dq	VARIABLE_EMPTY

variable_daemon_tcp_ip_stack_pseudo_header	db	0, 0, 0, 0	; source address
						db	0, 0, 0, 0	; target address
						db	VARIABLE_EMPTY
						db	VARIABLE_NETWORK_FRAME_IP_FIELD_PROTOCOL_TCP
						dw	VARIABLE_NETWORK_FRAME_TCP_SIZE << 8

struc STRUCTURE_DAEMON_TCP_IP_STACK_PSEUDO_HEADER
	.source_address	resb	4
	.target_address	resb	4
	.null		resb	1
	.protocol	resb	1
	.tcp_frame_size	resb	2
	.SIZE		resb	1
endstruc

; 64 Bitowy kod programu
[BITS 64]

daemon_tcp_ip_stack:
	; demon ethernet włączony?
	cmp	byte [variable_daemon_ethernet_semaphore],	VARIABLE_FALSE
	je	daemon_tcp_ip_stack	; czekaj

	; rozmiar buforu
	mov	rcx,	VARIABLE_DAEMON_TCP_IP_STACK_CACHE_SIZE

.wait_for_cache_in:
	; przydziel przestrzeń pod bufor pakietów przychodzących
	call	cyjon_page_find_free_memory_physical
	cmp	rdi,	VARIABLE_EMPTY
	je	.wait_for_cache_in	; brak miejsca, czekaj

	; zapisz adres
	call	cyjon_page_clear_few
	mov	qword [variable_daemon_tcp_ip_stack_cache_in],	rdi

.wait_for_cache_out:
	; przydziel przestrzeń pod bufor pakietów wychodzących
	call	cyjon_page_find_free_memory_physical
	cmp	rdi,	VARIABLE_EMPTY
	je	.wait_for_cache_out	; brak miejsca, czekaj

	; zapisz adres
	call	cyjon_page_clear_few
	mov	qword [variable_daemon_tcp_ip_stack_cache_out],	rdi

.wait_for_port_table:
	; przydziel miejsce pod tablicę portów
	call	cyjon_page_allocate
	cmp	rdi,	VARIABLE_EMPTY
	je	.wait_for_port_table	; brak miejsca

	; zapisz adres tablicy portów
	call	cyjon_page_clear	; wszystkie porty dostępne
	mov	qword [variable_daemon_tcp_ip_stack_table_port],	rdi

	; rozmiar stosu TCP/IP
	mov	rcx,	VARIABLE_DAEMON_TCP_IP_STACK_SIZE

.wait_for_stack:
	; przydziel miejsce pod stos TCP/IP
	call	cyjon_page_find_free_memory_physical
	cmp	rdi,	VARIABLE_EMPTY
	je	.wait_for_stack

	; zapisz adres stosu TCP/IP
	call	cyjon_page_clear_few
	mov	qword [variable_daemon_tcp_ip_stack],	rdi

.wait_for_tmp:
	; przydziel miejsce na bufor przetwarzania pakietów zwrotnych
	call	cyjon_page_allocate
	cmp	rdi,	VARIABLE_EMPTY
	je	.wait_for_tmp

	; zapisz adres
	mov	qword [variable_daemon_tcp_ip_stack_respond],	rdi

	;-----------------------------------------------------------------------
	; przygotuj wzór pakietu zwrotnego
	;-----------------------------------------------------------------------

	; dane ramki Ethernet --------------------------------------------------
	; nasz adres MAC
	mov	rax,	qword [variable_network_i8254x_mac_address]
	mov	dword [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_SENDER],	eax
	shr	rax,	VARIABLE_MOVE_HIGH_RAX_TO_EAX
	mov	word [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_SENDER + VARIABLE_DWORD_SIZE],	ax
	; typ ramki Ethernet > IP
	mov	word [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TYPE],	VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TYPE_IP

	; dane ramki IP --------------------------------------------------------
	; wersja pakietu i rozmiar nagłówka IP w podwójnych słowach
	mov	al,	01000000b	; wersja IPv4 (0100b)
	add	al,	00000101b	; rozmiar nagłówka, 5 x 32 Bity (0101b), domyślnie brak opcji
	mov	byte [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_VERSION_AND_IHL],	al
	; wyczyść informacje o Typie usługi, wykorzystywane np. w VoIP, QoS...
	mov	byte[ rdi + VARIABLE_NETWORK_FRAME_IP_FIELD_DSCP_AND_ECN],	VARIABLE_EMPTY
	; pole całkowity rozmiar ustaw na sumę rozmiarów ramek Ethernet + IP + TCP
	mov	ax,	VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_SIZE
	xchg	al,	ah
	mov	word [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_TOTAL_LENGTH],	ax
	; brak numeru identyfikacji, nasze pakiety nie ulegają fragmentacji
	mov	word [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_IDENTIFICATION],	VARIABLE_EMPTY
	; ustaw flagę DF i wyzeruj przesunięcie w fragmentacji
	mov	ax,	0000000001000000b
	mov	word [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_FLAGS_AND_FRAGMENT_OFFSET],	ax
	; czas życia datagramu maksymalny
	mov	byte [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_TTL],	VARIABLE_FULL
	; protokół warstwy wyższej TCP
	mov	byte [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_PROTOCOL],	VARIABLE_NETWORK_FRAME_IP_FIELD_PROTOCOL_TCP
	; brak sumy kontrolnej, ip źródła i opcji
	; wartości te ulegają częstej modyfikacji

	; dane ramki TCP -------------------------------------------------------
	; rozmiar nagłówka/rozmiar przesunięcia do danych, miejsca na opcje
	mov	byte [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_HEADER_LENGTH],	VARIABLE_NETWORK_FRAME_TCP_FIELD_HEADER_LENGTH_DEFAULT
	; szerokość okna to największy rozmiar przyjmowanego przez nas pakietu
	mov	ax,	STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_IN.SIZE - VARIABLE_BYTE_SIZE
	xchg	al,	ah
	mov	word [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_WINDOW_SIZE],	ax

	;-----------------------------------------------------------------------

	; demon tcp/ip gotowy
	mov	byte [variable_daemon_tcp_ip_stack_semaphore],	VARIABLE_TRUE

.out:
	; ilość możliwych pakietów przechowywanych w buforze przychodzącym
	mov	rcx,	VARIABLE_DAEMON_TCP_IP_STACK_CACHE_SIZE * VARIABLE_MEMORY_PAGE_SIZE / STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_OUT.SIZE

	; wskaźnik do bufora przychodzącego
	mov	rsi,	qword [variable_daemon_tcp_ip_stack_cache_out]

.out_search:
	; przeszukaj bufor przychodzący za pakietem
	cmp	qword [rsi + STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_OUT.id],	 VARIABLE_EMPTY
	ja	.out_found

.out_continue:
	; następny rekord
	add	rsi,	STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_OUT.SIZE
	loop	.out_search

	; brak pakietów przychodzących

	; sprawdź bufor przychodzący
	jmp	.in

.out_found:
	; zachowaj numer przetwarzanego rekordu
	push	rcx

	; zachowaj oryginalny wskaźnik w buforze wyjściowym stosu TCP/IP
	push	rsi

	;=======================================================================
	; wyślij pakiet z odpowiedzią  -----------------------------------------


	; oblicz adres rekordu na stosie TCP/IP
	mov	rdi,	qword [rsi + STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_OUT.id]

	; zapamiętaj
	push	rdi

	; rozmiar danych do wysłania
	mov	rcx,	qword [rsi + STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_OUT.size]

	; przygotuj podstawowe informacje w pakiecie zwrotnym
	push	rsi
	mov	rsi,	rdi
	call	daemon_tcp_ip_stack_prepare_respond_from_stack
	pop	rsi

	; zapamiętaj rozmiar danych do wysłania i wskaźnik do pakietu zwrotnego
	push	rcx
	; skopiuj dane do pakietu wysyłanego
	add	rsi,	STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_OUT.data
	add	rdi,	VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_SIZE
	rep	movsb
	; przywróć rozmiar załadowanych danych i wskaźnik początku pakietu zwrotnego
	pop	rcx

	; przywróć wskaźnik do rekordu stosu TCP/IP
	pop	rsi

	mov	rdi,	qword [variable_daemon_tcp_ip_stack_respond]

	; oblicz numer spodziewanej odpowiedzi z pola akceptacji
	mov	rbx,	qword [rsi + STRUCTURE_DAEMON_TCP_IP_STACK.tcp_sequence_number]
	add	ebx,	ecx
	; zapamiętaj numer akceptacji
	mov	dword [rsi + STRUCTURE_DAEMON_TCP_IP_STACK.tcp_acknowledgement_number],	ebx

	; ustaw flagę wysyłania danych do klienta FIN + PSH + ACK
	mov	byte [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS],	VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS_FIN + VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS_PSH + VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS_ACK

	; ustaw rozmiar ramki IP wraz z danymi
	push	rcx
	add	rcx,	VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_SIZE
	xchg	cl,	ch
	mov	word [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_TOTAL_LENGTH],	cx

	; nasz numer sekwencji
	mov	eax,	dword [rsi + STRUCTURE_DAEMON_TCP_IP_STACK.tcp_sequence_number]
	call	cyjon_network_convert_between_little_big_endian
	mov	dword [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_SEQUENCE_NUMBER],	eax

	; wylicz sumę kontrolną rameki TCP
	pop	rcx
	call	daemon_tcp_ip_stack_prepare_checksums_from_stack

	; wyślij odpowiedź do klienta z danymi
	add	ecx,	VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_SIZE
	mov	rsi,	rdi
	call	cyjon_network_i8254x_transmit_packet

.out_mismatch:
	; przywróć adres przetwarzanego pakietu
	pop	rsi

	; pakiet został wysłany lub zignorowany
	mov	qword [rsi + STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_OUT.id],	VARIABLE_EMPTY
	mov	byte [rsi + STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_OUT.flag],	VARIABLE_DAEMON_TCP_IP_STACK_CACHE_FLAG_EMPTY

	; przywróć numer przetwarzanego pakietu
	pop	rcx

	; kontynuuj
	jmp	.out_continue

.in:
	; ilość możliwych pakietów przechowywanych w buforze przychodzącym
	mov	rcx,	VARIABLE_DAEMON_TCP_IP_STACK_CACHE_SIZE * VARIABLE_MEMORY_PAGE_SIZE / STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_IN.SIZE

	; wskaźnik do bufora przychodzącego
	mov	rsi,	qword [variable_daemon_tcp_ip_stack_cache_in]

.in_search:
	; przeszukaj bufor przychodzący za pakietem
	cmp	byte [rsi + STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_IN.flag],	 VARIABLE_DAEMON_TCP_IP_STACK_CACHE_FLAG_READY
	je	.in_found

.in_continue:
	; następny rekord
	add	rsi,	STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_IN.SIZE
	loop	.in_search

	; brak pakietów przychodzących

	; sprawdź bufor wychodzący od początku
	jmp	.out

.in_found:
	; zachowaj numer przetwarzanego pakietu
	push	rcx

	; zachowaj wskaźnik do przestwarzanego pakietu
	push	rsi

	; przesuń wskaźnik na początek pakietu
	inc	rsi

	; sprawdź czy port docelowy jest obsługiwany
	movzx	rax,	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_DESTINATION_PORT]
	xchg	al,	ah
	cmp	rax,	VARIABLE_DAEMON_TCP_IP_STACK_TABLE_PORT_SIZE / STRUCTURE_DAEMON_TCP_IP_STACK_TABLE_PORT.SIZE
	ja	.in_no_port	; poinformuj klienta o braku otwartego portu

	; port obsługiwany, czy z portu korzysta jakiś proces?

	; oblicz pozycje portu/rekordu w tablicy
	mov	rcx,	STRUCTURE_DAEMON_TCP_IP_STACK_TABLE_PORT.SIZE
	xor	rdx,	rdx	; brak starszej części
	mul	rcx

	; sprawdź zawartość CR3 rekordu
	mov	rdi,	qword [variable_daemon_tcp_ip_stack_table_port]
	cmp	qword [rdi + rax + STRUCTURE_DAEMON_TCP_IP_STACK_TABLE_PORT.cr3],	VARIABLE_EMPTY
	je	.in_no_port	; brak procesu działającego na danym porcie

	; port jest wykorzystywany przez jakiś proces

	;-----------------------------------------------------------------------
	; główne procedury obsługi zdarzeń TCP/IP
	;-----------------------------------------------------------------------

	; prośba o nawiązanie połączenia?
	cmp	byte [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS],	VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS_SYN
	je	.in_syn

	; potwierdzenie otrzymania pakietu?
	cmp	byte [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS],	VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS_ACK
	je	.in_ack

	; przyszły dane do procesu?
	cmp	byte [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS],	VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS_PSH + VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS_ACK
	je	.in_psh

	; prośba o zakończenie połączenia?
	cmp	byte [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS],	VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS_FIN + VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS_ACK
	je	.in_fin

	; wymuszenie zakończenia połączenia
	cmp	byte [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS],	VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS_RST + VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS_ACK
	je	.in_rst

.in_mismatch:
	; przywróć adres przetwarzanego pakietu
	pop	rsi

	; pakiet został przetworzony lub zignorowany
	mov	byte [rsi + STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_IN.flag],	VARIABLE_DAEMON_TCP_IP_STACK_CACHE_FLAG_EMPTY

	; przywróć numer przetwarzanego pakietu
	pop	rcx

	; kontynuuj
	jmp	.in_continue

;-------------------------------------------------------------------------------
.in_no_port:
	; wyślij informacje o procesu obsługującego port -----------------------

	; przygotuj podstawowe informacje w pakiecie zwrotnym
	xor	rcx,	rcx	; brak danych do wysłania
	call	daemon_tcp_ip_stack_prepare_respond_from_source

	; pobierz numer sekwencji klienta i zapisz w polu akceptacji pakietu zwrotnego
	mov	eax,	dword [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_SEQUENCE_NUMBER]
	call	cyjon_network_convert_between_little_big_endian
	inc	eax	; odpowiedź potwierdzająca otrzymanie pakietu
	call	cyjon_network_convert_between_little_big_endian
	mov	dword [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_ACKNOWLEDGEMENT_NUMBER],	eax

	; nasz numer sekwencji rozpoczynającej połączenie
	mov	dword [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_SEQUENCE_NUMBER],	VARIABLE_EMPTY

	; zwróć informację o wymuszeniu rozłączenia z klientem
	mov	byte [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS],	VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS_RST + VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS_ACK

	; rozmiar okna ZERO, nie przyjmujemy więcej pakietów od klienta dotyczących tego połączenia
	mov	word [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_WINDOW_SIZE],	VARIABLE_EMPTY

	; wylicz sumy kontrolne ramek IP i TCP
	xor	rcx,	rcx	; brak danych do wysłania
	call	daemon_tcp_ip_stack_prepare_checksums

	; wyślij odpowiedź do klienta o niedostępnym porcie
	mov	rcx,	VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_SIZE
	mov	rsi,	rdi
	call	cyjon_network_i8254x_transmit_packet

	; koniec obsługi pakietu
	jmp	.in_mismatch

;-------------------------------------------------------------------------------
.in_syn:
	; sprawdź czy jest wolne miejsce na stosie do nawiązania połączenia
	cmp	qword [variable_daemon_tcp_ip_stack_count],	VARIABLE_EMPTY
	je	.in_mismatch	; brak miejsca, zignoruj nawiązanie połączenia

	; znajdź wolny rekord na stosie TCP/IP
	call	daemon_tcp_ip_stack_find_free_record

	; zachowaj wskaźnik do rekordu stosu
	push	rdi

	; zachowaj wskaźnik do pakietu przychodzącego
	push	rsi

	;-----------------------------------------------------------------------
	; pobierz wszystkie niezbędne informacje o połaczeniu i zachowaj na stosie
	;-----------------------------------------------------------------------

	; zapisz adres MAC nadawcy klienta
	mov	eax,	dword [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_SENDER]
	stosd
	mov	ax,	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_SENDER + VARIABLE_DWORD_SIZE]
	stosw

	; zapisz adres IPv4 ramki IP klienta
	mov	eax,	dword [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_SOURCE_ADDRESS]
	stosd

	; zapisz źródłowy numer portu ramki TCP klienta
	mov	ax,	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_SOURCE_PORT]
	xchg	al,	ah
	stosw

	; zapisz docelowy numer portu ramki TCP klienta
	mov	ax,	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_DESTINATION_PORT]
	xchg	al,	ah
	stosw

	; wyślij informacje o przyjęciu połączenia -----------------------------

	; przygotuj podstawowe informacje w pakiecie zwrotnym
	xor	rcx,	rcx	; brak danych do wysłania
	call	daemon_tcp_ip_stack_prepare_respond_from_source

	; wyślij potwierdzenie odebrania pakietu synchronizacji połączenia
	mov	eax,	dword [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_SEQUENCE_NUMBER]
	call	cyjon_network_convert_between_little_big_endian
	inc	eax
	call	cyjon_network_convert_between_little_big_endian
	; potwierdzenie zachowaj w polu akceptacji pakietu zwrotnego
	mov	dword [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_ACKNOWLEDGEMENT_NUMBER],	eax

	; inicjalizuj nasz numer sekwencji
	xor	eax,	eax	; w późniejszej wersji numer będzie losowy
	mov	dword [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_SEQUENCE_NUMBER],	eax
	; zachowaj informacje o numerze sekwencji i akceptacji(sekwencja + 1, jakiego się spodziewamy w odpowiedzi zwrotnej)
	mov	rsi,	qword [rsp + VARIABLE_QWORD_SIZE]
	mov	dword [rsi + STRUCTURE_DAEMON_TCP_IP_STACK.tcp_sequence_number],	eax
	inc	eax
	mov	dword [rsi + STRUCTURE_DAEMON_TCP_IP_STACK.tcp_acknowledgement_number],	eax

	; ustaw flagę potwierdzającą chęć nawiązania połaczenia SYN + ACK
	mov	byte [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS],	VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS_SYN + VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS_ACK

	; ustal maksymalny rozmiar pakietu jakiego się spodziewamy w odpowiedzi
	mov	ax,	STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_IN.SIZE / VARIABLE_WORD_SIZE	; połowa możliwej wielkości (debug)
	xchg	al,	ah
	mov	word [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_WINDOW_SIZE],	ax

	; wylicz sumy kontrolne ramek IP i TCP
	xor	rcx,	rcx	; brak danych do wysłania
	pop	rsi
	call	daemon_tcp_ip_stack_prepare_checksums

	; wyślij odpowiedź do klienta o niedostępnym porcie
	mov	rcx,	VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_SIZE
	mov	rsi,	rdi
	call	cyjon_network_i8254x_transmit_packet

	; usuń zmienną lokalną
	add	rsp,	VARIABLE_QWORD_SIZE

	; koniec obsługi pakietu
	jmp	.in_mismatch

;-------------------------------------------------------------------------------
.in_ack:
	; poszukaj rekordu na stocie TCP/IP, który wspomina pakiet
	call	daemon_tcp_ip_stack_find_record
	cmp	rdi,	VARIABLE_EMPTY
	je	.in_mismatch	; pakiet nie dotyczy naszych połączeń

	; sprawdź czy pakiet jest poprawny (czy go oczekiwaliśmy)
	mov	eax,	dword [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_ACKNOWLEDGEMENT_NUMBER]
	call	cyjon_network_convert_between_little_big_endian
	cmp	eax,	dword [rdi + STRUCTURE_DAEMON_TCP_IP_STACK.tcp_acknowledgement_number]
	jne	.in_mismatch	; pakiet niezarejestrowany, zignoruj

	; zapisz numer akceptacji w polu sekwencji
	mov	dword [rdi + STRUCTURE_DAEMON_TCP_IP_STACK.tcp_sequence_number],	eax

	; koniec obsługi pakietu
	jmp	.in_mismatch

;-------------------------------------------------------------------------------
.in_psh:
	; poszukaj rekordu na stocie TCP/IP, który wspomina pakiet
	call	daemon_tcp_ip_stack_find_record
	cmp	rdi,	VARIABLE_EMPTY
	je	.in_mismatch	; pakiet nie dotyczy naszych połączeń

	; zachowaj wskaźnik do pakietu klienta i rekordu stosu TCP/IP
	push	rsi
	push	rdi

	; wyślij informacje o poprawnym przyjęciu pakietu z danymi -------------

	; przygotuj nasz numer sekwencji
	mov	ebx,	dword [rdi + STRUCTURE_DAEMON_TCP_IP_STACK.tcp_sequence_number]
	mov	r8,	rbx

	; przygotuj podstawowe informacje w pakiecie zwrotnym
	xor	rcx,	rcx	; brak danych do wysłania
	call	daemon_tcp_ip_stack_prepare_respond_from_source

	; wyślij potwierdzenie odebrania pakietu z danymi
	mov	eax,	dword [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_SEQUENCE_NUMBER]
	call	cyjon_network_convert_between_little_big_endian
	; dodaj do numeru sekwencji klienta rozmiar odebranych danych
	movzx	ecx,	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_TOTAL_LENGTH]
	xchg	cl,	ch
	sub	cx,	VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_SIZE
	mov	r10,	rcx	; zachowaj rozmiar danych do skopiorania
	add	eax,	ecx
	call	cyjon_network_convert_between_little_big_endian
	; potwierdzenie zachowaj w polu akceptacji pakietu zwrotnego
	mov	dword [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_ACKNOWLEDGEMENT_NUMBER],	eax

	; zapamiętaj numer potwierdzenia dla klienta
	xchg	rdi,	qword [rsp]
	mov	dword [rdi + STRUCTURE_DAEMON_TCP_IP_STACK.tcp_acknowledgement_number_remote],	eax
	xchg	rdi,	qword [rsp]

	; wyślij nasz numer sekwencji kończącej połączenie
	mov	eax,	ebx
	call	cyjon_network_convert_between_little_big_endian
	mov	dword [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_SEQUENCE_NUMBER],	eax

	; ustaw flagę potwierdzającą odebranie danych ACK
	mov	byte [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS],	VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS_ACK

	; wylicz sumy kontrolne ramek IP i TCP
	xor	rcx,	rcx	; brak danych do wysłania
	call	daemon_tcp_ip_stack_prepare_checksums

	; wyślij odpowiedź do klienta o niedostępnym porcie
	mov	rcx,	VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_SIZE
	mov	rsi,	rdi
	call	cyjon_network_i8254x_transmit_packet

	; przywróć wskaźnik do pakietu klienta i rekordu stosu TCP/IP
	pop	rdi
	pop	rsi
	push	rdi

	;=======================================================================
	; przenieś dane do procesu
	;=======================================================================

	; sposów w jaki to robię, wymaga zmiany - cdn.

	; pobierz numer portu, do którego wysłać dane
	movzx	rax,	word [rdi + STRUCTURE_DAEMON_TCP_IP_STACK.tcp_destination_port]
	; przelicz na pozycję rekordu w tablicy portów
	mov	rcx,	STRUCTURE_DAEMON_TCP_IP_STACK_TABLE_PORT.SIZE
	xor	rdx,	rdx
	mul	rcx

	; pobierz CR3 procesu i wskaźnik docelowy danych
	mov	rdi,	qword [variable_daemon_tcp_ip_stack_table_port]
	mov	r8,	qword [rdi + rax + STRUCTURE_DAEMON_TCP_IP_STACK_TABLE_PORT.cr3]
	mov	r9,	qword [rdi + rax + STRUCTURE_DAEMON_TCP_IP_STACK_TABLE_PORT.rdi]
	mov	r12,	qword [rdi + rax + STRUCTURE_DAEMON_TCP_IP_STACK_TABLE_PORT.size]
	pop	r11	; wskaźnik do rekordu na stosie TCP/IP

	; wyłącz przerwanie zegara
	; debug
	cli

	; przełącz demona na przestrzeń pamięci procesu
	mov	rax,	cr3
	xchg	rax,	r8
	mov	cr3,	rax
	; UWAGA, BRAK DOSTĘPU DO STOSU <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

.restart:
	; znajdź wolny rekord w przestrzeni procesu
	mov	rdi,	r9
	mov	rcx,	r12

.search:
	; jeśli rekord nie posiada identyfikatora, wolny
	cmp	word [rdi + STRUCTURE_CACHE_DEFAULT.id],	VARIABLE_EMPTY
	je	.empty

	; rekord zajęty, przesuń wskaźnik na nastepny
	add	rdi,	STRUCTURE_CACHE_DEFAULT.SIZE

	; szukaj dalej
	loop	.search

	; szukaj ponownie
	jmp	.restart

.empty:
	; aktualizuj
	mov	r9,	rdi

	; przesuń wskaźnik na dane pakietu
	add	rsi,	VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_SIZE

	; zachowaj rozmiar przesłanych danych
	mov	rcx,	r10
	mov	qword [rdi + STRUCTURE_CACHE_DEFAULT.size],	rcx

	; skopiuj dane
	add	rdi,	STRUCTURE_CACHE_DEFAULT.data
	rep	movsb

	; rekord gotowy, udostępnij dla procesu wpisując identyfikator
	mov	qword [r9 + STRUCTURE_CACHE_DEFAULT.id],	r11

	; przełącz demona na własną przestrzeń pamięci
	mov	cr3,	r8

	; włącz przerwanie zegara
	sti

	; koniec obsługi pakietu
	jmp	.in_mismatch

;-------------------------------------------------------------------------------
.in_fin:
	; poszukaj rekordu na stocie TCP/IP, który wspomina pakiet
	call	daemon_tcp_ip_stack_find_record
	cmp	rdi,	VARIABLE_EMPTY
	je	.in_mismatch	; pakiet nie dotyczy naszych połączeń

	; zachowaj wskaźnik do rekordu stosu
	push	rdi

	; wyślij informacje o poprawnym zamknięciu połączenia-------------------

	; przygotuj nasz numer sekwencji
	mov	ebx,	dword [rdi + STRUCTURE_DAEMON_TCP_IP_STACK.tcp_sequence_number]

	; przygotuj podstawowe informacje w pakiecie zwrotnym
	xor	rcx,	rcx	; brak danych do wysłania
	call	daemon_tcp_ip_stack_prepare_respond_from_source

	; wyślij potwierdzenie odebrania pakietu zakończenia połączenia
	mov	eax,	dword [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_SEQUENCE_NUMBER]
	call	cyjon_network_convert_between_little_big_endian
	inc	eax
	call	cyjon_network_convert_between_little_big_endian
	; potwierdzenie zachowaj w polu akceptacji pakietu zwrotnego
	mov	dword [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_ACKNOWLEDGEMENT_NUMBER],	eax

	; wyślij nasz numer sekwencji kończącej połączenie
	mov	eax,	ebx
	call	cyjon_network_convert_between_little_big_endian
	mov	dword [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_SEQUENCE_NUMBER],	eax

	; ustaw flagę potwierdzającą zamknięcie połączenia ACK
	mov	byte [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS],	VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS_ACK

	; wylicz sumy kontrolne ramek IP i TCP
	xor	rcx,	rcx	; brak danych do wysłania
	call	daemon_tcp_ip_stack_prepare_checksums

	; wyślij odpowiedź do klienta o niedostępnym porcie
	mov	rcx,	VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_SIZE
	mov	rsi,	rdi
	call	cyjon_network_i8254x_transmit_packet

	; przywróć wskaźnik rekordu stosu TCP/IP
	pop	rdi

	; wyłącz rekord (zamknięcie połączenia)
	mov	word [rdi + STRUCTURE_DAEMON_TCP_IP_STACK.tcp_source_port],	VARIABLE_EMPTY

	; koniec obsługi pakietu
	jmp	.in_mismatch

;-------------------------------------------------------------------------------
.in_rst:
	; poszukaj rekordu na stocie TCP/IP, który wspomina pakiet
	call	daemon_tcp_ip_stack_find_record
	cmp	rdi,	VARIABLE_EMPTY
	je	.in_mismatch	; brak odpowiedniego wpisu na stosie TCP/IP, zignoruj

	; deaktywuj rekord połączenia na stocie TCP/IP
	mov	word [rdi + STRUCTURE_DAEMON_TCP_IP_STACK.tcp_source_port],	VARIABLE_FALSE

	; koniec obsługi pakietu
	jmp	.in_mismatch

;-------------------------------------------------------------------------------
; procedura wyszukuje rekord na stocie TCP/IP
;-------------------------------------------------------------------------------
; IN
;	rsi - wskaźnik do pakietu
; OUT
;	rdi - wskaźnk do rekordu na stosie TCP/IP
;
; pozostałe rejestry zachowane
daemon_tcp_ip_stack_find_record:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rbx
	push	rax

	; ustaw wskaźnik do stosu TCP/IP
	mov	rdi,	qword [variable_daemon_tcp_ip_stack]

	; sprawdź czy adres IP i numer portu z którego przyszła prośba o zamknięcie połączenia, jest zarejestrowany na stosie TCP/IP
	mov	eax,	dword [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_SOURCE_ADDRESS]
	mov	bx,	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_SOURCE_PORT]
	xchg	bl,	bh

	; ilość rekordów przechowywanych na stosie TCP/IP
	mov	rcx,	VARIABLE_MEMORY_PAGE_SIZE / STRUCTURE_DAEMON_TCP_IP_STACK.SIZE

.loop:
	; sprawdź port
	cmp	word [rdi + STRUCTURE_DAEMON_TCP_IP_STACK.tcp_source_port],	bx
	jne	.continue

.check:
	; sprawdź IP
	cmp	dword [rdi + STRUCTURE_DAEMON_TCP_IP_STACK.ip_source_address],	eax
	je	.found

.continue:
	; przesuń wskaźnik na następny rekord stosu TCP/IP
	add	rdi,	STRUCTURE_DAEMON_TCP_IP_STACK.SIZE

	; przeszukaj pozostałe rekordy
	loop	.loop

	; brak rekordu
	xor	rdi,	rdi

.found:
	; przywróć oryginalne rejestry
	pop	rcx
	pop	rbx
	pop	rax

	; koniec obsługi procedury
	ret

;-------------------------------------------------------------------------------
; procedura przygotowuje podstawowe informacje w pakiecie zwrotnym
;-------------------------------------------------------------------------------
; IN:
;	rsi - wskaźnik do pakietu przychodzącego
; OUT:
;	rdi - wskaźnk do pakietu wychodzącego
;
; pozostałe rejestry zachowane
;-------------------------------------------------------------------------------
daemon_tcp_ip_stack_prepare_respond_from_source:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx

	; konfiguruj pakiet zwrotny
	mov	rdi,	qword [variable_daemon_tcp_ip_stack_respond]

	; ustaw adres MAC klienta
	mov	eax,	dword [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_SENDER]
	mov	dword [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TARGET],	eax
	mov	ax,	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_SENDER + VARIABLE_DWORD_SIZE]
	mov	word [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TARGET + VARIABLE_DWORD_SIZE],	ax

	; ustaw adresy IP w ramce IP
	mov	eax,	dword [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_SOURCE_ADDRESS]
	mov	dword [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_TARGET_ADDRESS],	eax
	mov	eax,	dword [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_TARGET_ADDRESS]
	mov	dword [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_SOURCE_ADDRESS],	eax

	; ustaw rozmiar ramki IP
	add	rcx,	VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_SIZE
	xchg	cl,	ch
	mov	word [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_TOTAL_LENGTH],	cx

	; wyczyść starą sumę kontrolną ramki IP
	mov	word [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_HEADER_CHECKSUM],	VARIABLE_EMPTY

	; oblicz sumę kontrolną ramki IP
	xor	rax,	rax	; brak sumy sum kontrolnych
	mov	rcx,	VARIABLE_NETWORK_FRAME_IP_SIZE / VARIABLE_WORD_SIZE
	add	rdi,	VARIABLE_NETWORK_FRAME_ETHERNET_SIZE	; ustaw wskaźnk na początek ramki IP
	call	cyjon_network_checksum_create
	; ustaw skaźnik na początek pakietu
	sub	rdi,	VARIABLE_NETWORK_FRAME_ETHERNET_SIZE
	; zapisz sumę kontrolną ramki IP
	xchg	al,	ah
	mov	word [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_HEADER_CHECKSUM],	ax

	; ustaw numery portów w ramce TCP
	mov	ax,	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_SOURCE_PORT]
	mov	word [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_DESTINATION_PORT],	ax
	mov	ax,	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_DESTINATION_PORT]
	mov	word [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_SOURCE_PORT],	ax

	; przywróć oryginalne rejestry
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;-------------------------------------------------------------------------------
; procedura wylicza sumę kontrolną w ramce TCP
;-------------------------------------------------------------------------------
; IN:
;	rcx - rozmiar danych do wysłania
;	rsi - wskaźnik do pakietu przychodzącego
;	rdi - wskaźnik do pakietu wychodzącego
; OUT:
;	brak
;
; wszystkie rejestry zachowane
;-------------------------------------------------------------------------------
daemon_tcp_ip_stack_prepare_checksums:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi

	; wyczyść starą sumę kontrolną ramki TCP
	mov	word [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_CHECKSUM],	VARIABLE_EMPTY

	; przygotuj pseudo nagłówek --------------------------------------------
	mov	rdi,	variable_daemon_tcp_ip_stack_pseudo_header

	; ustaw adres ip klienta
	mov	eax,	dword [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_SOURCE_ADDRESS]
	mov	dword [rdi + STRUCTURE_DAEMON_TCP_IP_STACK_PSEUDO_HEADER.target_address],	eax
	; ustaw adres ip serwera
	mov	eax,	dword [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_TARGET_ADDRESS]
	mov	dword [rdi + STRUCTURE_DAEMON_TCP_IP_STACK_PSEUDO_HEADER.source_address],	eax

	; ustaw rozmiar ramki TCP wraz z danymi
	add	rcx,	VARIABLE_NETWORK_FRAME_TCP_SIZE
	push	rcx
	xchg	cl,	ch
	mov	word [rdi + STRUCTURE_DAEMON_TCP_IP_STACK_PSEUDO_HEADER.tcp_frame_size],	cx

	; wylicz sumę kontrolną pseudo nagłówka
	xor	rax,	rax	; brak sumy sum kontrolnych
	mov	rcx,	STRUCTURE_DAEMON_TCP_IP_STACK_PSEUDO_HEADER.SIZE / VARIABLE_WORD_SIZE
	call	cyjon_network_checksum_create

	; odneguj sumę kontrolną
	not	ax

	; oblicz sumę kontrolną ramki TCP w połączeniu z sumą kontrolną pseudo nagłówka TCP

	; ustaw wskaźnik na ramkę TCP pakietu zwrotnego
	mov	rdi,	qword [rsp + VARIABLE_QWORD_SIZE]
	add	rdi,	VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE
	pop	rcx
	shr	rcx,	VARIABLE_DIVIDE_BY_2
	call	cyjon_network_checksum_create

	; zapisz połączone sumy kontrolne w ramce TCP
	sub	rdi,	VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE
	xchg	al,	ah
	mov	word [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_CHECKSUM],	ax

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;-------------------------------------------------------------------------------
; procedura zwraca wskaźnik do wolnego rekordu na stosie TCP/IP
;-------------------------------------------------------------------------------
; IN:
;	brak
; OUT:
;	rdi - wskaźnik do wolnego rekordu
;
; pozostałe rejestry zachowane
;-------------------------------------------------------------------------------
daemon_tcp_ip_stack_find_free_record:
	; szukaj wolnego rekordu na stosie TCP/IP
	mov	rdi,	qword [variable_daemon_tcp_ip_stack]

.search:
	cmp	word [rdi + STRUCTURE_DAEMON_TCP_IP_STACK.tcp_source_port],	VARIABLE_EMPTY
	je	.empty

	; rekord zajęty, przesuń wskaźnik na nastepny
	add	rdi,	STRUCTURE_DAEMON_TCP_IP_STACK.SIZE

	; szukaj dalej
	jmp	.search

.empty:
	; powrót z procedury
	ret

;-------------------------------------------------------------------------------
; procedura przygotowuje podstawowe informacje w pakiecie zwrotnym
;-------------------------------------------------------------------------------
; IN:
;	rsi - wskaźnik rekordu na stosie TCP/IP
; OUT:
;	rdi - wskaźnk do pakietu wychodzącego
;
; pozostałe rejestry zachowane
;-------------------------------------------------------------------------------
daemon_tcp_ip_stack_prepare_respond_from_stack:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi

	; konfiguruj pakiet zwrotny
	mov	rdi,	qword [variable_daemon_tcp_ip_stack_respond]

	; ustaw adres MAC klienta
	mov	eax,	dword [rsi + STRUCTURE_DAEMON_TCP_IP_STACK.ethernet_source]
	mov	dword [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TARGET],	eax
	mov	ax,	word [rsi + STRUCTURE_DAEMON_TCP_IP_STACK.ethernet_source + VARIABLE_DWORD_SIZE]
	mov	word [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TARGET + VARIABLE_DWORD_SIZE],	ax

	; ustaw adresy IP w ramce IP
	mov	eax,	dword [rsi + STRUCTURE_DAEMON_TCP_IP_STACK.ip_source_address]
	mov	dword [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_TARGET_ADDRESS],	eax
	mov	eax,	dword [variable_network_ip]
	mov	dword [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_SOURCE_ADDRESS],	eax

	; ustaw rozmiar ramki IP
	add	rcx,	VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_SIZE
	xchg	cl,	ch
	mov	word [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_TOTAL_LENGTH],	cx

	; wyczyść starą sumę kontrolną ramki IP
	mov	word [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_HEADER_CHECKSUM],	VARIABLE_EMPTY

	; oblicz sumę kontrolną ramki IP
	xor	rax,	rax	; brak sumy sum kontrolnych
	mov	rcx,	VARIABLE_NETWORK_FRAME_IP_SIZE / VARIABLE_WORD_SIZE
	add	rdi,	VARIABLE_NETWORK_FRAME_ETHERNET_SIZE	; ustaw wskaźnk na początek ramki IP
	call	cyjon_network_checksum_create
	; ustaw skaźnik na początek pakietu
	sub	rdi,	VARIABLE_NETWORK_FRAME_ETHERNET_SIZE
	; zapisz sumę kontrolną ramki IP
	xchg	al,	ah
	mov	word [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_HEADER_CHECKSUM],	ax

	; ustaw numery portów w ramce TCP
	mov	ax,	word [rsi + STRUCTURE_DAEMON_TCP_IP_STACK.tcp_source_port]
	xchg	al,	ah
	mov	word [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_DESTINATION_PORT],	ax
	mov	ax,	word [rsi + STRUCTURE_DAEMON_TCP_IP_STACK.tcp_destination_port]
	xchg	al,	ah
	mov	word [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_SOURCE_PORT],	ax

	; potwierdź odbiór poprzedniego pakietu
	mov	eax,	dword [rsi + STRUCTURE_DAEMON_TCP_IP_STACK.tcp_acknowledgement_number_remote]
	mov	dword [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_ACKNOWLEDGEMENT_NUMBER],	eax

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;-------------------------------------------------------------------------------
; procedura wylicza sumę kontrolną w ramce TCP
;-------------------------------------------------------------------------------
; IN:
;	rcx - rozmiar danych do wysłania
;	rsi - wskaźnik do rekordu stosu TCP/IP
;	rdi - wskaźnik do pakietu wychodzącego
; OUT:
;	brak
;
; wszystkie rejestry zachowane
;-------------------------------------------------------------------------------
daemon_tcp_ip_stack_prepare_checksums_from_stack:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi

	; wyczyść starą sumę kontrolną ramki TCP
	mov	word [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_CHECKSUM],	VARIABLE_EMPTY

	; przygotuj pseudo nagłówek --------------------------------------------
	mov	rdi,	variable_daemon_tcp_ip_stack_pseudo_header

	; ustaw adres ip klienta
	mov	eax,	dword [rsi + STRUCTURE_DAEMON_TCP_IP_STACK.ip_source_address]
	mov	dword [rdi + STRUCTURE_DAEMON_TCP_IP_STACK_PSEUDO_HEADER.target_address],	eax
	; ustaw adres ip serwera
	mov	eax,	dword [variable_network_ip]
	mov	dword [rdi + STRUCTURE_DAEMON_TCP_IP_STACK_PSEUDO_HEADER.source_address],	eax

	; ustaw rozmiar ramki TCP wraz z danymi
	add	rcx,	VARIABLE_NETWORK_FRAME_TCP_SIZE
	push	rcx
	xchg	cl,	ch
	mov	word [rdi + STRUCTURE_DAEMON_TCP_IP_STACK_PSEUDO_HEADER.tcp_frame_size],	cx

	; wylicz sumę kontrolną pseudo nagłówka
	xor	rax,	rax	; brak sumy sum kontrolnych
	mov	rcx,	STRUCTURE_DAEMON_TCP_IP_STACK_PSEUDO_HEADER.SIZE / VARIABLE_WORD_SIZE
	call	cyjon_network_checksum_create

	; odneguj sumę kontrolną
	not	ax

	; oblicz sumę kontrolną ramki TCP w połączeniu z sumą kontrolną pseudo nagłówka TCP

	; ustaw wskaźnik na ramkę TCP pakietu zwrotnego
	mov	rdi,	qword [rsp + VARIABLE_QWORD_SIZE]
	add	rdi,	VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE
	pop	rcx
	shr	rcx,	VARIABLE_DIVIDE_BY_2
	call	cyjon_network_checksum_create

	; zapisz połączone sumy kontrolne w ramce TCP
	sub	rdi,	VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE
	xchg	al,	ah
	mov	word [rdi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_TCP_FIELD_CHECKSUM],	ax

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret
