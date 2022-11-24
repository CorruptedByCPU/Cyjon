;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%define	KERNEL_PAGE_mask		0xFFFF000000000000
%define	KERNEL_PAGE_mirror		0xFFFF800000000000

%define	KERNEL_PAGE_ENTRY_count		512

%define	KERNEL_PAGE_PML1_SIZE_byte	KERNEL_PAGE_ENTRY_count * STATIC_PAGE_SIZE_byte
%define	KERNEL_PAGE_PML2_SIZE_byte	KERNEL_PAGE_ENTRY_count * KERNEL_PAGE_PML1_SIZE_byte
%define	KERNEL_PAGE_PML3_SIZE_byte	KERNEL_PAGE_ENTRY_count * KERNEL_PAGE_PML2_SIZE_byte
%define	KERNEL_PAGE_PML4_SIZE_byte	KERNEL_PAGE_ENTRY_count * KERNEL_PAGE_PML3_SIZE_byte

%define	KERNEL_PAGE_FLAG_present	1 << 0
%define	KERNEL_PAGE_FLAG_write		1 << 1
%define	KERNEL_PAGE_FLAG_user		1 << 2
%define	KERNEL_PAGE_FLAG_write_through	1 << 3
%define	KERNEL_PAGE_FLAG_cache_disable	1 << 4
%define	KERNEL_PAGE_FLAG_length		1 << 7
%define	KERNEL_PAGE_FLAG_process	1 << 9
%define	KERNEL_PAGE_FLAG_shared		1 << 10
%define	KERNEL_PAGE_FLAG_journal	1 << 11