;===============================================================================
; Copyright (C) by Andrzej Adamczyk at Wataha.net
;===============================================================================

;===============================================================================
kernel_init_smp:
	xchg	bx,bx

	; dostępny jest tylko jeden procesor logiczny?
	cmp	word [kernel_init_ap_count],	STATIC_TRUE
	jbe	.finish	; tak, pomiń inicjalizacje pozostałych

	; ustaw kod rozruchowy dla procesorów logicznych na docelowe miejsce
	mov	ecx,	kernel_init_boot_file_end - kernel_init_boot_file
	mov	rsi,	kernel_init_boot_file
	mov	rdi,	0x8000	; 0x0000:0x8000
	rep	movsb

	; otwórz docelową ścieżkę dla procesorów logicznych w procedurach inicjalizacyjnych
	mov	byte [kernel_init_smp_semaphore],	STATIC_TRUE

	; pobierz identyfikator procesora BSP
	mov	rdi,	qword [kernel_apic_base_address]
	mov	eax,	dword [rdi + KERNEL_APIC_ID_register]
	shr	eax,	24	; przesuń bity 24..31 do 0..7

	; zachowaj identyfikator
	mov	dl,	al

	; inicjalizuj kolejne procesory logiczne
	mov	rsi,	kernel_apic_id_table

	; ilość procesorów logicznych
	mov	cx,	word [kernel_init_ap_count]

; .init:
; 	; koniec procesorów logicznych do uruchomienia?
; 	dec	cx
; 	js	.init_done	; tak
;
; 	; pobierz identyfikator procesora logicznego
; 	lodsb
;
; 	; procesor logiczny BSP?
; 	cmp	al,	dl
; 	je	.init	; tak, pomiń
;
; 	; wyślij polecenie INIT do procesora logicznego
; 	shl	eax,	24
; 	mov	dword [rdi + KERNEL_ACPI_MADT_LAPIC_ICH_register],	eax
; 	mov	eax,	0x00004500
; 	mov	dword [rdi + KERNEL_ACPI_MADT_LAPIC_ICL_register],	eax
;
; .init_wait:
; 	; wykonano polecenie?
; 	bt	dword [rdi + KERNEL_ACPI_MADT_LAPIC_ICL_register],	KERNEL_ACPI_MADT_LAPIC_ICL_COMMAND_COMPLETE_bit
; 	jc	.init_wait	; czekaj
;
; 	; następny procesor logiczny
; 	jmp	.init
;
; .init_done:
; 	; odczekaj około 10ms
; 	mov	rax,	qword [kernel_rtc_microtime]
; 	add	rax,	10
;
; .init_wait_for_ipi:
; 	; czas upłynął?
; 	cmp	rax,	qword [kernel_rtc_microtime]
; 	ja	.init_wait_for_ipi	; nie
;
; 	; uruchom kolejne procesory logiczne
; 	mov	rsi,	kernel_init_lapic_id_list
;
; 	; ilość procesorów logicznych
; 	mov	cx,	word [kernel_lapic_cpu_count]
;
; .start:
; 	; koniec procesorów logicznych?
; 	dec	cx
; 	js	.finish	; tak
;
; 	; pobierz identyfikator procesora logicznego
; 	lodsb
;
; 	; procesor logiczny BSP?
; 	cmp	al,	dl
; 	je	.start	; tak, pomiń
;
; 	; wyślij polecenie START do procesora logicznego (wektor 0x08 > 0x8000)
; 	shl	eax,	24
; 	mov	dword [rdi + KERNEL_ACPI_MADT_LAPIC_ICH_register],	eax
; 	mov	eax,	0x00004608
; 	mov	dword [rdi + KERNEL_ACPI_MADT_LAPIC_ICL_register],	eax
;
; .wait_for_start:
; 	; wykonano polecenie?
; 	bt	dword [rdi + KERNEL_ACPI_MADT_LAPIC_ICL_register],	KERNEL_ACPI_MADT_LAPIC_ICL_COMMAND_COMPLETE_bit
; 	jc	.wait_for_start	; czekaj
;
; 	; następny procesor logiczny
; 	jmp	.start
;
.finish:
	; ; poinformuj o ilości dostępnych procesorów logicznych
	; mov	dword [kernel_video_color],	STATIC_COLOR_default
	; mov	ecx,	kernel_init_smp_available_end - kernel_init_smp_available
	; mov	rsi,	kernel_init_smp_available
	; call	kernel_video_string
	;
	; ; ilość
	; movzx	eax,	word [kernel_lapic_cpu_count]
	; mov	ebx,	STATIC_NUMBER_SYSTEM_decimal
	; xor	ecx,	ecx
	; mov	dword [kernel_video_color],	STATIC_COLOR_white
	; call	kernel_video_number
	;
	; ; przesuń kursor do nowej linii
	; mov	al,	STATIC_ASCII_NEW_LINE
	; mov	dword [kernel_video_color],	STATIC_COLOR_default
	; call	kernel_video_char
	;
	; ; ilość procesorów logicznych w systemie
	; mov	eax,	dword [kernel_lapic_cpu_count]
	;
; .wait:
; 	; wszystkie procesory logiczne zainicjowane?
; 	cmp	eax,	dword [kernel_ap_initialized_count]
; 	jne	.wait	; nie, czekaj dalej
