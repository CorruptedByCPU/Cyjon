;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%define	LIB_ELF

%define	LIB_ELF_FLAG_execute			0b00000001
%define	LIB_ELF_FLAG_write			0b00000010
%define	LIB_ELF_FLAG_read			0b00000100

%define	LIB_ELF_TYPE_executable			2
%define	LIB_ELF_TYPE_shared_object		3

%define	LIB_ELF_HEADER_TYPE_load		1

%define	LIB_ELF_SECTION_TYPE_null		0x00
%define	LIB_ELF_SECTION_TYPE_string_table	0x03
%define	LIB_ELF_SECTION_TYPE_dynamic		0x06
%define	LIB_ELF_SECTION_TYPE_symbol_table	0x0B

%define	LIB_ELF_SECTION_DYNAMIC_TYPE_needed	1

struc	LIB_ELF_STRUCTURE
	.magic_number		resd	1
	.class			resb	1
	.memory_layout		resb	1
	.header_version		resb	1
	.abi			resb	1
	.abi_version		resb	1
	.padding		resb	7
	.type			resw	1
	.instruction_set	resw	1
	.elf_version		resd	1
	.program_entry_position	resq	1
	.header_table_position	resq	1
	.section_table_position	resq	1
	.flags			resd	1
	.header_size		resw	1
	.header_table_size	resw	1
	.header_entry_count	resw	1
	.section_table_size	resw	1
	.section_entry_count	resw	1
	.correlation		resw	1
endstruc

struc	LIB_ELF_STRUCTURE_HEADER
	.type			resd	1
	.flags			resd	1
	.segment_offset		resq	1
	.virtual_address	resq	1
	.physical_address	resq	1
	.segment_size		resq	1
	.memory_size		resq	1
	.alignment		resq	1
	.SIZE:
endstruc

struc	LIB_ELF_STRUCTURE_SECTION
	.name			resd	1
	.type			resd	1
	.flags			resq	1
	.virtual_address	resq	1
	.file_offset		resq	1
	.size_byte		resq	1
	.link			resd	1
	.info			resd	1
	.alignment		resq	1
	.entry_count		resq	1
	.SIZE:
endstruc

struc	LIB_ELF_STRUCTURE_SECTION_DYNAMIC
	.type			resq	1
	.offset			resq	1
	.SIZE:
endstruc

struc	LIB_ELF_STRUCTURE_DYNAMIC_SYMBOL
	.name_offset		resd	1
	.flags			resd	1
	.address		resq	1
	.size_byte		resq	1
	.SIZE:
endstruc