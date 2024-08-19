;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

	;-----------------------------------------------------------------------
	; structures, definitions
	;-----------------------------------------------------------------------
	; global ---------------------------------------------------------------
	%include	"library/std.inc"	; not required, but nice to have
	; library --------------------------------------------------------------
	%ifndef	LIB_VFS
		%include	"library/vfs.inc"
	%endif
	;=======================================================================

; 64 bit code
[bits 64]

; we are using Position Independed Code
default	rel

; ;-------------------------------------------------------------------------------
; ; in:
; ;	rcx - length of path
; ;	rsi - path to file
; ;	rdi - pointer to begining of file data
; ;	rbp - pointer of file descriptor
; lib_vfs_file:
; 	; preserve original registers
; 	push	rcx
; 	push	rsi
; 	push	rdi

; 	; by default file does not exist
; 	mov	qword [rbp + KERNEL_STRUCTURE_STORAGE_FILE.id],	EMPTY

; .file:
; 	; file name length
; 	cmp	word [rdi + LIB_VFS_STRUCTURE.length],	cx
; 	jne	.next	; incorrect

; 	; check file name
; 	add	rdi,	LIB_VFS_STRUCTURE.name
; 	call	lib_string_compare

; 	; names are similar?
; 	jnc	.found	; yes

; 	; move pointer back to entry
; 	sub	rdi,	LIB_VFS_STRUCTURE.name

; .next:
; 	; no more files in VFS?
; 	cmp	word [rdi + LIB_VFS_STRUCTURE.length],	EMPTY
; 	je	.end

; 	; move pointer to next file
; 	add	rdi,	LIB_VFS_base

; 	; continue search
; 	jmp	.file

; .found:
; 	; return file specification

; 	; move pointer back to entry
; 	sub	rdi,	LIB_VFS_STRUCTURE.name

; 	; size in Bytes
; 	mov	rcx,	qword [rdi + LIB_VFS_STRUCTURE.size]
; 	mov	qword [rbp + KERNEL_STRUCTURE_STORAGE_FILE.size_byte],	rcx

; 	; and ID
; 	mov	qword [rbp + KERNEL_STRUCTURE_STORAGE_FILE.id],	rdi

; .end:
; 	; restore original registers
; 	pop	rdi
; 	pop	rsi
; 	pop	rcx

; 	; return from routine
; 	ret

; ;-------------------------------------------------------------------------------
; ; in:
; ;	rsi - pointer to begining of file data
; lib_vfs_init:
; 	; preserve original registers
; 	push	rax
; 	push	rsi

; 	; VFS position inside memory
; 	mov	rax,	rsi

; .loop:
; 	; all files parsed?
; 	cmp	word [rsi + LIB_VFS_STRUCTURE.length],	EMPTY
; 	je	.end	; yes

; 	; set correct file content offsets, related to package inside memory
; 	add	qword [rsi + LIB_VFS_STRUCTURE.offset],	rax

; 	; next file
; 	add	rsi,	LIB_VFS_STRUCTURE.SIZE
; 	jmp	.loop

; .end:
; 	; restore original registers
; 	pop	rsi
; 	pop	rax

; 	; return from routine
; 	ret

; ;-------------------------------------------------------------------------------
; ; in:
; ;	rsi - file identificator
; ;	rdi - file data destination
; lib_vfs_read:
	; ; preserve original registers
	; push	rcx
	; push	rsi
	; push	rdi

	; ; file size in Bytes
	; mov	rcx,	qword [rsi + LIB_VFS_STRUCTURE.size]

	; ; file data position
	; mov	rsi,	qword [rsi + LIB_VFS_STRUCTURE.offset]

	; ; copy file content
	; rep	movsb

	; ; restore original registers
	; pop	rdi
	; pop	rsi
	; pop	rcx

	; ; return from routine
	; ret
