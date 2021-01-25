;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

kernel_init_library:
	; mapuj przestrzeń logiczną bibliotek
	mov	rax,	LIBRARY_ENTRY_base_address
	mov	bx,	KERNEL_PAGE_FLAG_user | KERNEL_PAGE_FLAG_available
	mov	ecx,	kernel_init_library_file_end - kernel_init_library_file
	call	library_page_from_size
	call	kernel_page_map_logical

	; przenieś biblioteki na miejsce docelowe
	mov	ecx,	(kernel_init_library_file_end - kernel_init_library_file) >> STATIC_DIVIDE_BY_8_shift
	mov	rsi,	kernel_init_library_file
	mov	rdi,	LIBRARY_ENTRY_base_address
	rep	movsq
