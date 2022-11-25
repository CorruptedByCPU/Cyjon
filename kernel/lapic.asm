;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; out:
;	rax - cpu id
kernel_lapic_id:
	; kernel environment variables/rountines base address
	mov	rax,	qword [kernel_environment_base_address]

	; retrieve CPU ID from LAPIC
	mov	rax,	qword [rax + KERNEL_STRUCTURE.lapic_base_address]
	mov	eax,	dword [rax + KERNEL_LAPIC_STRUCTURE.id]

	; return from routine
	ret