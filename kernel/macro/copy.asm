;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

; kopiowanie przestrzeni z RSI do RDI w fragmentach po 256 Bajtów
%macro	macro_copy	0
	; instrukcje SSE wymagają adresu wyrównanego do DWORD/QWORD
	align	STATIC_DWORD_SIZE_byte

	prefetchnta	[rsi + 256]
	prefetchnta	[rsi + 288]
	prefetchnta	[rsi + 320]
	prefetchnta	[rsi + 352]
	prefetchnta	[rsi + 384]
	prefetchnta	[rsi + 416]
	prefetchnta	[rsi + 448]
	prefetchnta	[rsi + 480]

	movdqa	xmm0,	[rsi]
	movdqa	xmm1,	[rsi + 0x10]
	movdqa	xmm2,	[rsi + 0x20]
	movdqa	xmm3,	[rsi + 0x30]
	movdqa	xmm4,	[rsi + 0x40]
	movdqa	xmm5,	[rsi + 0x50]
	movdqa	xmm6,	[rsi + 0x60]
	movdqa	xmm7,	[rsi + 0x70]
	movdqa	xmm8,	[rsi + 0x80]
	movdqa	xmm9,	[rsi + 0x90]
	movdqa	xmm10,	[rsi + 0xA0]
	movdqa	xmm11,	[rsi + 0xB0]
	movdqa	xmm12,	[rsi + 0xC0]
	movdqa	xmm13,	[rsi + 0xD0]
	movdqa	xmm14,	[rsi + 0xE0]
	movdqa	xmm15,	[rsi + 0xF0]

	movntdq	[rdi],	xmm0
	movntdq	[rdi + 0x10],	xmm1
	movntdq	[rdi + 0x20],	xmm2
	movntdq	[rdi + 0x30],	xmm3
	movntdq	[rdi + 0x40],	xmm4
	movntdq	[rdi + 0x50],	xmm5
	movntdq	[rdi + 0x60],	xmm6
	movntdq	[rdi + 0x70],	xmm7
	movntdq	[rdi + 0x80],	xmm8
	movntdq	[rdi + 0x90],	xmm9
	movntdq	[rdi + 0xA0],	xmm10
	movntdq	[rdi + 0xB0],	xmm11
	movntdq	[rdi + 0xC0],	xmm12
	movntdq	[rdi + 0xD0],	xmm13
	movntdq	[rdi + 0xE0],	xmm14
	movntdq	[rdi + 0xF0],	xmm15
%endmacro
