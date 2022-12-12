;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

; information for linker
section	.rodata

; align routine
align	0x08,	db	0x00
kernel_service_list:
	dq	kernel_service_framebuffer
	dq	kernel_service_memory_alloc
	dq	kernel_service_memory_release
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
	push	r11
	pushf

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

	; return properties of framebuffer

	; width in pixels
	mov	ax,	word [r8 + KERNEL_STRUCTURE.framebuffer_width_pixel]
	mov	word [rdi + LIB_SYS_STRUCTURE_FRAMEBUFFER.width_pixel],	ax

	; height in pixels
	mov	ax,	word [r8 + KERNEL_STRUCTURE.framebuffer_height_pixel]
	mov	word [rdi + LIB_SYS_STRUCTURE_FRAMEBUFFER.height_pixel],	ax

	; scanline in Bytes
	mov	eax,	dword [r8 + KERNEL_STRUCTURE.framebuffer_scanline_byte]
	mov	dword [rdi + LIB_SYS_STRUCTURE_FRAMEBUFFER.scanline_byte],	eax

	; framebuffer manager
	mov	rax,	qword [r8 + KERNEL_STRUCTURE.framebuffer_pid]

	; framebuffer manager exist?
	test	rax,	rax
	jnz	.return	; yes

	; retrieve pointer to current task descriptor
	call	kernel_task_current

	; calculate size of framebuffer space
	mov	eax,	dword [rdi + LIB_SYS_STRUCTURE_FRAMEBUFFER.scanline_byte]
	movzx	ecx,	word [rdi + LIB_SYS_STRUCTURE_FRAMEBUFFER.height_pixel]
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
	mov	qword [rdi + LIB_SYS_STRUCTURE_FRAMEBUFFER.base_address],	rax

	; new framebuffer manager
	mov	rax,	qword [r9 + KERNEL_TASK_STRUCTURE.pid]

.return:
	; framebuffer manager
	mov	qword [rdi + LIB_SYS_STRUCTURE_FRAMEBUFFER.pid],	rax

	; restore original registers
	popf
	pop	r11
	pop	r9
	pop	r8
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rdi - length of space in Bytes
; out:
;	rax - pointer to allocated space
;	or EMPTY if no enough memory
kernel_service_memory_alloc:
	; preserve original registers
	push	rbx
	push	rcx
	push	rdi
	push	rsi
	push	r8
	push	r9
	push	r11
	pushf

	; convert size to pages (align up to page boundaries)
	add	rdi,	~STATIC_PAGE_mask
	shr	rdi,	STATIC_PAGE_SIZE_shift

	; retrieve pointer to current task descriptor
	call	kernel_task_current

	; set pointer of process paging array
	mov	r11,	qword [r9 + KERNEL_TASK_STRUCTURE.cr3]

	; aquire memory space from process memory map
	mov	r9,	qword [r9 + KERNEL_TASK_STRUCTURE.memory_map]
	mov	rcx,	rdi	; number of pages
	call	kernel_memory_aquire
	jc	.error	; no enough memory

	; convert first page number to logical address
	shl	rdi,	STATIC_PAGE_SIZE_shift

	; assign pages to allocated memory in process space
	mov	rax,	rdi
	mov	bx,	KERNEL_PAGE_FLAG_present | KERNEL_PAGE_FLAG_write | KERNEL_PAGE_FLAG_user | KERNEL_PAGE_FLAG_process
	call	kernel_page_alloc
	jnc	.end	; space allocated

	; take back modifications
	mov	rsi,	rcx
	call	kernel_service_memory_release

.error:
	; no enough memory
	xor	eax,	eax

.end:
	; restore original registers
	popf
	pop	r11
	pop	r9
	pop	r8
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rdi - pointer to allocated space
;	rsi - length of space in Bytes
kernel_service_memory_release:
	; preserve original registers
	push	rax
	push	rcx
	push	rsi
	push	rdi
	push	r9
	push	r11
	pushf

	; retrieve pointer to current task descriptor
	call	kernel_task_current

	; convert bytes to pages
	add	rsi,	~STATIC_PAGE_mask
	shr	rsi,	STATIC_PAGE_SIZE_shift

	; release space from paging array of process
	mov	rax,	rdi	; address of releasing space
	mov	rcx,	rsi
	mov	r11,	qword [r9 + KERNEL_TASK_STRUCTURE.cr3]
	call	kernel_page_release

	; restore original registers
	popf
	pop	r11
	pop	r9
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; return from routine
	ret