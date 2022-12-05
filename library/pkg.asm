;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; in:
;	rcx - length of path
;	rsi - path to file
;	rdi - pointer to begining of file data
;	rbp - pointer of file descriptor
lib_pkg_file:
	; preserve original registers
	push	rcx
	push	rsi
	push	rdi

	; by default file does not exist
	mov	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.id],	EMPTY

.file:
	; file name length
	cmp	qword [rdi + LIB_PKG_STRUCTURE.length],	rcx
	jne	.next	; incorrect

	; check file name
	add	rdi,	LIB_PKG_STRUCTURE.name
	call	lib_string_compare
	sub	rdi,	LIB_PKG_STRUCTURE.name

	; names are similar?
	jnc	.found	; yes

.next:
	; no more files in PKG?
	cmp	qword [rdi + LIB_PKG_STRUCTURE.offset],	EMPTY
	je	.end

	; move pointer to next file
	add	rdi,	LIB_PKG_base

	; continue search
	jmp	.file

.found:
	; return file specification

	; size in Bytes
	mov	rcx,	qword [rdi + LIB_PKG_STRUCTURE.size]
	mov	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.size_byte],	rcx

	; and ID
	mov	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.id],	rdi

.end:
	; restore original registers
	pop	rdi
	pop	rsi
	pop	rcx

	; return from routine
	ret