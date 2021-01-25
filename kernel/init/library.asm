;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

kernel_init_library:
	xchg	bx,bx

	; mapuj przestrzeń logiczną bibliotek
	mov	ecx,	kernel_library_end - kernel_library
	call	library_page_from_size
	mov	rsi,	kernel_library
	mov	rdi,	LIBRARY_ENTRY_base_address
	; call	kernel_page_map_virtual

	; ; przenieś biblioteki na początek przestrzenikopiuj zbiór bibliotek w miejsce docelowe
	; mov	ecx,	kernel_init_libraries_end - kernel_init_libraries
	; mov	rsi,	kernel_init_libraries
	; rep	movsb
