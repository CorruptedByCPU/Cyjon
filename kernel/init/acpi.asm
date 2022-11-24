;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; in:
;	r8 - kernel environment variables/rountines base address
kernel_init_acpi:
	; preserve original registers
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	rdi

	; RSDP available?
	cmp	qword [kernel_limine_rsdp_request + LIMINE_RSDP_REQUEST.response],	EMPTY
	jne	.available	; yes

.error:
	; RSDP is not available or something worse...
	mov	rsi,	kernel_log_rsdp
	call	driver_serial_string

	; hold the door
	jmp	$

	;-----------------------------------------------------------------------
	; second, parse every entry to find what we need
	;-----------------------------------------------------------------------

.parse:
	; header of MADT (Multiple APIC Description Table)?
	cmp	dword [rsi + KERNEL_INIT_ACPI_STRUCTURE_MADT.madt + KERNEL_INIT_ACPI_STRUCTURE_DEFAULT.signature],	"APIC"
	je	.madt	; yes

	; return from subroutine
	ret

.madt:
	; preserve original registers
	push	rax
	push	rcx
	push	rsi

	; store LAPIC base address
	mov	eax,	dword [rsi + KERNEL_INIT_ACPI_STRUCTURE_MADT.lapic_address]
	mov	dword [r8 + KERNEL_STRUCTURE.lapic_base_address],	eax

	; length of MADT table in entries
	mov	ecx,	dword [rsi + KERNEL_INIT_ACPI_STRUCTURE_MADT.madt + KERNEL_INIT_ACPI_STRUCTURE_DEFAULT.length]
	sub	ecx,	KERNEL_INIT_ACPI_STRUCTURE_MADT.SIZE	; adjust for header size

	; move pointer to first MADT entry
	add	rsi,	KERNEL_INIT_ACPI_STRUCTURE_MADT.SIZE

.madt_entry:
	; we found I/O APIC?
	cmp	byte [rsi + KERNEL_INIT_ACPI_STRUCTURE_MADT_ENTRY.type],	KERNEL_INIT_ACPI_MADT_ENTRY_TYPE_io_apic
	je	.madt_io_apic	; yes

.madt_next:
	; move pointer to next entry
	movzx	eax,	byte [rsi + KERNEL_INIT_ACPI_STRUCTURE_MADT_ENTRY.length]
	add	rsi,	rax

	; end of table?
	sub	rcx,	rax
	jnz	.madt_entry	; no

	; restore original registers
	pop	rsi
	pop	rcx
	pop	rax

	; return from subroutine
	ret

.madt_io_apic:
	; first interrupt number supported by this controller is ZERO?
	cmp	dword [rsi + KERNEL_INIT_ACPI_STRUCTURE_IO_APIC.gsib],	EMPTY
	jne	.madt_next	; no

	; store I/O APIC base address
	mov	eax,	dword [rsi + KERNEL_INIT_ACPI_STRUCTURE_IO_APIC.base_address]
	mov	dword [r8 + KERNEL_STRUCTURE.io_apic_base_address],	eax

	; continue
	jmp	.madt_next

	;-----------------------------------------------------------------------
	; first, we need to identify the ACPI version and according to its type,
	; process its entries
	;-----------------------------------------------------------------------

.available:
	; pointer to RSDP header
	mov	rsi,	qword [kernel_limine_rsdp_request + LIMINE_RSDP_REQUEST.response]
	mov	rsi,	qword [rsi + LIMINE_RSDP_RESPONSE.address]

	; check revision number of RSDP header
	cmp	byte [rsi + KERNEL_INIT_ACPI_STRUCTURE_RSDP_OR_XSDP_HEADER.revision],	EMPTY
	jne	.extended	; no

	; preserve original register
	push	rsi

	; show information about ACPI version
	mov	rsi,	kernel_acpi_standard
	call	driver_serial_string

	; restore original register
	pop	rsi

	; set pointer to RSDT header
	mov	edi,	dword [rsi + KERNEL_INIT_ACPI_STRUCTURE_RSDP_OR_XSDP_HEADER.rsdt_address]

	; entries inside table
	mov	ecx,	dword [edi + KERNEL_INIT_ACPI_STRUCTURE_DEFAULT.length]
	sub	ecx,	KERNEL_INIT_ACPI_STRUCTURE_DEFAULT.SIZE
	shr	ecx,	STATIC_DWORD_SIZE_shift

	; move pointer to first entry of RSDT table
	add	edi,	KERNEL_INIT_ACPI_STRUCTURE_DEFAULT.SIZE

.rsdt_entry:
	; parse entry
	mov	esi,	dword [edi]
	call	.parse

	; next entry from RSDT table
	add	edi,	STATIC_DWORD_SIZE_byte

	; end of table?
	dec	ecx
	jnz	.rsdt_entry	; no

	; everything parsed
	jmp	.acpi_end

.extended:
	; preserve original register
	push	rsi

	; show information about ACPI version
	mov	rsi,	kernel_acpi_extended
	call	driver_serial_string

	; restore original register
	pop	rsi

	; set pointer to XSDT header
	mov	rdi,	qword [rsi + KERNEL_INIT_ACPI_STRUCTURE_RSDP_OR_XSDP_HEADER.xsdt_address]

	; entries inside table
	mov	ecx,	dword [edi + KERNEL_INIT_ACPI_STRUCTURE_DEFAULT.length]
	sub	ecx,	KERNEL_INIT_ACPI_STRUCTURE_DEFAULT.SIZE
	shr	ecx,	STATIC_QWORD_SIZE_shift

	; move pointer to first entry of RSDT table
	add	rdi,	KERNEL_INIT_ACPI_STRUCTURE_DEFAULT.SIZE

.xsdt_entry:
	; parse entry
	mov	rsi,	qword [rdi]
	call	.parse

	; next entry from XSDT table
	add	rdi,	STATIC_QWORD_SIZE_byte

	; end of table?
	dec	rcx
	jnz	.xsdt_entry	; no

	;-----------------------------------------------------------------------
	; at last, "Show Me What You Got."
	;-----------------------------------------------------------------------

.acpi_end:
	; LAPIC controller is available?
	cmp	qword [r8 + KERNEL_STRUCTURE.lapic_base_address],	EMPTY
	je	.error	; no

	; show information about LAPIC
	mov	rsi,	kernel_acpi_lapic
	call	driver_serial_string
	mov	rax,	qword [r8 + KERNEL_STRUCTURE.lapic_base_address]
	mov	ebx,	STATIC_NUMBER_SYSTEM_hexadecimal
	call	driver_serial_value

	; I/O APIC controller is available?
	cmp	qword [r8 + KERNEL_STRUCTURE.io_apic_base_address],	EMPTY
	je	.error	; no

	; show information about I/O APIC
	mov	rsi,	kernel_acpi_io_apic
	call	driver_serial_string
	mov	rax,	qword [r8 + KERNEL_STRUCTURE.io_apic_base_address]
	mov	ebx,	STATIC_NUMBER_SYSTEM_hexadecimal
	call	driver_serial_value

	; restore original registers
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; return from routine
	ret