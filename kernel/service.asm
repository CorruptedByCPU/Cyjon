;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

; information for linker
section	.rodata

; align routine
align	0x08,	db	0x00
kernel_service_list:
	dq	kernel_service_framebuffer
kernel_service_list_end:

; information for linker
section	.text

;-------------------------------------------------------------------------------
; in:
;	rdi - pointer to framebuffer descriptor
kernel_service_framebuffer:
	; preserve original registers
	push	rax
	push	rcx
	push	rdx
	push	rsi
	push	r8
	push	r9

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

	; return properties of framebuffer

	; width in pixels
	mov	ax,	word [r8 + KERNEL_STRUCTURE.framebuffer_width_pixel]
	mov	word [rdi + SYS_STRUCTURE_FRAMEBUFFER.width_pixel],	ax

	; height in pixels
	mov	ax,	word [r8 + KERNEL_STRUCTURE.framebuffer_height_pixel]
	mov	word [rdi + SYS_STRUCTURE_FRAMEBUFFER.height_pixel],	ax

	; scanline in Bytes
	mov	eax,	dword [r8 + KERNEL_STRUCTURE.framebuffer_scanline_byte]
	mov	dword [rdi + SYS_STRUCTURE_FRAMEBUFFER.scanline_byte],	eax

	; framebuffer manager
	mov	rax,	qword [r8 + KERNEL_STRUCTURE.framebuffer_pid]

	; framebuffer manager exist?
	test	rax,	rax
	jnz	.return	; yes

	; preserve original flags
	pushf

	; turn off interrupts
	; we cannot allow task switch
	; when looking for current task pointe
	cli

	; retrieve CPU id
	call	kernel_lapic_id

	; set pointer to current task of CPU
	mov	r9,	qword [r8 + KERNEL_STRUCTURE.task_ap_address]
	mov	r9,	qword [r9 + rax * STATIC_PTR_SIZE_byte]

	; restore original flags
	popf

	; calculate size of framebuffer space
	mov	eax,	dword [rdi + SYS_STRUCTURE_FRAMEBUFFER.scanline_byte]
	movzx	ecx,	word [rdi + SYS_STRUCTURE_FRAMEBUFFER.height_pixel]
	mul	rcx

	; convert to pages
	add	rax,	~STATIC_PAGE_mask
	shr	rax,	STATIC_PAGE_SIZE_shift

	; share framebuffer memory space with process
	xor	ecx,	ecx	; no framebuffer manager, if error on below function
	xchg	rcx,	rax	; length of shared space in pages
	mov	rsi,	qword [r8 + KERNEL_STRUCTURE.framebuffer_base_address]
	mov	r11,	qword [r9 + KERNEL_TASK_STRUCTURE.cr3]
	call	kernel_memory_share
	jc	.return	; no enough memory?

	; return pointer to shared memory of framebuffer
	mov	qword [rdi + SYS_STRUCTURE_FRAMEBUFFER.base_address],	rax

	; new framebuffer manager
	mov	rax,	qword [r9 + KERNEL_TASK_STRUCTURE.pid]

.return:
	; framebuffer manager
	mov	qword [rdi + SYS_STRUCTURE_FRAMEBUFFER.pid],	rax

	; restore original registers
	pop	r9
	pop	r8
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

	; return from routine
	ret