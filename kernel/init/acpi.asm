;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; void
kernel_init_acpi:
	; preserve original registers
	push	rcx
	push	rsi
	push	rdi

	; RSDP or XSDP header properties
	mov	rsi,	qword [kernel_limine_rsdp_request + LIMINE_RSDP_REQUEST.response]
	mov	rsi,	qword [rsi + LIMINE_RSDP_RESPONSE.address]

	; check revision number of RSDP/XSDP header
	cmp	byte [rsi + KERNEL_STRUCTURE_INIT_ACPI_RSDP_OR_XSDP_HEADER.revision],	EMPTY
	jne	.extended	; no

	; RSDT header properties
	mov	edi,	dword [rsi + KERNEL_STRUCTURE_INIT_ACPI_RSDP_OR_XSDP_HEADER.rsdt_address]

	; amount of entries
	mov	ecx,	dword [edi + KERNEL_STRUCTURE_INIT_ACPI_DEFAULT.length]
	sub	ecx,	KERNEL_STRUCTURE_INIT_ACPI_DEFAULT.SIZE
	shr	ecx,	STD_DIVIDE_BY_4_shift

	; pointer to list of RSDT entries
	add	edi,	KERNEL_STRUCTURE_INIT_ACPI_DEFAULT.SIZE

.rsdt_entry:
	; parse entry
	mov	esi,	dword [edi]
	call	.parse

	; next entry from RSDT table
	add	edi,	STD_DWORD_SIZE_byte

	; end of table?
	dec	ecx
	jnz	.rsdt_entry	; no

	; everything parsed
	jmp	.acpi_end

.extended:
	; XSDT header properties
	mov	rdi,	qword [rsi + KERNEL_STRUCTURE_INIT_ACPI_RSDP_OR_XSDP_HEADER.xsdt_address]

	; amount of entries
	mov	ecx,	dword [edi + KERNEL_STRUCTURE_INIT_ACPI_DEFAULT.length]
	sub	ecx,	KERNEL_STRUCTURE_INIT_ACPI_DEFAULT.SIZE
	shr	ecx,	STD_DIVIDE_BY_8_shift

	; pointer to list of XSDT entries
	add	rdi,	KERNEL_STRUCTURE_INIT_ACPI_DEFAULT.SIZE

.xsdt_entry:
	; parse entry
	mov	rsi,	qword [rdi]
	call	.parse

	; next entry from XSDT table
	add	rdi,	STD_QWORD_SIZE_byte

	; end of table?
	dec	rcx
	jnz	.xsdt_entry	; no

.acpi_end:
	; restore original registers
	pop	rdi
	pop	rsi
	pop	rcx

	; return from routine
	ret

	;-----------------------------------------------------------------------
	; second, parse every entry to find what we need
	;-----------------------------------------------------------------------

.parse:
	; header of MADT (Multiple APIC Description Table)?
	cmp	dword [rsi + KERNEL_STRUCTURE_INIT_ACPI_DEFAULT.signature],	KERNEL_INIT_ACPI_MADT_signature
	je	.madt	; yes

	; return from subroutine
	ret

.madt:
	; preserve original registers
	push	rax
	push	rcx
	push	rsi

	; store LAPIC base address
	mov	eax,	dword [rsi + KERNEL_STRUCTURE_INIT_ACPI_MADT.lapic_address]
	mov	dword [r8 + KERNEL.lapic_base_address],	eax
	; under logical address
	mov	rax,	KERNEL_PAGE_mirror
	or	qword [r8 + KERNEL.lapic_base_address],	rax

	; length of MADT list
	mov	ecx,	dword [rsi + KERNEL_STRUCTURE_INIT_ACPI_DEFAULT.length]
	sub	ecx,	KERNEL_STRUCTURE_INIT_ACPI_MADT.SIZE	; adjust for header size

	; pointer of MADT list
	add	rsi,	KERNEL_STRUCTURE_INIT_ACPI_MADT.SIZE

.madt_entry:
	; we found I/O APIC?
	cmp	byte [rsi + KERNEL_STRUCTURE_INIT_ACPI_MADT_ENTRY.type],	KERNEL_INIT_ACPI_APIC_TYPE_io_apic
	je	.madt_io_apic	; yes

.madt_next:
	; get size of entry being processed
	movzx	eax,	byte [rsi + KERNEL_STRUCTURE_INIT_ACPI_MADT_ENTRY.length]

	; move pointer to next entry
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
	; I/O APIC supports interrupt vectors 0+?
	cmp	dword [rsi + KERNEL_STRUCTURE_INIT_ACPI_IO_APIC.gsib],	EMPTY
	jne	.madt_next	; no

	; store base address of I/O APIC
	mov	eax,	dword [rsi + KERNEL_STRUCTURE_INIT_ACPI_IO_APIC.base_address]
	mov	dword [r8 + KERNEL.io_apic_base_address],	eax
	; under logical address
	mov	rax,	KERNEL_PAGE_mirror
	or	qword [r8 + KERNEL.io_apic_base_address],	rax

	; continue
	jmp	.madt_next