;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

	;-----------------------------------------------------------------------
	; structures, definitions
	;-----------------------------------------------------------------------
	; global ---------------------------------------------------------------
	%include	"library/std.inc"	; not required, but nice to have
	; library --------------------------------------------------------------
	%ifndef	LIB_SYS
		%include	"library/sys.inc"
	%endif
	;=======================================================================

; 64 bit code
[bits 64]

; we are using Position Independed Code
default	rel

;-------------------------------------------------------------------------------
; in:
;	interchangeably due to the LIB_SYS_REQUEST_*
lib_sys_request:
	; preserve original registers
	push	rcx
	push	r11

	; execute request
	syscall

	; restore original registers
	pop	r11
	pop	rcx

	; return from routine
	ret

;===============================================================================
; SUBSTITUTE OF LIBC
;===============================================================================

; yes, it's so simple ;)
; + small code
; - horrific amount of wasted memory (Hello, Chrome!)

;-------------------------------------------------------------------------------
; in:
;	rdi - length of space in Bytes
; out:
;	rax - pointer to allocated space
;	or EMPTY if no enough memory
malloc:
	; preserve original registers
	push	rdi

	; request for definied space
	mov	eax,	LIB_SYS_REQUEST_MEMORY_ALLOC
	add	rdi,	STD_QWORD_SIZE_byte << STD_MULTIPLE_BY_2_shift
	call	lib_sys_request
	jc	.end	; not enough space

	; store information about size of this space
	add	rdi,	STD_PAGE_mask
	shr	rdi,	STD_PAGE_SIZE_shift
	mov	qword [rax],	rdi

	; return pointer to space
	add	rax,	STD_QWORD_SIZE_byte << STD_MULTIPLE_BY_2_shift

.end:
	; restore original registers
	pop	rdi

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rdi - pointer to allocated space
free:
	; preserve original registers
	push	rax
	push	rsi
	push	rdi

	; request for definied space
	mov	eax,	LIB_SYS_REQUEST_MEMORY_RELEASE
	mov	rsi,	qword [rdi - (STD_QWORD_SIZE_byte << STD_MULTIPLE_BY_2_shift)]
	and	di,	STD_PAGE_mask
	call	lib_sys_request

.end:
	; restore original registers
	pop	rdi
	pop	rsi
	pop	rax

	; return from routine
	ret
