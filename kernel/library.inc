;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%define	KERNEL_LIBRARY_limit			1

; this structure should be divisible by power of 2
struc	KERNEL_LIBRARY_STRUCTURE
	.device_type		resb	1

	; align next label
	alignb	0x08

	.SIZE:
endstruc