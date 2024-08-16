;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

%ifndef	KERNEL_STREAM
	%define	KERNEL_STREAM

	%define	KERNEL_STREAM_limit		(KERNEL_TASK_limit << STD_SHIFT_2)

	%define	KERNEL_STREAM_FLAG_data		0b00000001
	%define	KERNEL_STREAM_FLAG_modified	0b00000010
	%define	KERNEL_STREAM_FLAG_null		0b01000000
	%define	KERNEL_STREAM_FLAG_closed	0b10000000

	struc	KERNEL_STRUCTURE_STREAM
		.base_address	resq	1
		.start		resw	1
		.end		resw	1
		.free		resw	1
		.lock		resb	1
		.flags		resb	1
		.count		resq	1
		.meta		resb	LIB_SYS_STREAM_META_LENGTH_byte
		.SIZE:
	endstruc
%endif