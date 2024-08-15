;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

%ifndef	MACRO
	%define MACRO

	; ; Bochs Enchanced Debugger: line break
	; %define	MACRO_DEBUF( void ) __asm__ volatile( "xchg %bx, %bx" );
	; ; support for while( TRUE );
	; %define	MACRO_NOP( void ) __asm__ volatile( "nop" );

	; ; exclusive access
	; %define	MACRO_LOCK( semaphore ) while( __sync_val_compare_and_swap( &semaphore, UNLOCK, LOCK ) ) {};
	; ; %define	MACRO_LOCK( semaphore ) while( __sync_val_compare_and_swap( &semaphore, UNLOCK, LOCK ) ) { __asm__ volatile( "int $0x20" ); };
	; %define	MACRO_UNLOCK( semaphore ) semaphore = UNLOCK;

	%define	MACRO_PAGE_ALIGN_UP( value )( ((value) + STD_PAGE_byte - 1) & ~(STD_PAGE_byte - 1) )
	%define	MACRO_PAGE_ALIGN_DOWN( value )( (value) & ~(STD_PAGE_byte - 1) )

	; %define	MACRO_STR2( x ) #x
	; %define	MACRO_STR( x ) MACRO_STR2( x )

	; %define MACRO_SIZEOF( structure, entry )( sizeof( ((structure *) 0 ) -> entry ))

	; %define MACRO_IMPORT_FILE_AS_STRING( name, file ) __asm__( ".section .rodata\n.global " MACRO_STR( name ) "\n.balign 16\n" MACRO_STR( name ) ":\n.incbin \"" file "\"\n.byte 0x00\n" ); \
	; 	extern const __attribute__( ( aligned( 16 ) ) ) void* name; \

	; %define MACRO_IMPORT_FILE_AS_ARRAY( name, file ) __asm__( ".section .rodata\n.global file_" MACRO_STR( name ) "_start\n.global file_" MACRO_STR( name ) "_end\n.balign 16\nfile_" MACRO_STR( name ) "_start:\n.incbin \"" file "\"\nfile_" MACRO_STR( name ) "_end:\n" ); \
	; 	extern const __attribute__( ( aligned( 16 ) ) ) void* file_ ## name ## _start; \
	; 	extern const void* file_ ## name ## _end;
	
	; %define MACRO_WORD( x ) ( *( (uint16_t *) (x) ) )
	; %define MACRO_DWORD( x ) ( *( (uint32_t *) (x) ) )
	; %define MACRO_QWORD( x ) ( *( (uint64_t *) (x) ) )

	; %define MACRO_ENDIANNESS_WORD( value )( (uint16_t) (value >> STD_MOVE_BYTE | value << STD_MOVE_BYTE) )
	; %define MACRO_ENDIANNESS_DWORD( value )( (uint32_t) (value >> (STD_MOVE_WORD + STD_MOVE_BYTE) | ((value >> STD_MOVE_BYTE) & 0xFF00) | ((value << STD_MOVE_BYTE) & 0xFF0000) | value << (STD_MOVE_WORD + STD_MOVE_BYTE)) )
%endif
