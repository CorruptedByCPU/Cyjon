;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

%ifndef	KERNEL_INIT_ACPI
	%define	KERNEL_INIT_ACPI

	%define	KERNEL_INIT_ACPI_MADT_signature		0x43495041
	%define	KERNEL_INIT_ACPI_HPET_signature		0x54455048

	%define	KERNEL_INIT_ACPI_APIC_TYPE_lapic	0x00
	%define	KERNEL_INIT_ACPI_APIC_TYPE_io_apic	0x01

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

	struc	KERNEL_INIT_ACPI_STRUCTURE_HPET
		.address_space_id	resb	1
		.register_width		resb	1
		.register_offset	resb	1
		.reserved		resb	5
		.base_address		resq	1
	endstruc
%endif