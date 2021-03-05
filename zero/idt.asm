;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

ZERO_IDT_address	equ	0xA000

ZERO_IDT_TYPE_exception	equ	0x8E00
ZERO_IDT_TYPE_irq	equ	0x8F00

struc	ZERO_STRUCTURE_IDT_HEADER
	.limit		resb	2
	.address	resb	8
endstruc

;===============================================================================
zero_idt:
	; określ pozycję Tablicy Deskryptorów Przerwań
	mov	edi,	dword [zero_page_table_address]
	add	edi,	ZERO_STRUCTURE_GRAPHICS_MODE_INFO_BLOCK.SIZE

	; zachowaj wskaźnik początku przestrzeni
	mov	dword [zero_idt_table_address],	edi

	; zarejestruj wszystkie wyjątki procesora pod domyślną procedurę obsługi
	mov	rax,	zero_idt_default_exception
	mov	bx,	ZERO_IDT_TYPE_exception
	mov	ecx,	32	; wszystkie wyjątki procesora
	call	zero_idt_set

	; podłącz procedurę obsługi przerwania zegara
	mov	rax,	zero_idt_clock
	mov	bx,	ZERO_IDT_TYPE_irq
	mov	ecx,	1
	call	zero_idt_set

	; zarejestruj pozostałe przerwania sprzętowe pod domyślną procedurę obsługi
	mov	rax,	zero_idt_default_interrupt
	mov	ecx,	15	; pozostałe przerwania sprzętowe
	call	zero_idt_set

	; załaduj Tablicę Deskryptorów Przerwań
	lidt	[zero_idt_header]

	; włącz obsługę przerwań
	sti

	; kontynuuj
	jmp	zero_idt_end

;===============================================================================
zero_idt_default_exception:
	; powrót z przerwania wyjątku procesora
	iretq

;===============================================================================
zero_idt_default_interrupt:
	; zachowaj oryginalne rejestry
	push	rax

	; zaakceptuj przerwnaie
	mov	al,	0x20
	out	0x20,	al

	; przywróćoryginalne rejestry
	pop	rax

	; powrót z przerwania sprzętowego
	iretq

;===============================================================================
zero_idt_clock:
	; zachowaj oryginalne rejestry
	push	rax

	; zwiększ mikrotime
	inc	qword [zero_microtime]

	; zaakceptuj przerwnaie
	mov	al,	0x20
	out	0x20,	al

	; przywróćoryginalne rejestry
	pop	rax

	; powrót z przerwania sprzętowego
	iretq

;===============================================================================
; wejście:
;	rax - adres logiczny procedury obsługi
;	bx - typ: wyjątek, przerwanie(sprzętowe, programowe)
;	rcx - ilość kolejnych rekordów o tej samej procedurze obsługi
;	rdi - adres rekordu do modyfikacji w Tablicy Deskryptorów Przerwań
; wyjście:
;	rdi - adres kolejnego rekordu w Tablicy Deskryptorów Przerwań
zero_idt_set:
	; zachowaj oryginalne rejestry
	push	rcx

.next:
	; zachowaj adres procedury obsługi
	push	rax

	; załaduj do tablicy adres obsługi wyjątku (bity 15...0)
	stosw

	; selektor deskryptora kodu (GDT), wszystkie procedury wywoływane są z uprawnieniami ring0
	mov	ax,	0x08
	stosw

	; typ: wyjątek, przerwanie(sprzętowe, programowe)
	mov	ax,	bx
	stosw

	; przywróć adres procedury obsługi
	mov	rax,	qword [rsp]

	; przemieszczamy do ax bity 31...16
	shr	rax,	16
	stosw

	; przemieszczamy do eax bity 63...32
	shr	rax,	32
	stosd

	; pola zastrzeżone, zostawiamy puste
	xor	eax,	eax
	stosd

	; przywróć adres procedury obsługi
	pop	rax

	; przetwórz pozostałe rekordy
	dec	rcx
	jnz	.next

	; przywróć oryginalne rejestry
	pop	rcx

	; powrót z procedury
	ret

;===============================================================================
zero_idt_end:
