;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

kernel_init_ipc:
	; przygotuj przestrzeń pod listę wiadomości
	mov	ecx,	KERNEL_IPC_SIZE_page_default
	call	kernel_memory_alloc

	; wyczyść listę
	call	kernel_page_drain_few

	; zachowaj adres początku przestrzeni
	mov	qword [kernel_ipc_base_address],	rdi

	; połącz koniec przestrzeni z początkiem
	mov	qword [rdi + STATIC_STRUCTURE_BLOCK.link],	rdi
