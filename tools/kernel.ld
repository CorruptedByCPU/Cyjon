/*===============================================================================
 Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
===============================================================================*/

OUTPUT_FORMAT( elf64-x86-64 )
OUTPUT_ARCH( i386:x86-64 )

ENTRY( _entry )

PHDRS {
	null	PT_NULL		FLAGS( 0 );
	text	PT_LOAD		FLAGS( (1 << 0) | (1 << 2) );
	rodata	PT_LOAD		FLAGS( (1 << 2) );
	data	PT_LOAD		FLAGS( (1 << 1) | (1 << 2) );
	bss	PT_LOAD		FLAGS( (1 << 1) | (1 << 2) );
	dynamic	PT_DYNAMIC	FLAGS( (1 << 1) | (1 << 2) );
}

SECTIONS {
	. = 0xffffffff80000000;

	.text : ALIGN( CONSTANT( MAXPAGESIZE ) ) {
		*(.text .text.*)
	} :text

	.rodata : ALIGN( CONSTANT( MAXPAGESIZE ) ) {
		*(.rodata .rodata.*)
	} :rodata

	.data : ALIGN( CONSTANT( MAXPAGESIZE ) ) {
		*(.data .data.*)
	} :data

	.data : ALIGN( CONSTANT( MAXPAGESIZE ) ) {
		*(.bss .bss.*)
	} :bss
}
