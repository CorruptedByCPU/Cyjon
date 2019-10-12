;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

KERNEL_IDT_IRQ_offset			equ	0x20

KERNEL_IDT_TYPE_exception		equ	0x8E00
KERNEL_IDT_TYPE_irq			equ	0x8F00
KERNEL_IDT_TYPE_isr			equ	0xEF00

;===============================================================================
; wejście:
;	rax - numer przerwania
;	rbx - identyfikator przerwania (wyjątek, sprzęt lub proces)
;	rdi - adres procedury obsługi przerwania
kernel_idt_mount:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdi

	; ustaw rejestry na swoje miejsca
	xchg	rax,	rdi

	; oblicz prdesunięcie do rekordu numeru przerwania
	shl	rdi,	STATIC_MULTIPLE_BY_16_shift
	add	rdi,	qword [kernel_idt_header + KERNEL_STRUCTURE_IDT_HEADER.address]

	; procedura obsługi przerwania
	mov	rcx,	1	; podłącz procedurę obsługi pod jeden rekord
	call	kernel_idt_update

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rax - adres logiczny procedury obsługi
;	bx - typ: wyjątek, przerwanie(sprzętowe, programowe)
;	rcx - ilość kolejnych rekordów o tej samej procedurze obsługi
;	rdi - adres rekordu do modyfikacji w Tablicy Deskryptorów Przerwań
; wyjście:
;	rdi - adres kolejnego rekordu w Tablicy Deskryptorów Przerwań
kernel_idt_update:
	; zachowaj oryginalne rejestry
	push	rcx

.next:
	; zachowaj adres procedury obsługi
	push	rax

	; załaduj do tablicy adres obsługi wyjątku (bity 15...0)
	stosw

	; selektor deskryptora kodu (GDT), wszystkie procedury wywoływane są z uprawnieniami ring0
	mov	ax,	KERNEL_STRUCTURE_GDT.cs_ring0
	stosw

	; typ: wyjątek, przerwanie(sprzętowe, programowe)
	mov	ax,	bx
	stosw

	; przywróć adres procedury obsługi
	mov	rax,	qword [rsp]

	; przemieszczamy do ax bity 31...16
	shr	rax,	STATIC_MOVE_HIGH_TO_AX_shift
	stosw

	; przemieszczamy do eax bity 63...32
	shr	rax,	STATIC_MOVE_HIGH_TO_EAX_shift
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
; domyślna obsługa wyjątku procesora
kernel_idt_exception_default:
	; przerwij pracę debugera Bochs
	xchg	bx,bx

	nop

	; wróć do zadania
	iretq

;===============================================================================
; domyślna obsługa przerwania sprzętowego
kernel_idt_interrupt_hardware:
	; zachowaj oryginalne rejestry
	push	rdi

	; poinformuj APIC o obsłużeniu aktualnego przerwania sprzętowego
	mov	rdi,	qword [kernel_apic_base_address]
	mov	dword [rdi + KERNEL_APIC_EOI_register],	STATIC_EMPTY

	; przywróć oryginalne rejestry
	pop	rdi

	; wróć do zadania
	iretq

;===============================================================================
; obsługa nieprawidłowego przerwania programowego
kernel_idt_interrupt_software:
	; zwróć informację o błędzie
	or	word [rsp + KERNEL_STRUCTURE_TASK_IRETQ.eflags],	KERNEL_TASK_EFLAGS_cf

	; wróć do zadania
	iretq

;===============================================================================
; obsługa przerwania "nieobsłużonego"
kernel_idt_spurious_interrupt:
	; wróć do zadania
	iretq
