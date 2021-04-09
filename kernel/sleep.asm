;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rax - ilość czasu do odczekania w microtime
kernel_sleep_microtime:
	; zachowaj oryginalny rejestr
	push	rax

	; oblicz punkt odniesienia
	add	rax,	qword [driver_rtc_microtime]

.wait:
	; zwolnij czas procesora
	call	kernel_sleep

	; odczekano wymagany czas?
	cmp	rax,	qword [driver_rtc_microtime]
	jnb	.wait	; nie

	; przywróć oryginalny rejestr
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
kernel_sleep:
	; wywłaszcz process, przekazująć pozosały czas
	int	KERNEL_APIC_IRQ_number

	; powrót z procedury
	ret

	macro_debug	"kernel_sleep"
