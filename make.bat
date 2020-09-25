@echo off

rem MS/Windows build fix ... even if I'm compiling a new kernel ... the file contains a previous version -_-
IF EXIST "build\kernel" ( DEL build\kernel )

rem select a resolution supported by the BIOS
set WIDTH=800
set HEIGHT=600

set PASS=0

..\nasm -f bin software/tm.asm		-o build/tm		&& echo. || set PASS=1
..\nasm -f bin software/hello.asm	-o build/hello		&& echo. || set PASS=1
..\nasm -f bin software/console.asm	-o build/console	&& echo. || set PASS=1
..\nasm -f bin software/shell.asm	-o build/shell		&& echo. || set PASS=1

..\nasm -f bin kernel/init/boot.asm	-o build/boot		&& echo. || set PASS=1
..\nasm -f bin kernel.asm		-o build/kernel		&& echo. || set PASS=1
FOR /F "usebackq" %%A IN ('build/kernel') DO set KERNEL_SIZE=%%~zA

..\nasm -f bin zero.asm			-o build/zero		-dKERNEL_FILE_SIZE_bytes=%KERNEL_SIZE% -dSELECTED_VIDEO_WIDTH_pixel=%WIDTH% -dSELECTED_VIDEO_HEIGHT_pixel=%HEIGHT%	&& echo. || set PASS=1
FOR /F "usebackq" %%A IN ('build/zero') DO set ZERO_SIZE=%%~zA

..\nasm -f bin bootsector.asm		-o build/bootsector	-dZERO_FILE_SIZE_bytes=%ZERO_SIZE%	&& echo. || set PASS=1

..\nasm -f bin disk.asm			-o build/disk.raw	&& echo. || set PASS=1

IF %PASS% == 1 (
	pause
)
