;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; out:
;	rsi - stream descriptor
kernel_stream:
	; preserve original registers
	push	rax
	push	rcx
	push	rdi
	push	r8

	; global kernel environment variables/functions/rountines
	mov	r8,	qword [kernel]

.lock:
	; request an exclusive access
	mov	al,	LOCK
	xchg	byte [r8 + KERNEL.stream_semaphore],	al

	; assigned?
	test	al,	al
	jnz	.lock	; no

	; stream first descriptor
	mov	rsi,	qword [r8 + KERNEL.stream_base_address]

	; amount of streams
	mov	rcx,	KERNEL_STREAM_limit

.search:
	; available stream?
	cmp	qword [rsi + KERNEL_STRUCTURE_STREAM.base_address],	EMPTY
	je	.found	; yes

	; check next stream
	add	rsi,	KERNEL_STRUCTURE_STREAM.SIZE

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
	mov	ecx,	STD_STREAM_SIZE_page
	call	kernel_memory_alloc

	; store space of stream
	mov	qword [rsi + KERNEL_STRUCTURE_STREAM.base_address],	rdi

	; clean up stream content
	mov	word [rsi + KERNEL_STRUCTURE_STREAM.start],	EMPTY
	mov	word [rsi + KERNEL_STRUCTURE_STREAM.end],	EMPTY
	mov	word [rsi + KERNEL_STRUCTURE_STREAM.free],	LIB_SYS_STREAM_SIZE_byte

	; stream in use by requester
	mov	qword [rsi + KERNEL_STRUCTURE_STREAM.count],	TRUE

	; stream is unlocked
	mov	byte [rsi + KERNEL_STRUCTURE_STREAM.lock],	UNLOCK

.end:
	; unlock access
	mov	byte [r8 + KERNEL.stream_semaphore],	UNLOCK

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
	call	kernel_task_active

	; stream in properties
	mov	rbx,	qword [r9 + KERNEL_STRUCTURE_TASK.stream_in]

	; there is data inside stream?
	cmp	word [rbx + KERNEL_STRUCTURE_STREAM.free],	LIB_SYS_STREAM_SIZE_byte
	je	.end	; no

.lock:
	; request an exclusive access
	mov	dl,	LOCK
	xchg	byte [rbx + KERNEL_STRUCTURE_STREAM.lock],	dl

	; assigned?
	test	dl,	dl
	jnz	.lock	; no

	; get current pointer of start of stream
	movzx	edx,	word [rbx + KERNEL_STRUCTURE_STREAM.start]

	; get pointer of stream space
	mov	rsi,	qword [rbx + KERNEL_STRUCTURE_STREAM.base_address]

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
	cmp	dx,	word [rbx + KERNEL_STRUCTURE_STREAM.end]
	jne	.load	; nie

	; preserve new marker of start of stream
	mov	word [rbx + KERNEL_STRUCTURE_STREAM.start],	dx

	; stream is drained
	mov	word [rbx + KERNEL_STRUCTURE_STREAM.free],	LIB_SYS_STREAM_SIZE_byte

.end:
	; release stream
	mov	byte [rbx + KERNEL_STRUCTURE_STREAM.lock],	UNLOCK

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
;	rsi - string length in bytes
kernel_stream_out:
	; preserve original registers
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r9

	; data volume supported?
	cmp	rsi,	LIB_SYS_STREAM_SIZE_byte
	jnb	.exit	; no

	; length of string
	mov	rcx,	rsi

	; task properties
	call	kernel_task_active

	; stream out properties
	mov	rbx,	qword [r9 + KERNEL_STRUCTURE_TASK.stream_out]

	; stream closed?
	test	byte [rbx + KERNEL_STRUCTURE_STREAM.flags],	LIB_SYS_STREAM_FLAG_closed
	jnz	.exit	; yes

.lock:
	; request an exclusive access
	mov	dl,	LOCK
	xchg	byte [rbx + KERNEL_STRUCTURE_STREAM.lock],	dl

	; assigned?
	test	dl,	dl
	jnz	.lock	; no

	; there is enough space inside stream?
	cmp	cx,	word [rbx + KERNEL_STRUCTURE_STREAM.free]
	ja	.end	; no

	; set string pointer in place
	mov	rsi,	rdi

	; get pointer of stream space
	mov	rdi,	qword [rbx + KERNEL_STRUCTURE_STREAM.base_address]

	; get current pointer of end of stream
	movzx	edx,	word [rbx + KERNEL_STRUCTURE_STREAM.end]

	; after operation there will be less space inside stream
	sub	word [rbx + KERNEL_STRUCTURE_STREAM.free],	cx

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
	mov	word [rbx + KERNEL_STRUCTURE_STREAM.end],	dx

	; set meta flag
	or	byte [rbx + KERNEL_STRUCTURE_STREAM.flags],	LIB_SYS_STREAM_FLAG_undefinied;

	; string inside stream
	mov	al,	TRUE

.end:
	; release stream
	mov	byte [rbx + KERNEL_STRUCTURE_STREAM.lock],	UNLOCK

