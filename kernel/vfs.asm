;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; in:
;	rcx - length in Bytes
;	rsi - pointer to beginning of file
; out:
;	ZF - if valid VFS file
kernel_vfs_identify:
	; preserve original register
	push	rcx

	; offset of magic value
	shr	rcx,	STD_SHIFT_4
	dec	rcx

	; at end of file, magic value exist?
	cmp	dword [rsi + rcx * STD_SIZE_DWORD_byte],	LIB_VFS_magic

	; restore original register
	pop	rcx

	; return from routine
	ret

;------------------------------------------------------------------------------
; in:
;	rcx - length of string
;	rsi - pointer to string
; out:
;
;	rsi - pointer to file entry of EMPTY if not found
kernel_vfs_path:
	; preserve original registers
	push	rax
	push	rbx
	push	rcx
	push	rdi
	push	r8
	push	r9

	xchg	bx,bx

	; global kernel environment variables/functions/rountines
	mov	r8,	qword [kernel]

	; start from current file?
	cmp	byte [rsi],	STD_ASCII_SLASH
	je	.default_path

	; retrieve pointer to currently running task
	call	kernel_task_active

	; choose task current file
	mov	rdi,	qword [rdi + KERNEL_STRUCTURE_TASK.directory]

	; check path length
	jmp	.empty

.default_path:
	; start from default file
	imul	rax,	qword [r8 + KERNEL.storage_root],	KERNEL_STRUCTURE_STORAGE.SIZE
	mov	rdi,	qword [r8 + KERNEL.storage_base_address]
	mov	rdi,	qword [rdi + KERNEL_STRUCTURE_STORAGE.device_block]

.empty:
	; if path is empty
	test	rcx,	rcx
	jz	.end	; acquired VFS root file

	; remember current path length
	mov	rbx,	rcx

.search:
	; start from current file
	mov	rdi,	qword [rdi + LIB_VFS_STRUCTURE.offset]

.slash:
	; remove leading '/', if exist
	cmp	byte [rsi],	STD_ASCII_SLASH
	jne	.slash_removed	; done

	; next character from path
	inc	rsi

	; all slash characters removed?
	dec	rbx
	jnz	.slash	; no

.slash_removed:
	; select file name from path
	mov	al,	STD_ASCII_SLASH
	mov	rcx,	rbx
	call	lib_string_word_end

.check:
	; compare lengths
	cmp	byte [rdi + LIB_VFS_STRUCTURE.name_length],	cl
	jne	.not_found	; no

	; preserve original register
	push	rdi

	; compare names
	add	rdi,	LIB_VFS_STRUCTURE.name
	call	lib_string_compare

	; restore original register
	pop	rdi

	; equal?
	jnc	.equal	; yep

.not_found:
	; next file
	add	rdi,	LIB_VFS_STRUCTURE.SIZE

	; check next file?
	cmp	byte [rdi + LIB_VFS_STRUCTURE.name_length],	EMPTY
	jne	.search	; yes

	; file not found
	xor	esi,	esi

	; end of routine
	jmp	.end

.equal:
	; last file from path and requested one?
	cmp	cl,	byte [rdi + LIB_VFS_STRUCTURE.name_length]
	jne	.directory	; no

.directory:
	; follow bymsolic links (if possible)
	; ...

	; move pointer to next file inside path
	add	rsi,	rcx
	sub	rbx,	rcx	; left path length

	; continue search
	jmp	.search

.end:
	; restore original registers
	pop	r9
	pop	r8
	pop	rdi
	pop	rcx
	pop	rbx
	pop	rax

	; return from routine
	ret