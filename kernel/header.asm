;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty, nagłówki
	;-----------------------------------------------------------------------
	%include	"config.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/config.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/header/ipc.asm"
	%include	"kernel/header/library.asm"
	%include	"kernel/header/service.asm"
	%include	"kernel/header/stream.asm"
	%include	"kernel/header/task.asm"
	%include	"kernel/header/vfs.asm"
	%include	"kernel/header/wm.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/macro/apic.asm"
	%include	"kernel/macro/copy.asm"
	%include	"kernel/macro/debug.asm"
	%include	"kernel/macro/library.asm"
	%include	"kernel/macro/lock.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/library/bosu/header.asm"
	%include	"kernel/library/font/header.asm"
	%include	"kernel/library/rgl/header.asm"
	%include	"kernel/library/terminal/header.asm"
	;-----------------------------------------------------------------------
