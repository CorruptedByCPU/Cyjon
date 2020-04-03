;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
service_cero_clock:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; pobierz aktualny czas zegara RTC
	call	driver_rtc_get_date_and_time
	mov	rax,	qword [driver_rtc_date_and_time]

	; czas uległ zmianie?
	cmp	qword [service_cero_clock_last_state],	rax
	je	.end	; nie, koniec obsługi procedury

	; zachowaj nowy znacznik czasu
	mov	qword [service_cero_clock_last_state],	rax

	; przy każdej zmianie czasu (sekundy) ukryj/pokaż dwukropek
	mov	bl,	byte [service_cero_clock_colon]
	xchg	bl,	byte [service_cero_window_taskbar.element_label_clock_char_colon]
	mov	byte [service_cero_clock_colon],	bl

	;-----------------------------------------------------------------------
	; Minuta
	;-----------------------------------------------------------------------
	shr	rax,	STATIC_MOVE_HIGH_TO_AL_shift	; przesuń ilość minut do rejestru AX
	and	eax,	0xFF	; usuń informacje o godzinie, dniu, miesiącu... itp.
	mov	ebx,	STATIC_NUMBER_SYSTEM_decimal
	mov	ecx,	0x02	; wyświetl dwie cyfry (prefix)
	mov	dl,	STATIC_ASCII_DIGIT_0	; prefix to cyfra "0"
	mov	rdi,	service_cero_window_taskbar.element_label_clock_string_minute
	call	library_integer_to_string

	; pobierz aktualny znacznik czasu
	mov	rax,	qword [service_cero_clock_last_state]

	;-----------------------------------------------------------------------
	; Godzina
	;-----------------------------------------------------------------------
	shr	rax,	STATIC_MOVE_HIGH_TO_AX_shift	; przesuń ilość godzin do rejestru AL
	and	rax,	0xFF	; usuń informacje o dniu, miesiącu, roku... itp.
	mov	dl,	STATIC_ASCII_SPACE	; prefix to "spacja"
	mov	rdi,	service_cero_window_taskbar.element_label_clock_string_hour
	call	library_integer_to_string

	; aktualizuj element "etykieta zegar" w przestrzeni okna paska zadań
	mov	rdi,	service_cero_window_taskbar
	mov	rsi,	service_cero_window_taskbar.element_label_clock
	call	library_bosu_element_label

	; ustaw flagę okna: nowa zawartość
	mov	al,	SERVICE_DESU_WINDOW_update
	mov	rsi,	service_cero_window_taskbar
	int	SERVICE_DESU_IRQ

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret
