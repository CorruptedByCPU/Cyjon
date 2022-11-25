;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https:;blackdev.org/). All rights reserved.
;===============================================================================

struc	KERNEL_LAPIC_STRUCTURE
	.reserved_0	resb	32
	.id		resd	1
	reserved_1	resb	92
	.tp		resd	1
	reserved_2	resb	44
	.eoi		resd	1
	reserved_3	resb	28
	.ld		resd	1
	reserved_4	resb	12
	.df		resd	1
	reserved_5	resb	12
	.siv		resd	1
	reserved_6	resb	524
	.icl		resd	1
	reserved_7	resb	12
	.ich		resd	1
	reserved_8	resb	12
	.lvt		resd	1
	reserved_9	resb	92
	.tic		resd	1
	reserved_A	resb	12
	.tcc		resd	1
	reserved_B	resb	76
	.tdc		resd	1
endstruc