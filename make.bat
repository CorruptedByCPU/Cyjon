del build\disk.raw.lock

set WIDTH=640
set HEIGHT=480

nasm -f bin software/init.asm		-o build/init
nasm -f bin software/shell.asm		-o build/shell
nasm -f bin software/hello.asm		-o build/hello

nasm -f bin kernel/init/boot.asm	-o build/boot
nasm -f bin kernel/kernel.asm		-o build/kernel -dMULTIBOOT_VIDEO_WIDTH_pixel=%WIDTH% -dMULTIBOOT_VIDEO_HEIGHT_pixel=%HEIGHT%
nasm -f bin zero/zero.asm		-o build/disk.raw -dMULTIBOOT_VIDEO_WIDTH_pixel=%WIDTH% -dMULTIBOOT_VIDEO_HEIGHT_pixel=%HEIGHT%

pause
