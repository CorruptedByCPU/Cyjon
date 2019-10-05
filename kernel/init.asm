;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

	;-----------------------------------------------------------------------
	; wszystkie procedury inicjalizacyjne zostały zaprojektowane z myślą
	; o trybie 64 bitowym procesora, do tej pory Cyjon nie był kompatybilny
	; z programem rozruchowym GRUB, zatem aby tą kompatybilność uzyskać
	; najniższym kosztem, przełączam od razu procesor w tryb 64 bitowy
	;
	; program rozruchowy "Zero" zwraca już taki sam nagłówek Multiboot
	; oraz przekazuje procesor w trybie 32 bitowym do jądra systemu
	;
	; kod który przełącza procesor w tryb 64 bitowy, został zapożyczony
	; z programu rozruchowego "Zero" (bez modyfikacji)
	;-----------------------------------------------------------------------

	;-----------------------------------------------------------------------
	; przełącz procesor w tryb 64 bitowy
	;-----------------------------------------------------------------------
	%include	"kernel/init/long_mode.asm"

	;-----------------------------------------------------------------------
	; utworzenie binarnej mapy pamięci i oznaczenie w niej jądra systemu
	;-----------------------------------------------------------------------
	%include	"kernel/init/memory.asm"

	;-----------------------------------------------------------------------
	%include	"kernel/init/data.asm"
	;-----------------------------------------------------------------------
