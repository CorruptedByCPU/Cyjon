;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%define	KERNEL_INIT_ACPI_MADT_ENTRY_TYPE_io_apic	0x01

struc	KERNEL_INIT_ACPI_STRUCTURE_RSDP_OR_XSDP_HEADER
	.signature		resq	1
	.checksum		resb	1
	.oem_id			resb	6
	.revision		resb	1
	.rsdt_address		resd	1
	.length			resd	1
	.xsdt_address		resq	1
	.extended_checksum	resb	1
	.reserved		resb	3
endstruc

struc	KERNEL_INIT_ACPI_STRUCTURE_DEFAULT
	.signature		resd	1
	.length			resd	1
	.revision		resb	1
	.checksum		resb	1
	.oem_id			resb	6
	.oem_table_id		resq	1
	.oem_revision		resd	1
	.creator_id		resd	1
	.creator_revision	resd	1
	.SIZE:
endstruc

struc	KERNEL_INIT_ACPI_STRUCTURE_MADT
	.madt			resb	KERNEL_INIT_ACPI_STRUCTURE_DEFAULT.SIZE
	.lapic_address		resd	1
	.flags			resd	1
	.SIZE:
endstruc

struc	KERNEL_INIT_ACPI_STRUCTURE_MADT_ENTRY
	.type			resb	1
	.length			resb	1
endstruc

struc	KERNEL_INIT_ACPI_STRUCTURE_IO_APIC
	.type			resb	1
	.length			resb	1
	.ioapic_id		resb	1
	.reserved		resb	1
	.base_address		resd	1
	.gsib			resd	1
endstruc