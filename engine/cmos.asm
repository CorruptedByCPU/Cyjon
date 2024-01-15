;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; poniższe stałe, nie będą wykorzystywane w innym miejscu,
; nie ma potrzeby przenosić ich do config.asm
STATIC_PORT_CMOS_IN		equ	0x71
STATIC_PORT_CMOS_OUT		equ	0x70

STATIC_CMOS_SECOND		equ	0x00
STATIC_CMOS_MINUTE		equ	0x02
STATIC_CMOS_HOUR		equ	0x04
STATIC_CMOS_DAY_OF_WEEK		equ	0x06
STATIC_CMOS_DAY_OF_MONTH	equ	0x07
STATIC_CMOS_MONTH		equ	0x08
STATIC_CMOS_YEAR		equ	0x09
STATIC_CMOS_REGISTER_B		equ	0x0B
STATIC_CMOS_REGISTER_B_MODE_24H	equ	2	; 24h mode / 12h default
STATIC_CMOS_REGISTER_B_BINARY	equ	4	; binary mode / bcd default

; 64 Bitowy kod programu
[BITS 64]

cmos:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx

	xchg	bx,bx

	; pobierz status rejestru B
	mov	al,	STATIC_CMOS_REGISTER_B
	out	STATIC_PORT_CMOS_OUT,	al
	in	al,	STATIC_PORT_CMOS_IN	; odbierz

	; ustaw zegar 24 godzinny i liczby w systemie binarnym
	or	al,	STATIC_CMOS_REGISTER_B_MODE_24H
	or	al,	STATIC_CMOS_REGISTER_B_BINARY

	; aktualizuj rejestr b
	out	STATIC_PORT_CMOS_IN,	al

.loop:
	; pobierz prawidłowy czas
	mov	byte [variable_cmos_semaphore],	VARIABLE_FALSE

	; pobierz ilość sekund
	mov	al,	STATIC_CMOS_SECOND
	out	STATIC_PORT_CMOS_IN,	al
	in	al,	STATIC_PORT_CMOS_OUT	; odbierz

	; sprawdź czy nastąpiła modyfikacja
	cmp	al,	byte [variable_cmos_second]
	je	.minute	; jeśli brak zmian, kontynuuj

	; pobierany czas uległ zmianie
	mov	byte [variable_cmos_second],	al
	mov	byte [variable_cmos_semaphore],	VARIABLE_TRUE

.minute:
	; pobierz ilość minut
	mov	al,	STATIC_CMOS_MINUTE
	out	STATIC_PORT_CMOS_OUT,	al
	in	al,	STATIC_PORT_CMOS_IN

	; sprawdź czy wystąpiła modyfikacj
	cmp	al,	byte [variable_cmos_minute]
	je	.hour	; jeśli brak zmian, kontynuuj

	; pobierany czas uległ zmianie
	mov	byte [variable_cmos_minute],	al
	mov	byte [variable_cmos_semaphore],	VARIABLE_TRUE

.hour:
	; pobierz ilość godzin
	mov	al,	STATIC_CMOS_HOUR
	out	STATIC_PORT_CMOS_OUT,	al
	in	al,	STATIC_PORT_CMOS_IN

	; sprawdź czy wystąpiła modyfikacja
	cmp	al,	byte [variable_cmos_hour]
	je	.day	; jeśli brak zmian, kontynuuj

	; pobierany czas uległ zmianie
	mov	byte [variable_cmos_hour],	al
	mov	byte [variable_cmos_semaphore],	VARIABLE_TRUE

.day:
	; pobierz ilość dni
	mov	al,	STATIC_CMOS_DAY_OF_MONTH
	out	STATIC_PORT_CMOS_OUT,	al
	in	al,	STATIC_PORT_CMOS_IN

	; sprawdź czy wystąpiła modyfikacja
	cmp	al,	byte [variable_cmos_day_of_month]
	je	.week	; jeśli brak zmian, kontynuuj

	; pobierany czas uległ zmianie
	mov	byte [variable_cmos_day_of_month],	al
	mov	byte [variable_cmos_semaphore],	VARIABLE_TRUE

.week:
	; pobierz numer dnia (niedziela, poniedzialek, wto...)
	mov	al,	STATIC_CMOS_DAY_OF_WEEK
	out	STATIC_PORT_CMOS_OUT,	al
	in	al,	STATIC_PORT_CMOS_IN

	; sprawdź czy wystąpiła modyfikacja
	cmp	al,	byte [variable_cmos_day_of_week]
	je	.month	; jeśli brak zmian, kontynuuj

	; pobierany czas uległ zmianie
	mov	byte [variable_cmos_day_of_week],	al
	mov	byte [variable_cmos_semaphore],	VARIABLE_TRUE

.month:
	; pobierz ilość miesięcy
	mov	al,	STATIC_CMOS_MONTH
	out	STATIC_PORT_CMOS_OUT,	al
	in	al,	STATIC_PORT_CMOS_IN

	; sprawdź czy wystąpiła modyfikacja
	cmp	al,	byte [variable_cmos_month]
	je	.year	; jeśli brak zmian, kontynuuj

	; pobierany czas uległ zmianie
	mov	byte [variable_cmos_month],	al
	mov	byte [variable_cmos_semaphore],	VARIABLE_TRUE

.year:
	; pobierz ilość lat
	mov	al,	STATIC_CMOS_YEAR
	out	STATIC_PORT_CMOS_OUT,	al
	in	al,	STATIC_PORT_CMOS_IN

	; sprawdź czy wystąpiła modyfikacja
	cmp	al,	byte [variable_cmos_year]
	je	.end	; jeśli brak zmian, kontynuuj

	; sprawdź czy wystąpiła modyfikacja
	mov	byte [variable_cmos_year],	al
	mov	byte [variable_cmos_semaphore],	VARIABLE_TRUE

.end:
	; sprawdź czy pobrany czas nie uległ zmianie już w czasie pobierania
	cmp	byte [variable_cmos_semaphore],	VARIABLE_FALSE
	jne	cmos.loop	; jeśli tak, pobierz czas ponownie

	; przyrwóć oryginalne rejestry
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

; flaga prawidłowego pobrania czasu
variable_cmos_semaphore		db	0x00

variable_cmos_second		db	0x00
variable_cmos_minute		db	0x00
variable_cmos_hour		db	0x00
variable_cmos_month		db	0x00
variable_cmos_year		db	0x00
variable_cmos_day_of_week	db	0x00
variable_cmos_day_of_month	db	0x00
