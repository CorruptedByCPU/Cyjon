;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%ifndef	KERNEL_STREAM
	%define	KERNEL_STREAM

	%define	KERNEL_STREAM_limit		(KERNEL_TASK_limit << STATIC_MULTIPLE_BY_2_shift)

	%define	KERNEL_STREAM_FLAG_closed	00000001b
	%define	KERNEL_STREAM_FLAG_meta		00000010b

	%define KERNEL_STREAM_META_size_byte	8

	struc	KERNEL_STREAM_STRUCTURE
		.base_address	resq	1
		.start		resw	1
		.end		resw	1
		.free		resw	1
		.lock		resb	1
		.flags		resb	1
		.count		resq	1
		.meta		resb	KERNEL_STREAM_META_size_byte
		.SIZE:
	endstruc
%endif