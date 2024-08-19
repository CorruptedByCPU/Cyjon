;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

; global kernel environment variables/functions
kernel	dq	EMPTY

; our limine requests

limine_framebuffer_request:
	dq	LIMINE_FRAMEBUFFER_MAGIC
	dq	0	; revision
	dq	EMPTY	; response

limine_memmap_request:
	dq	LIMINE_MEMMAP_MAGIC
	dq	0	; revision
	dq	EMPTY	; response

limine_rsdp_request:
	dq	LIMINE_RSDP_MAGIC
	dq	0	; revision
	dq	EMPTY	; response

limine_kernel_file_request:
	dq	LIMINE_KERNEL_FILE_MAGIC
	dq	0	; revision
	dq	EMPTY	; response

limine_kernel_address_request:
	dq	LIMINE_KERNEL_ADDRESS_MAGIC
	dq	0	; revision
	dq	EMPTY	; response

limine_smp_request:
	dq	LIMINE_SMP_MAGIC
	dq	0	; revision
	dq	EMPTY	; response
	dq	EMPTY	; flags: do not emable X2APIC

limine_module_request:
	dq	LIMINE_MODULE_MAGIC
	dq	0	; revision
	dq	EMPTY	; response

; TODO, remove me after refactorization
; often necessary
kernel_page_mirror		dq	KERNEL_PAGE_mirror