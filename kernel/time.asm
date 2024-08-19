;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;------------------------------------------------------------------------------
; out:
;	rax - RDTSC value
kernel_time_rdtsc:
	; preserve original register
	push	rdx

	; receive current CPU cycle count
	rdtsc

	; combine values
	shl	rdx,	STD_MOVE_DWORD
	or	rax,	rdx

	; restore original register
	pop	rdx

	; return from routine
	ret