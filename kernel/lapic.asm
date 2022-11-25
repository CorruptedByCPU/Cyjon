;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; void
kernel_lapic_accept:
	; preserve original register
	push	rax

	; LAPIC controller base address
	mov	rax,	qword [kernel_environment_base_address]
	mov	rax,	qword [rax + KERNEL_STRUCTURE.lapic_base_address]

	; accept currently pending interrupt
	mov	dword [rax + KERNEL_LAPIC_STRUCTURE.eoi],	EMPTY

	; restore original register
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; out:
;	eax - cpu id
kernel_lapic_id:
	; kernel environment variables/rountines base address
	mov	rax,	qword [kernel_environment_base_address]

	; retrieve CPU ID from LAPIC
	mov	rax,	qword [rax + KERNEL_STRUCTURE.lapic_base_address]
	mov	eax,	dword [rax + KERNEL_LAPIC_STRUCTURE.id]
	shr	eax,	24	; move ID at a begining of EAX register

	; return from routine
	ret

;-------------------------------------------------------------------------------
; void
kernel_lapic_init:
	; preserve original registers
	push	rax
	push	rdi

	; kernel environment variables/rountines base address
	mov	rdi,	qword [kernel_environment_base_address]
	mov	rdi,	qword [rdi + KERNEL_STRUCTURE.lapic_base_address]

	; turn off Task Priority and Priority Sub-Class
	mov	dword [rdi + KERNEL_LAPIC_STRUCTURE.tp],	EMPTY;

	; turn on Flat Mode
	mov	dword [rdi + KERNEL_LAPIC_STRUCTURE.df],	KERNEL_LAPIC_DF_FLAG_flat_mode

	; all logical/BSP processors gets interrupts (physical!)
	mov	dword [rdi + KERNEL_LAPIC_STRUCTURE.ld],	KERNEL_LAPIC_LD_FLAG_target_cpu

	; enable APIC controller on the BSP/logical processor
	mov	eax,	dword [rdi + KERNEL_LAPIC_STRUCTURE.siv]
	or	eax,	KERNEL_LAPIC_SIV_FLAG_enable_apic | KERNEL_LAPIC_SIV_FLAG_spurious_vector3
	mov	dword [rdi + KERNEL_LAPIC_STRUCTURE.siv],	eax 

	; turn on internal interrupts time on APIC controller of BSP/logical processor
	mov	eax,	dword [rdi + KERNEL_LAPIC_STRUCTURE.lvt]
	and	eax,	KERNEL_LAPIC_LVT_TR_FLAG_mask_interrupts
	mov	dword [rdi + KERNEL_LAPIC_STRUCTURE.lvt],	eax

	; number of hardware interrupt at the end of the timer
	mov	dword [rdi + KERNEL_LAPIC_STRUCTURE.lvt],	KERNEL_LAPIC_IRQ_number

	; countdown time converter
	mov	dword [rdi + KERNEL_LAPIC_STRUCTURE.tdc],	KERNEL_LAPIC_TDC_divide_by_1

	; restore original registers
	pop	rdi
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; void
kernel_lapic_reload:
	; preserve original register
	push	rax

	; LAPIC controller base address
	mov	rax,	qword [kernel_environment_base_address]
	mov	rax,	qword [rax + KERNEL_STRUCTURE.lapic_base_address]

	; wake up internal interrupt after KERNEL_LAPIC_Hz cycles
	mov	dword [rax + KERNEL_LAPIC_STRUCTURE.tic],	KERNEL_LAPIC_Hz

	; restore original register
	pop	rax

	; return from routine
	ret