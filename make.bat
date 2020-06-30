rem select a resolution supported by the BIOS
set WIDTH=640
set HEIGHT=480

..\nasm -f bin software/console.asm	-o build/console

..\nasm -f bin kernel/init/boot.asm	-o build/boot
..\nasm -f bin kernel.asm		-o build/kernel
FOR /F "usebackq" %%A IN ('build/kernel') DO set KERNEL_SIZE=%%~zA

..\nasm -f bin zero.asm			-o build/zero		-dKERNEL_FILE_SIZE_bytes=%KERNEL_SIZE% -dSELECTED_VIDEO_WIDTH_pixel=%WIDTH% -dSELECTED_VIDEO_HEIGHT_pixel=%HEIGHT%
FOR /F "usebackq" %%A IN ('build/zero') DO set ZERO_SIZE=%%~zA

..\nasm -f bin bootsector.asm		-o build/bootsector	-dZERO_FILE_SIZE_bytes=%ZERO_SIZE%

..\nasm -f bin disk.asm			-o build/disk.raw

rem error check
pause
