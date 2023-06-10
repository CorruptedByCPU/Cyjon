;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; void
kernel_hpet_irq:
	; preserve original register
	push	rax

	; kernel environment variables/rountines base address
	mov	rax,	qword [kernel_environment_base_address]

	; increment microtime counter
	inc	qword [rax + KERNEL_STRUCTURE.hpet_microtime]

	; accept this interrupt
	call	kernel_lapic_accept

	; restore original register
	pop	rax

	; return from interrupt
	iretq