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
	#include	<string.h>
	#include	<sys/stat.h>
	// library -------------------------------------------------------------
	#define	LIB_PKG_length		4
	#define	LIB_PKG_magic		"#PKG"
	#define	LIB_PKG_base		64
	#define	LIB_PKG_align		16
	#define	LIB_PKG_name_limit	40

	struct LIB_PKG_STRUCTURE {
		uint64_t	offset;
		uint64_t	size;
		uint64_t	length;
		uint8_t		name[ LIB_PKG_name_limit ];
	};
	//======================================================================

int main() {
	// prepare empty file header
	struct LIB_PKG_STRUCTURE pkg[ LIB_PKG_base ] = { 0 };

	// included files
	uint64_t files_included = 0;

	// directory entry
	struct dirent *entry = NULL;

	// open directory content
	DIR *directory = opendir( "system" );

	// for every file inside directory
	while( (entry = readdir( directory )) != NULL ) {
		// ignore system files
		if( ! strcmp( entry -> d_name, "." ) || ! strcmp( entry -> d_name, ".." ) ) continue;

		// file name longer than limit?
		if( strlen( entry -> d_name ) > LIB_PKG_name_limit ) { printf( "Name \"%s\" too long.", entry -> d_name ); return -1; }

		// insert: name, length
		pkg[ files_included ].length = strlen( entry -> d_name );
		strcpy( (char *) pkg[ files_included ].name, entry -> d_name );

		// combine path to file
		char system[ 7 ] = "system/";
		char path[ sizeof( system ) + pkg[ files_included ].length + 1 ];
		snprintf( path, sizeof( path ), "%s%s", system, pkg[ files_included ].name );

		// insert: size of file in Bytes
		struct stat finfo;
		stat( (char *) path, &finfo );	// get file specification
		pkg[ files_included ].size = finfo.st_size;

		// next directory entry if possible
		if( ++files_included < LIB_PKG_base ) continue;

		// show error message
		printf( "Overflow.\n" ); return -1;
	}

	// we don't need it anymore, close it up
	closedir( directory );

	// offset of first file inside package
	uint64_t offset = sizeof( struct LIB_PKG_STRUCTURE ) * (files_included + 1);

	// calculate offset for every registered file
	for( uint64_t i = 0; i < files_included; i++ ) {
		// first file
		pkg[ i ].offset = offset;

		// next file (align file position)
		offset += (pkg[ i ].size + (LIB_PKG_align - (pkg[ i ].size % LIB_PKG_align))) - sizeof( struct LIB_PKG_STRUCTURE );
	}

	// show amount of included files
	printf( "%lu entries.\n", files_included );

	// show content of package with properties of file
	printf( "Offset [byte]\tSize [byte]\tLength\tName\n" );	// header of table
	for( uint8_t i = 0; i < files_included; i++ ) printf( "%lu\t\t%lu\t\t%u\t%s\n", (uint64_t) pkg[ i ].offset, pkg[ i ].size, (unsigned int) pkg[ i ].length, pkg[ i ].name );

	/*--------------------------------------------------------------------*/

	// open new package for write
	FILE *fpkg = fopen( "build/system.pkg", "w" );

	// append file header
	fwrite( &pkg, sizeof( struct LIB_PKG_STRUCTURE ) * (files_included + 1), 1, fpkg );

	// append files described in header
	for( uint64_t i = 0; i < files_included; i++ ) {
		// combine path to file
		char system[ 7 ] = "system/";
		char path[ sizeof( system ) + pkg[ i ].length + 1 ];
		snprintf( path, sizeof( path ), "%s%s", system, pkg[ i ].name );

		// insert file
		FILE *file = fopen( path, "r" );
		uint64_t left = pkg[ i ].size;
		while( left-- ) fputc( fgetc( file ), fpkg );
		fclose( file );

		// align end of file up to offset
		for( uint16_t j = 0; j < LIB_PKG_align - (pkg[ i ].size % LIB_PKG_align); j++ ) fputc( '\x00', fpkg );
	}

	// append magic value to end of pkg file
	uint8_t magic[] = LIB_PKG_magic;
	fwrite( magic, LIB_PKG_length, 1, fpkg );

	// close package
	fclose( fpkg );

	// package created
	return 0;
}
