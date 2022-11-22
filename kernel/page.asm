;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; in:
;	rdi - physical/logical address of page
kernel_page_clean:
	; preserve original register
	push	rcx

	; clean whole 1 page
	mov	rcx,	STATIC_PAGE_SIZE_page
	call	.proceed

	; restore original register
	pop	rcx

	; return from routine
	ret

;-------------------------------------------------------------------------------
; out:
;	rcx - EMPTY
.proceed:
	; preserve original registers
	push	rax
	push	rdi

	; clean area
	xor	rax,	rax
	shl	rcx,	STATIC_MULTIPLE_BY_512_shift	; 8 Bytes at a time
	rep	stosq

	; restore original registers
	pop	rdi
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rcx - pages
;	rdi - physical/logical address
kernel_page_clean_few:
	; preserve original register
	push	rcx

	; convert to Bytes and clean up
	call	kernel_page_clean.proceed

	; restore original register
	pop	rcx

	; return from routine
	ret