.exit:
	; restore original registers
	pop	r9
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rdi - value
;	sil - number base
;	dl - required N digits, but no more than 64 (QWORD limit)
;	cl - ASCII code of characters
kernel_stream_out_value:
	; preserve original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; prefix overflow?
	cmp	dl,	STD_SIZE_QWORD_bit
	ja	.end	; yes

	; string cache
	mov	eax,	STD_SIZE_QWORD_bit
	sub	rsp,	rax

	; fill with prefix value
	xchg	al,	cl
	mov	rdi,	rsp
	rep	stosb

	; prepare acumulator
	mov	rax,	qword [rsp + STD_SIZE_QWORD_bit]

	; preserve prefix value
	movzx	rbx,	dl

	; string index
	xor	ecx,	ecx

	; convert base and prefix to 64bit value
	movzx	rsi,	sil

.loop:
	; division result
	xor	edx,	edx

	; modulo
	div	rsi

	; assign place for digit
	dec	rcx

	; lower prefix requirement
	dec	rbx

	; convert digit to ASCII
	add	dl,	STD_ASCII_DIGIT_0
	mov	byte [rsp + rcx + STD_SIGN_QWORD_bit],	dl	; and keep on stack

	; keep parsing?
	test	rax,	rax
	jnz	.loop	; yes

	; prefix fulfilled
	bt	rbx,	STD_SIGN_QWORD_bit
	jc	.ready	; yes

	; show N digits
	sub	rcx,	rbx

.ready:
	; number of digits
	mov	rsi,	rcx
	not	rsi
	inc	rsi

	; send string to stdout
	lea	rdi,	[rsp + rcx + STD_SIGN_QWORD_bit]
	call	kernel_stream_out

	; remove string cache from stack
	add	rsp,	STD_SIZE_QWORD_bit

.end:
	; restore original registers
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rsi - stream type
;	rdi - pointer to meta descriptor
; out:
;	al - stream status
kernel_stream_get:
	; preserve original registers
	push	rcx
	push	rsi
	push	rdi
	push	r9

	; task properties
	call	kernel_task_active

	; stream out?
	test	rsi,	LIB_SYS_STREAM_out
	jnz	.out	; yes

	; change to stream in
	mov	rsi,	qword [r9 + KERNEL_STRUCTURE_TASK.stream_in]

	; continue
	jmp	.lock

.out:
	; set to stream out
	mov	rsi,	qword [r9 + KERNEL_STRUCTURE_TASK.stream_out]

.lock:
	; request an exclusive access
	mov	cl,	LOCK
	xchg	byte [rsi + KERNEL_STRUCTURE_STREAM.lock],	cl

	; assigned?
	test	cl,	cl
	jnz	.lock	; no

	; preserve stream pointer
	push	rsi

	; retrieve metadata
	mov	ecx,	LIB_SYS_STREAM_META_LENGTH_byte
	add	rsi,	KERNEL_STRUCTURE_STREAM.meta
	rep	movsb

	; restore stream pointer
	pop	rsi

	; release stream
	mov	byte [rsi + KERNEL_STRUCTURE_STREAM.lock],	UNLOCK

	; return stream flags
	movzx	eax,	byte [rsi + KERNEL_STRUCTURE_STREAM.flags]

	; restore original registers
	pop	r9
	pop	rdi
	pop	rsi
	pop	rcx

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rsi - pointer to stream metadata
;	rdi - stream type
kernel_stream_set:
	; preserve original registers
	push	rcx
	push	rsi
	push	rdi
	push	r9

	; task properties
	call	kernel_task_active

	; by default stream out
	mov	rdi,	qword [r9 + KERNEL_STRUCTURE_TASK.stream_out]

	; stream out?
	test	rdi,	LIB_SYS_STREAM_out
	jnz	.lock	; yes

	; change to stream in
	mov	rdi,	qword [r9 + KERNEL_STRUCTURE_TASK.stream_in]

.lock:
	; request an exclusive access
	mov	cl,	LOCK
	xchg	byte [rdi + KERNEL_STRUCTURE_STREAM.lock],	cl

	; assigned?
	test	cl,	cl
	jnz	.lock	; no

	; ignore metadata modification if stream is not empty
	mov	cx,	word [rdi + KERNEL_STRUCTURE_STREAM.start]
	cmp	cx,	word [rdi + KERNEL_STRUCTURE_STREAM.end]
	jne	.not_empty

	; preserve stream pointer
	push	rdi

	; retrieve metadata
	mov	ecx,	LIB_SYS_STREAM_META_LENGTH_byte
	add	rdi,	KERNEL_STRUCTURE_STREAM.meta
	rep	movsb

	; restore stream pointer
	pop	rdi

	; metadata are up to date
	and	byte [rdi + KERNEL_STRUCTURE_STREAM.flags],	~LIB_SYS_STREAM_FLAG_undefinied

.not_empty:
	; release stream
	mov	byte [rdi + KERNEL_STRUCTURE_STREAM.lock],	UNLOCK

	; restore original registers
	pop	r9
	pop	rdi
	pop	rsi
	pop	rcx

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rdi - pointer to stream descriptor
kernel_stream_release:
	; preserve original registers
	push	rcx
	push	rdi

	; lower stream usage
	dec	qword [rdi + KERNEL_STRUCTURE_STREAM.count]
	jnz	.end	; someone is still using it

	; release stream cache
	mov	rcx,	STD_STREAM_SIZE_page
	mov	rdi,	qword [rdi + KERNEL_STRUCTURE_STREAM.base_address]
	call	kernel_memory_release

	; mark stream descriptor as free
	mov	rdi,	qword [rsp]
	mov	qword [rdi + KERNEL_STRUCTURE_STREAM.base_address],	EMPTY

.end:
	; restore original registers
	pop	rdi
	pop	rcx

	; return from routine
	ret