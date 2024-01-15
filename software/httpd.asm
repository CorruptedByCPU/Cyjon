;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; zestaw imiennych wartości stałych jądra systemu
%include	'config.asm'

%define	VARIABLE_PROGRAM_NAME		httpd
%define	VARIABLE_PROGRAM_VERSION	"v0.7"

VARIABLE_HTTPD_CACHE_SIZE		equ	8
VARIABLE_HTTPD_PORT_DEFAULT		equ	80

; 64 Bitowy kod programu
[BITS 64]

; adresowanie względne (skoki, etykiety)
[DEFAULT REL]

; adres kodu programu w przestrzeni logicznej
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]

start:
	; wyrównaj adres przestrzeni do pełnej strony
	mov	rdi,	end
	call	library_align_address_up_to_page

	; zapamiętaj
	mov	qword [variable_httpd_cache],	rdi

	; zaalokuj przestrzeń pamięci pod zapytnia od klientów
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_MEMORY_ALLOCATE
	mov	rcx,	VARIABLE_HTTPD_CACHE_SIZE
	int	STATIC_KERNEL_SERVICE

	; zarezerwuj numer portu
	mov	ax,	VARIABLE_KERNEL_SERVICE_NETWORK_PORT_ASSIGN
	mov	rcx,	VARIABLE_HTTPD_PORT_DEFAULT
	mov	rdx,	VARIABLE_HTTPD_CACHE_SIZE
	int	STATIC_KERNEL_SERVICE

	; sprawdź czy port został przyznany
	cmp	rcx,	VARIABLE_EMPTY
	mov	rsi,	text_port_busy
	je	.error

.restart:
	; rozmiar bufora w rekordach
	mov	rcx,	VARIABLE_HTTPD_CACHE_SIZE * VARIABLE_MEMORY_PAGE_SIZE / STRUCTURE_CACHE_DEFAULT.SIZE

	; ustaw wskaźnik na początek bufora zapytań
	mov	rdi,	qword [variable_httpd_cache]
	
.search:
	; sprawdź czy przyszło zapytanie do serwera
	cmp	qword [rdi + STRUCTURE_CACHE_DEFAULT.id],	VARIABLE_EMPTY
	ja	.request

.continue:
	; przesuń wskaźnik na nastepny rekord
	add	rdi,	STRUCTURE_CACHE_DEFAULT.SIZE

	; przeszukaj następne rekordy
	loop	.search

	; brak zapytań, rozpocznij od początku
	jmp	.restart

.request:
	; zachowaj oryginalne rejestry
	push	rcx

	; sprawdź rodzaj zapytania
	mov	rcx,	qword [variable_httpd_request_200_chars]
	add	rdi,	STRUCTURE_CACHE_DEFAULT.data
	mov	rsi,	variable_httpd_request_200
	call	library_compare_string
	jc	.no_answer	; nie rozpoznano zapytania, wyślij komunikat "404 pliku nie znaleziono"

	; ilość znaków w odpowiedzi
	mov	rcx,	variable_httpd_answer_200_end
	sub	ecx,	variable_httpd_answer_200
	; wskaźnik do odpowiedzi
	mov	rsi,	variable_httpd_answer_200

	; wyślij
	jmp	.send

.no_answer:
	; ilość znaków w odpowiedzi
	mov	rcx,	variable_httpd_answer_404_end
	sub	ecx,	variable_httpd_answer_404
	; wskaźnik do odpowiedzi
	mov	rsi,	variable_httpd_answer_404

.send:
	sub	rdi,	STRUCTURE_CACHE_DEFAULT.data
	; procedura wysyłania odpowiedzi do sieci
	mov	ax,	VARIABLE_KERNEL_SERVICE_NETWORK_ANSWER
	; pobierz identyfikator zapytania i zwolnij rekord
	xor	rbx,	rbx
	xchg	rbx,	qword [rdi + STRUCTURE_CACHE_DEFAULT.id]
	; wartość parzysta?
	bt	cx,	0
	jnc	.ok

	; wyrównaj rozmiar do liczby parzystej
	inc	rcx

.ok:
	int	STATIC_KERNEL_SERVICE

	; przywróć oryginalne rejestry
	pop	rcx

	; obsłuż pozostałe zapytania
	jmp	.continue

.port_release:
	; zwolnij numer portu
	mov	ax,	VARIABLE_KERNEL_SERVICE_NETWORK_PORT_RELEASE
	mov	rcx,	VARIABLE_HTTPD_PORT_DEFAULT
	int	STATIC_KERNEL_SERVICE

	; koniec pracy serwera
	jmp	.end

.error:
	mov	rax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	bl,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	VARIABLE_FULL
	mov	dl,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	int	STATIC_KERNEL_SERVICE

.end:
	; zakończ proces
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_END
	int	STATIC_KERNEL_SERVICE

%include	"library/align_address_up_to_page.asm"
%include	"library/compare_string.asm"

; wczytaj lokalizacje programu systemu
%push
	%defstr		%$system_locale		VARIABLE_KERNEL_LOCALE
	%defstr		%$process_name		VARIABLE_PROGRAM_NAME
	%strcat		%$include_program_locale,	"software/", %$process_name, "/locale/", %$system_locale, ".asm"
	%include	%$include_program_locale
%pop

variable_httpd_cache			dq	VARIABLE_EMPTY

variable_httpd_request_200_chars	dq	14
variable_httpd_request_200		db	'GET / HTTP/1.1'

end:
