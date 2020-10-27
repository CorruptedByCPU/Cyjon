;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
kernel_init_apic:
	; pobierz adres tablicy Local ACPI
	mov	rsi,	qword [kernel_apic_base_address]

	; wyłącz Task Priority i Priority Sub-Class
	mov	dword [rsi + KERNEL_APIC_TP_register],	STATIC_EMPTY

	; włącz Flat Mode
	mov	dword [rsi + KERNEL_APIC_DF_register],	KERNEL_APIC_DF_FLAG_flat_mode

	; wszystkie dostępne procesory otrzymują przerwania (fizyczne!)
	mov	dword [rsi + KERNEL_APIC_LD_register],	KERNEL_APIC_LD_FLAG_target_cpu

	; włącz kontroler APIC na procesorze BSP/logicznym
	mov	eax,	dword [rsi + KERNEL_APIC_SIV_register]
	or	eax,	KERNEL_APIC_SIV_FLAG_enable_apic | KERNEL_APIC_SIV_FLAG_spurious_vector
	mov	dword [rsi + KERNEL_APIC_SIV_register],	eax

	; włącz przerwania wew. czasu na kontrolerze APIC procesora BSP/logicznego
	mov	eax,	dword [rsi + KERNEL_APIC_LVT_TR_register]
	and	eax,	~KERNEL_APIC_LVT_TR_FLAG_mask_interrupts
	mov	dword [rsi + KERNEL_APIC_LVT_TR_register],	eax

	; numer przerwania sprzętowego podczas zakończenia odliczania czasu
	mov	dword [rsi + KERNEL_APIC_LVT_TR_register],	KERNEL_APIC_IRQ_number

	; przelicznik odliczanego czasu
	mov	dword [rsi + KERNEL_APIC_TDC_register],	KERNEL_APIC_TDC_divide_by_16

	; powróc z procedury
	ret
