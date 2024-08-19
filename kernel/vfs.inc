;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

%ifndef	KERNEL_VFS
	%define	KERNEL_VFS

	%define	KERNEL_VFS_limit		(STD_PAGE_byte / KERNEL_STRUCTURE_VFS.SIZE )

	struc	KERNEL_STRUCTURE_VFS
		.storage	resq	1
		.knot		resq	1
		.pid		resq	1
		.lock		resq	1	; amount of opened instances
		.semaphore	resb	1	; set if someone is writing or reallocating file area
		.SIZE:
	endstruc

	struc	KERNEL_STRUCTURE_VFS_PROPERTIES
		.byte		resq	1
		.name_length	resb	1
		.name		resb	LIB_VFS_NAME_limit + 1
	endstruc
%endif