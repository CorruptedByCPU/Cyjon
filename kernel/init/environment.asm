;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; void
kernel_init_environment:
	; preserve original registers
	push	rax
	push	rbx
	push	rcx
	push	rdi
	push	rsi

	;----------------------------------------------------------------------

	; remember largest chunk of physical memory
	xor	rbx,	rbx

	; properties of memory map response
	mov	rsi,	qword [kernel_limine_memmap_request + LIMINE_MEMMAP_REQUEST.response]

	; amount of entries inside memory map
	mov	rcx,	qword [rsi + LIMINE_MEMMAP_RESPONSE.entry_count]

	; list of memory map entires
	mov	rsi,	qword [rsi + LIMINE_MEMMAP_RESPONSE.entries]

.entry:
	; parse "next" entry?
	dec	rcx
	js	.done	; no

	; retrieve entry
	mov	rax,	qword [rsi + rcx * STD_SIZE_PTR_byte]

	;  USABLE memory area?
	cmp	qword [rax + LIMINE_MEMMAP_ENTRY.type],	LIMINE_MEMMAP_USABLE
	jne	.entry	; no

	; this area is larger than previous one?
	cmp	qword [rax + LIMINE_MEMMAP_ENTRY.length],	rbx
	jng	.entry	; no

	; remember size for later use
	mov	rbx,	qword [rax + LIMINE_MEMMAP_ENTRY.length]

	; set global kernel environment variables/functions inside largest contiguous memory area (reflected in Higher Half)
	mov	rdi,	KERNEL_PAGE_mirror
	or	rdi,	qword [rax + LIMINE_MEMMAP_ENTRY.base]
	mov	qword [kernel],	rdi

	; next entry
	jmp	.entry

.done:
	;----------------------------------------------------------------------

	; properties of first framebuffer
	mov	rsi,	qword [kernel_limine_framebuffer_request + LIMINE_FRAMEBUFFER_REQUEST.response]
	mov	rsi,	qword [rsi + LIMINE_FRAMEBUFFER_RESPONSE.framebuffers]
	mov	rsi,	qword [rsi + INIT]	; properties of first framebuffer

	; set information about framebuffer properties

	; base address
	mov	rax,	KERNEL_PAGE_mirror
	or	rax,	qword [rsi + LIMINE_FRAMEBUFFER.address]
	mov	qword [rdi + KERNEL.framebuffer_base_address],	rax

	; width in pixels
	mov	ax,	word [rsi + LIMINE_FRAMEBUFFER.width]
	mov	word [rdi + KERNEL.framebuffer_width_pixel],	ax

	; height in pixels
	mov	ax,	word [rsi + LIMINE_FRAMEBUFFER.height]
	mov	word [rdi + KERNEL.framebuffer_height_pixel],	ax

	; pitch in Bytes
	mov	eax,	dword [rsi + LIMINE_FRAMEBUFFER.pitch]
	mov	dword [rdi + KERNEL.framebuffer_pitch_byte],	eax

	; owner of framebuffer
	mov	qword [rdi + KERNEL.framebuffer_pid],	INIT	; by default: kernel

	;----------------------------------------------------------------------

	; share IDT management functions
	mov	qword [rdi + KERNEL.idt_mount],			kernel_idt_mount

	; share kernel early printf function
	mov	qword [rdi + KERNEL.log],			kernel_log

	; share memory management functions
	mov	qword [rdi + KERNEL.memory_release],		kernel_memory_release

	; share page management functions
	mov	qword [rdi + KERNEL.page_deconstruction],	kernel_page_deconstruction

	; share stream management functions
	mov	qword [rdi + KERNEL.stream_release],		kernel_stream_release

	; restore original registers
	pop	rsi
	pop	rdi
	pop	rcx
	pop	rbx
	pop	rax

	; return from routine
	ret
