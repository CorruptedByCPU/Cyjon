;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

; we are using Position Independed Code
default	rel

; 64 bit code
[bits 64]

; information for linker
section .text

;------------------------------------------------------------------------------
; in:
;	rcx - length of both strings
;	rsi - first string pointer
;	rdi - second string pointer
; out:
;	ZF - if equal
lib_string_compare:
	; preserve original register
	push	rax
	push	rcx
	push	rsi
	push	rdi

.compare:
	; are they different?
	mov	al,	byte [rsi]
	cmp	al,	byte [rdi]
	jnz	.different	; no

	; next character from strings
	inc	rsi
	inc	rdi

	; end of strings?
	dec	rcx
	jnz	.compare	; no

.different:
	; restore original register
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; return from library
	ret

;------------------------------------------------------------------------------
; in:
;	rsi - pointer to string
; out:
;	rcx - length of string
lib_string_length:
	; by default string is empty
	xor	ecx,	ecx

.loop:
	; end of string?
	cmp	byte [rsi + rcx],	STD_ASCII_TERMINATOR
	je	.end	; yes

	; next character from string
	inc	rcx

	; continue
	jmp	.loop

.end:
	; return from routine
	ret

;------------------------------------------------------------------------------
; in:
;	rcx - length of string
;	rsi - pointer to string
; out:
;	rcx - length of word
lib_string_word_end:
	; preserve original register
	push	rbx
	push	rsi

	; search from the beginning
	xor	ebx,	ebx
	xchg	rbx,	rcx

.check:
	; separator located?
	cmp	byte [rsi + rcx],	al
	je	.end	; yes

	; no
	inc	rcx

	; end of string?
	cmp	rcx,	rbx
	jb	.check	; no

	; whole string is "word"

.end:
	; restore original registers
	pop	rsi
	pop	rbx

	; return from library
	ret