;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

KERNEL_IDT_IRQ_offset			equ	0x20

KERNEL_IDT_TYPE_exception		equ	0x8E00
KERNEL_IDT_TYPE_irq			equ	0x8F00
KERNEL_IDT_TYPE_isr			equ	0xEF00

kernel_idt_string_exception_default	db	STATIC_ASCII_NEW_LINE, STATIC_COLOR_ASCII_RED_LIGHT, "IDT: exception default", STATIC_ASCII_NEW_LINE
kernel_idt_string_exception_default_end:
kernel_idt_string_exception_gpf		db	STATIC_ASCII_NEW_LINE, STATIC_COLOR_ASCII_RED_LIGHT, "IDT: exception general protection fault", STATIC_ASCII_NEW_LINE
kernel_idt_string_exception_gpf_end:
kernel_idt_string_exception_page_fault	db	STATIC_ASCII_NEW_LINE, STATIC_COLOR_ASCII_RED_LIGHT, "IDT: exception page fault", STATIC_ASCII_NEW_LINE
kernel_idt_string_exception_page_fault_end:

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

	macro_debug	"kernel_idt_mount"

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

	macro_debug	"kernel_idt_update"

;===============================================================================
; domyślna obsługa wyjątku procesora
kernel_idt_exception_default:
	; przełącz w tryb debugowania
	jmp	kernel_debug

	macro_debug	"kernel_idt_exception_default"

;===============================================================================
kernel_idt_exception_general_protection_fault:
	; wyświetl komunikat
	mov	ecx,	kernel_idt_string_exception_gpf_end - kernel_idt_string_exception_gpf
	mov	rsi,	kernel_idt_string_exception_gpf
	call	kernel_video_string

	; przerwij pracę debugera Bochs
	xchg	bx,bx

	nop
	nop

	; zatrzymaj dalsze wykonywanie kodu dla aktualnego procesu
	jmp	$

	macro_debug	"kernel_idt_exception_general_protection_fault"

;===============================================================================
kernel_idt_exception_page_fault:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi

	; wyświetl komunikat
	mov	ecx,	kernel_idt_string_exception_page_fault_end - kernel_idt_string_exception_page_fault
	mov	rsi,	kernel_idt_string_exception_page_fault
	call	kernel_video_string

	; przerwij pracę debugera Bochs
	xchg	bx,bx

	nop
	nop
	nop

	; zatrzymaj dalsze wykonywanie kodu dla aktualnego procesu
	jmp	$

	macro_debug	"kernel_idt_exception_page_fault"

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

	macro_debug	"kernel_idt_interrupt_hardware"

;===============================================================================
; obsługa nieprawidłowego przerwania programowego
kernel_idt_interrupt_software:
	; zwróć informację o błędzie
	or	word [rsp + KERNEL_TASK_STRUCTURE_IRETQ.eflags],	KERNEL_TASK_EFLAGS_cf

	; wróć do zadania
	iretq

	macro_debug	"kernel_idt_interrupt_software"

;===============================================================================
; obsługa przerwania "nieobsłużonego"
kernel_idt_spurious_interrupt:
	; wróć do zadania
	iretq

	macro_debug	"kernel_idt_spurious_interrupt"
