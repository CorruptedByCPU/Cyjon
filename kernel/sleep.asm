;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
kernel_sleep:
	; wywłaszcz process, przekazująć pozosały czas
	int	KERNEL_APIC_IRQ_number

	; powrót z procedury
	ret
