/*==============================================================================
Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
==============================================================================*/

	//----------------------------------------------------------------------
	// constants, structures, definitions
	//----------------------------------------------------------------------
	// global --------------------------------------------------------------
	#include	<dirent.h>
	#include	<stdint.h>
	#include	<stdio.h>
	#include	<stdlib.h>
	#include	<string.h>
	#include	<sys/stat.h>
	// library -------------------------------------------------------------
	#define	LIB_VFS_align		16
	#define	LIB_VFS_length		4
	#define	LIB_VFS_magic		0x53465623	// "#VFS"
	#define	LIB_VFS_name_limit	40
	#define	LIB_VFS_shift		6
	#define	LIB_VFS_default		2

	#define	LIB_VFS_TYPE_default	0

	// this structure should be divisible by power of 2
	struct LIB_VFS_STRUCTURE {
		uint64_t	offset;
		uint64_t	size;
		uint64_t	length;
		uint8_t		name[ LIB_VFS_name_limit ];
	};
	//======================================================================

#define	STATIC_PAGE_SIZE_byte		4096
#define	MACRO_PAGE_ALIGN_UP( value )	(((value) + STATIC_PAGE_SIZE_byte - 1) & ~(STATIC_PAGE_SIZE_byte - 1))
#define	EMPTY				0

char path_export[] = "build/";
char file_extension[] = ".vfs";
char name_symlink[] = "..";

int main( int argc, char *argv[] ) {
	// prepare import path
	char path_import[ sizeof( argv[ 1 ] ) ];
	snprintf( path_import, sizeof( path_import ), "%s%c", argv[ 1 ], 0x2F );

	// prepare vfs header
	struct LIB_VFS_STRUCTURE *vfs = malloc( sizeof( struct LIB_VFS_STRUCTURE ) * LIB_VFS_default );

	// prepare default symlinks for root directory
	vfs[ 0 ].offset = EMPTY;
	vfs[ 0 ].length = 1;
	strncpy( (char *) &vfs[ 0 ].name, name_symlink, 1 );
	vfs[ 1 ].offset = EMPTY;
	vfs[ 1 ].length = 2;
	strncpy( (char *) &vfs[ 1 ].name, name_symlink, 2 );

	// included files
	uint64_t files_included = 2;

	// directory entry
	struct dirent *entry = NULL;

	// open directory content
	DIR *directory = opendir( argv[ 1 ] );

	// for every file inside directory
	while( (entry = readdir( directory )) != NULL ) {
		// ignore system files
		if( ! strcmp( entry -> d_name, "." ) || ! strcmp( entry -> d_name, ".." ) ) continue;

		// file name longer than limit?
		if( strlen( entry -> d_name ) > LIB_VFS_name_limit ) { printf( "Name \"%s\" too long.", entry -> d_name ); return -1; }

		// resize header for new file
		vfs = realloc( vfs, sizeof( struct LIB_VFS_STRUCTURE ) * (files_included + 1) );

		// insert: name, length
		vfs[ files_included ].length = strlen( entry -> d_name );
		strcpy( (char *) vfs[ files_included ].name, entry -> d_name );

		// combine path to file
		char path_local[ sizeof( argv[ 1 ] ) + vfs[ files_included ].length ];
		snprintf( path_local, sizeof( path_local ), "%s%s", path_import, vfs[ files_included ].name );

		// insert: size of file in Bytes
		struct stat finfo;
		stat( (char *) path_local, &finfo );	// get file specification
		vfs[ files_included ].size = finfo.st_size;

		// next directory entry
		files_included++;
	}

	// we don't need it anymore, close it up
	closedir( directory );

	// last entry keep as empty
	vfs[ files_included++ ].offset = EMPTY;

	// offset of first file inside package
	uint64_t offset = MACRO_PAGE_ALIGN_UP( sizeof( struct LIB_VFS_STRUCTURE ) * files_included );

	// calculate offset for every registered file
	for( uint64_t i = LIB_VFS_default; i < files_included - 1; i++ ) {
		// first file
		vfs[ i ].offset = offset;

		// next file (align file position)
		offset += MACRO_PAGE_ALIGN_UP( vfs[ i ].size );
	}

	// update size of root directory inside symlinks
	for( uint8_t i = 0; i < LIB_VFS_default; i++ ) vfs[ i ].size = MACRO_PAGE_ALIGN_UP( sizeof( struct LIB_VFS_STRUCTURE ) * files_included );

	// show content of package with properties of file
	printf( "Offset [byte]\tSize [Bytes]\tLength\tName\n" );	// header of table
	for( uint8_t i = 0; i < files_included - 1; i++ ) printf( "%lX\t\t%lu\t\t%u\t%s\n", vfs[ i ].offset, vfs[ i ].size, (unsigned int) vfs[ i ].length, vfs[ i ].name );

	// show amount of included files
	printf( "%lu entries of \"%s\".\n\n", files_included - 1, argv[ 1 ] );

	// // /*--------------------------------------------------------------------*/

	// combine path to file
	char path_local[ sizeof( path_export ) + sizeof( argv[ 1 ] ) + sizeof( file_extension ) ];
	snprintf( path_local, sizeof( path_local ), "%s%s%s", path_export, argv[ 1 ], file_extension );

	// open new package for write
	FILE *fvfs = fopen( path_local, "w" );

	// append file header
	uint64_t size = sizeof( struct LIB_VFS_STRUCTURE ) * files_included;	// last data offset in Bytes
	fwrite( vfs, size, 1, fvfs );

	// append files described in header
	for( uint64_t i = LIB_VFS_default; i < files_included - 1; i++ ) {
		// align file to offset
		for( uint64_t j = 0; j < MACRO_PAGE_ALIGN_UP( size ) - size; j++ ) fputc( '\x00', fvfs );

		// combine path to file
		char path_insert[ sizeof( path_import ) + vfs[ i ].length ];
		snprintf( path_insert, sizeof( path_insert ), "%s%s", path_import, vfs[ i ].name );

		// append file to package
		FILE *file = fopen( path_insert, "r" );
		for( uint64_t f = 0; f < vfs[ i ].size; f++ ) fputc( fgetc( file ), fvfs );
		fclose( file );

		// last data offset in Bytes
		size = vfs[ i ].offset + vfs[ i ].size;
	}

	// release header
	free( vfs );

	// align magic value to uint32_t size
	for( uint8_t a = 0; a < sizeof( uint32_t ) - (size % sizeof( uint32_t )); a++ ) fputc( '\x00', fvfs );

	// append magic value to end of vfs file
	uint32_t magic = LIB_VFS_magic;
	fwrite( &magic, LIB_VFS_length, 1, fvfs );

	// close package
	fclose( fvfs );

	// package created
	return 0;
}
