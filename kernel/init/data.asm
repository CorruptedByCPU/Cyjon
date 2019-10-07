;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

kernel_init_string_video_welcome	db	"Welcome!", STATIC_ASCII_NEW_LINE
kernel_init_string_video_welcome_end:

kernel_init_string_error_memory		db	"Init: Memory map, error."
kernel_init_string_error_memory_end:
kernel_init_string_error_memory_low	db	"Not enough memory."
kernel_init_string_error_memory_low_end:
kernel_init_string_error_acpi		db	"ACPI table not found."
kernel_init_string_error_acpi_end:
kernel_init_string_error_acpi_2		db	"No support for ACPI v2.0+ version."
kernel_init_string_error_acpi_2_end:
kernel_init_string_error_acpi_corrupted	db	"ACPI table, corrupted."
kernel_init_string_error_acpi_corrupted_end:
kernel_init_string_error_apic		db	"APIC table not found."
kernel_init_string_error_apic_end:
kernel_init_string_error_ioapic		db	"I/O APIC table not found."
kernel_init_string_error_ioapic_end:

kernel_init_apic_semaphore		db	STATIC_FALSE
kernel_init_ioapic_semaphore		db	STATIC_FALSE
kernel_init_smp_semaphore		db	STATIC_FALSE
kernel_init_ap_count			db	STATIC_EMPTY

kernel_init_apic_id_highest		db	STATIC_EMPTY
