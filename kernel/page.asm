;===============================================================================
;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

KERNEL_PAGE_FLAG_available	equ	0x01
KERNEL_PAGE_FLAG_write		equ	0x02
KERNEL_PAGE_FLAG_user		equ	0x04
KERNEL_PAGE_FLAG_write_through	equ	0x08
KERNEL_PAGE_FLAG_cache_disable	equ	0x10
KERNEL_PAGE_FLAG_length		equ	0x80

KERNEL_PAGE_RECORDS_amount	equ	512

KERNEL_PAGE_PML4_SIZE_byte	equ	KERNEL_PAGE_RECORDS_amount * KERNEL_PAGE_PML3_SIZE_byte
KERNEL_PAGE_PML3_SIZE_byte	equ	KERNEL_PAGE_RECORDS_amount * KERNEL_PAGE_PML2_SIZE_byte
KERNEL_PAGE_PML2_SIZE_byte	equ	KERNEL_PAGE_RECORDS_amount * KERNEL_PAGE_PML1_SIZE_byte
KERNEL_PAGE_PML1_SIZE_byte	equ	KERNEL_PAGE_RECORDS_amount * KERNEL_PAGE_SIZE_byte

kernel_page_pml4_address	dq	STATIC_EMPTY

kernel_page_total_count		dq	STATIC_EMPTY
kernel_page_free_count		dq	STATIC_EMPTY
kernel_page_reserved_count	dq	STATIC_EMPTY
kernel_page_paged_count		dq	STATIC_EMPTY

;===============================================================================
; wejście:
;	rdi - adres strony do wyczyszczenia
kernel_page_drain:
	; zachowaj oryginalne rejestry
	push	rcx

	; rozmiar strony w Bajtach
	mov	rcx,	KERNEL_PAGE_SIZE_byte
	call	.proceed

	; przywróć oryginalne rejestry
	pop	rcx

	; powrót z procedury
	ret

;-------------------------------------------------------------------------------
; uwagi:
;	rcx - zniszczony
.proceed:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdi

	; wyczyść przestrzeń
	xor	rax,	rax
	shr	rcx,	STATIC_DIVIDE_BY_8_shift	; po 8 Bajtów na raz
	and	di,	KERNEL_PAGE_mask	; wyrównaj adres przestrzeni w dół (failsafe)
	rep	stosq

	; przywróć orygialne rejestry
	pop	rdi
	pop	rax

	; powrót z podprocedury
	ret

;===============================================================================
; wejście:
;	rcx - ilość kolejnych stron do wyczyszczenia
;	rdi - wskaźnik do pierwszej strony
kernel_page_drain_few:
	; zachowaj oryginalne rejestry
	push	rcx

	; oblicz rozmiar przestrzeni do wyczyszczenia
	shl	rcx,	KERNEL_PAGE_SIZE_shift
	call	kernel_page_drain.proceed

	; przywróć oryginalne rejestry
	pop	rcx

	; powrót z procedury
	ret
