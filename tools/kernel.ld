/*==============================================================================
Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
==============================================================================*/

OUTPUT_FORMAT( elf64-x86-64 )
OUTPUT_ARCH( i386:x86-64 )

ENTRY( init )

PHDRS
{
	null    PT_NULL    FLAGS(0) ;                   /* Null segment */
	text    PT_LOAD    FLAGS((1 << 0) | (1 << 2)) ; /* Execute + Read */
	rodata  PT_LOAD    FLAGS((1 << 2)) ;            /* Read only */
	data    PT_LOAD    FLAGS((1 << 1) | (1 << 2)) ; /* Write + Read */
	bss	PT_LOAD    FLAGS((1 << 1) | (1 << 2)) ; /* Write + Read */
}

SECTIONS
{
    . = 0xffffffff80000000;

    .text : {
        *(.text .text.*)
    } :text

    . += CONSTANT(MAXPAGESIZE);

    .rodata : {
        *(.rodata .rodata.*)
    } :rodata

    . += CONSTANT(MAXPAGESIZE);

    .data : {
        *(.data .data.*)
    } :data

    . += CONSTANT(MAXPAGESIZE);

    .bss : {
        *(COMMON)
        *(.bss .bss.*)
    } :bss
}
