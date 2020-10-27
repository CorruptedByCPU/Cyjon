;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

struc	KERNEL_STRUCTURE_GDT_HEADER
	.limit						resb	2
	.address					resb	8
endstruc

struc	KERNEL_STRUCTURE_GDT
	.null						resb	8
	.cs_ring0					resb	8
	.ds_ring0					resb	8
	.cs_ring3					resb	8
	.ds_ring3					resb	8
	.tss						resb	8
	.SIZE:
endstruc

kernel_init_gdt:
	; zarezerwuj przestrzeń dla Globalnej Tablicy Deskryptorów
	call	kernel_memory_alloc_page
	jc	kernel_panic_memory

	; wyczyść tablicę GDT i zachowaj jej adres
	call	kernel_page_drain
	mov	qword [kernel_gdt_header + KERNEL_STRUCTURE_GDT_HEADER.address],	rdi

	; utwórz deskryptor NULL
	xor	eax,	eax
	stosq	; zapisz

	; utwórz deskryptor kodu ring0 (CS)
	mov	rax,	0000000000100000100110000000000000000000000000000000000000000000b
	stosq	; zapisz

	; utwórz deskryptor danych/stosu ring0 (DS/SS)
	mov	rax,	0000000000100000100100100000000000000000000000000000000000000000b
	stosq	; zapisz

	; utwórz deskryptor kodu ring3 (CS)
	mov	rax,	0000000000100000111110000000000000000000000000000000000000000000b
	stosq	; zapisz

	; utwórz deskryptor danych/stosu ring3 (DS/SS)
	mov	rax,	0000000000100000111100100000000100000000000000000000000000000000b
	stosq	; zapisz

	; zachowaj adres pośredni pierwszego deskryptora TSS
	and	di,	~STATIC_PAGE_mask
	mov	word [kernel_gdt_tss_bsp_selector],	di

	; utwórz N deskryptorów TSS dla procesorów logicznych
	mov	cx,	word [kernel_apic_count]
	mov	rsi,	kernel_apic_id_table

.loop:
	; pobierz identyfikator procesora logicznego
	lodsb

	; zamień na deskryptor
	and	eax,	STATIC_BYTE_mask
	shl	eax,	STATIC_MULTIPLE_BY_16_shift

	; ustaw wskaźnik na docelowy deskryptor TSS procesora logicznego
	mov	rdi,	qword [kernel_gdt_header + KERNEL_STRUCTURE_GDT_HEADER.address]
	add	rdi,	rax
	add	di,	word [kernel_gdt_tss_bsp_selector]

	; rozmiar tablicy Task State Segment w Bajtach
	mov	ax,	kernel_gdt_tss_table_end - kernel_gdt_tss_table
	stosw	; zapisz

	; pobierz adres fizyczny tablicy Task State Segment
	mov	rax,	kernel_gdt_tss_table
	stosw	; zapisz (bity 15..0)
	shr	rax,	16	; przesuń starszą część rejestru EAX do AX
	stosb	; zapisz (bity 23..16)

	; zachowaj pozostałą część adresu tablicy Task State Segment
	push	rax

	; uzupełnij deskryptor Task State Segment o flagi
	mov	al,	10001001b	; P, DPL, 0, Type
	stosb	; zapisz
	xor	al,	al		; G, 0, 0, AVL, Limit (starsza część rozmiaru tablicy Task State Segment)
	stosb	; zapisz

	; przywróć pozostałą część adresu tablicy Task State Segment
	pop	rax

	; przenieś bity 31..24 do rejestru AL
	shr	rax,	8
	stosb	; zapisz (bity 31..24)

	; przenieś bity 63..32 do rejestru EAX
	shr	rax,	8
	stosd	; zapisz (bity 63..32)

	; 32 Bajty deskryptora - zastrzeżone
	xor	rax,	rax
	stosd	; zapisz

	; utworzyć pozostałe?
	dec	cx
	jnz	.loop	; tak

	; przeładuj Globalną Tablicę Deskryptorów
	lgdt	[kernel_gdt_header]

	; załaduj deskryptor Task State Segment
	ltr	word [kernel_gdt_tss_bsp_selector]

	; zresetuj deskryptory niewykorzystywane
	mov	fs,	ax
	mov	gs,	ax

	; przeładuj głównedeskryptory
	mov	ax,	KERNEL_STRUCTURE_GDT.ds_ring0
	mov	ds,	ax	; danych
	mov	es,	ax	; ekstra
	mov	ss,	ax	; stosu
