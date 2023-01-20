;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; out:
;	rsi - stream descriptor
kernel_stream:
	; preserve original registers
	push	rax
	push	rcx
	push	rdi
	push	r8

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

.lock:
	; request an exclusive access
	mov	al,	LOCK
	lock xchg	byte [r8 + KERNEL_STRUCTURE.stream_semaphore],	al

	; assigned?
	test	al,	al
	jnz	.lock	; no

	; stream first descriptor
	mov	rsi,	qword [r8 + KERNEL_STRUCTURE.stream_base_address]

	; amount of streams
	mov	rcx,	KERNEL_STREAM_limit

.search:
	; available stream?
	cmp	qword [rsi + KERNEL_STREAM_STRUCTURE.base_address],	EMPTY
	je	.found	; yes

	; check next stream
	add	rsi,	KERNEL_STREAM_STRUCTURE.SIZE

	; end of streams?
 	dec	rcx
	jnz	.search	; no

.error:
	; free stream not found
	xor	esi,	esi

	; end of routine
	jmp	.end

.found:
	; prepare space for stream
	mov	ecx,	((KERNEL_STREAM_limit * KERNEL_STREAM_STRUCTURE.SIZE) + ~STATIC_PAGE_mask) >> STATIC_PAGE_SIZE_shift
	call	kernel_memory_alloc

	; store space of stream
	mov	qword [rsi + KERNEL_STREAM_STRUCTURE.base_address],	rdi

	; clean up stream content
	mov	word [rsi + KERNEL_STREAM_STRUCTURE.start],	EMPTY
	mov	word [rsi + KERNEL_STREAM_STRUCTURE.end],	EMPTY
	mov	word [rsi + KERNEL_STREAM_STRUCTURE.free],	LIB_SYS_STREAM_SIZE_byte

	; stream in use by requester
	mov	qword [rsi + KERNEL_STREAM_STRUCTURE.count],	TRUE

	; stream is unlocked
	mov	byte [rsi + KERNEL_STREAM_STRUCTURE.lock],	UNLOCK

.end:
	; unlock access
	mov	byte [r8 + KERNEL_STRUCTURE.stream_semaphore],	UNLOCK

	; restore original registers
	pop	r8
	pop	rdi
	pop	rcx
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rdi - pointer to process cache
; out:
;	rax - amount of transferred data
kernel_stream_in:
	; preserve original registers
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r9

	; by default, stream was empty
	xor	eax,	eax

	; task properties
	call	kernel_task_current

	; stream in properties
	mov	rbx,	qword [r9 + KERNEL_TASK_STRUCTURE.stream_out]

	; there is data inside stream?
	cmp	word [rbx + KERNEL_STREAM_STRUCTURE.free],	LIB_SYS_STREAM_SIZE_byte
	je	.end	; no

.lock:
	; request an exclusive access
	mov	dl,	LOCK
	lock xchg	byte [rbx + KERNEL_STREAM_STRUCTURE.lock],	dl

	; assigned?
	test	dl,	dl
	jnz	.lock	; no

	; get current pointer of start of stream
	movzx	edx,	word [rbx + KERNEL_STREAM_STRUCTURE.start]

	; get pointer of stream space
	mov	rsi,	qword [rbx + KERNEL_STREAM_STRUCTURE.base_address]

	; data transferred
	xor	eax,	eax

.load:
	; retrieve first Byte from stream
	mov	cl,	byte [rsi + rdx]

	; store inside process cache
	mov	byte [rdi + rax],	cl

	; move start marker forward
	inc	dx

	; end of stream space?
	cmp	dx,	LIB_SYS_STREAM_SIZE_byte
	jne	.continue	; no

	; set start marker at begining of stream space
	xor	dx,	dx

.continue:
	; amount of transferred data
	inc	ax

	; end of data inside stream?
	cmp	dx,	word [rbx + KERNEL_STREAM_STRUCTURE.end]
	jne	.load	; nie

	; preserve new marker of start of stream
	mov	word [rbx + KERNEL_STREAM_STRUCTURE.start],	dx

	; stream is drained
	mov	word [rbx + KERNEL_STREAM_STRUCTURE.free],	LIB_SYS_STREAM_SIZE_byte

.end:
	; release stream
	mov	byte [rbx + KERNEL_STREAM_STRUCTURE.lock],	UNLOCK

	; restore original registers
	pop	r9
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx

	; powrót z procedury
	ret

;-------------------------------------------------------------------------------
; in:
;	rdi - pointer to string
; out:
;	al - TRUE if sended
kernel_stream_out:
	; preserve original registers
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r9

	; length of string
	mov	rsi,	rdi
	call	lib_string_length

	; by default, stream is full
	mov	al,	FALSE

	; task properties
	call	kernel_task_current

	; stream out properties
	mov	rbx,	qword [r9 + KERNEL_TASK_STRUCTURE.stream_out]

.lock:
	; request an exclusive access
	mov	dl,	LOCK
	lock xchg	byte [rbx + KERNEL_STREAM_STRUCTURE.lock],	dl

	; assigned?
	test	dl,	dl
	jnz	.lock	; no

	; get pointer of stream space
	mov	rdi,	qword [rbx + KERNEL_STREAM_STRUCTURE.base_address]

	; get current pointer of end of stream
	movzx	edx,	word [rbx + KERNEL_STREAM_STRUCTURE.end]

	; there is enough space inside stream?
	cmp	cx,	word [rbx + KERNEL_STREAM_STRUCTURE.free]
	ja	.end	; no

	; after operation there will be less space inside stream
	sub	word [rbx + KERNEL_STREAM_STRUCTURE.free],	cx

.next:
	; load first char from string
	lodsb

	; preserve in stream
	mov	byte [rdi + rdx],	al

	; move end marker to next position
	inc	dx

	; end of stream space?
	cmp	dx,	LIB_SYS_STREAM_SIZE_byte
	jne	.continue	; nie

	; set end marker at begining of stream space
	xor	dx,	dx

.continue:
	; end of string?
	dec	cx
	jnz	.next	; no

	; preserve new marker of end of stream
	mov	word [rbx + KERNEL_STREAM_STRUCTURE.end],	dx

	; string inside stream
	mov	al,	TRUE

.end:
	; release stream
	mov	byte [rbx + KERNEL_STREAM_STRUCTURE.lock],	UNLOCK

	; restore original registers
	pop	r9
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx

	; return from routine
	ret