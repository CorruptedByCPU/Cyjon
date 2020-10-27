;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
kernel_gui_clock:
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
	cmp	qword [kernel_gui_clock_last_state],	rax
	je	.end	; nie, koniec obsługi procedury

	; zachowaj nowy znacznik czasu
	mov	qword [kernel_gui_clock_last_state],	rax

	; przy każdej zmianie czasu (sekundy) ukryj/pokaż dwukropek
	mov	bl,	byte [kernel_gui_clock_colon]
	xchg	bl,	byte [kernel_gui_window_taskbar.element_label_clock_char_colon]
	mov	byte [kernel_gui_clock_colon],	bl

	;-----------------------------------------------------------------------
	; Minuta
	;-----------------------------------------------------------------------
	shr	rax,	STATIC_MOVE_HIGH_TO_AL_shift	; przesuń ilość minut do rejestru AX
	and	eax,	0xFF	; usuń informacje o godzinie, dniu, miesiącu... itp.
	mov	ebx,	STATIC_NUMBER_SYSTEM_decimal
	mov	ecx,	0x02	; wyświetl dwie cyfry (prefix)
	mov	dl,	STATIC_ASCII_DIGIT_0	; prefix to cyfra "0"
	mov	rdi,	kernel_gui_window_taskbar.element_label_clock_string_minute
	call	library_integer_to_string

	; pobierz aktualny znacznik czasu
	mov	rax,	qword [kernel_gui_clock_last_state]

	;-----------------------------------------------------------------------
	; Godzina
	;-----------------------------------------------------------------------
	shr	rax,	STATIC_MOVE_HIGH_TO_AX_shift	; przesuń ilość godzin do rejestru AL
	and	rax,	0xFF	; usuń informacje o dniu, miesiącu, roku... itp.
	mov	dl,	STATIC_ASCII_SPACE	; prefix to "spacja"
	mov	rdi,	kernel_gui_window_taskbar.element_label_clock_string_hour
	call	library_integer_to_string

	; aktualizuj element "etykieta zegar" w przestrzeni okna paska zadań
	mov	rdi,	kernel_gui_window_taskbar
	mov	rsi,	kernel_gui_window_taskbar.element_label_clock
	call	library_bosu_element_label

	; ustaw flagę okna: nowa zawartość
	mov	al,	KERNEL_WM_WINDOW_update
	mov	rsi,	kernel_gui_window_taskbar
	int	KERNEL_WM_IRQ

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

	macro_debug	"kernel_gui_clock"
