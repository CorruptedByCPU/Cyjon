# select a resolution supported by the BIOS
WIDTH=1920
HEIGHT=1080

nasm -f bin software/tm.asm		-o build/tm
nasm -f bin software/hello.asm		-o build/hello
nasm -f bin software/console.asm	-o build/console
nasm -f bin software/shell.asm		-o build/shell
nasm -f bin software/ls.asm		-o build/ls
nasm -f bin software/cat.asm		-o build/cat
nasm -f bin software/moko.asm		-o build/moko
nasm -f bin software/soler.asm		-o build/soler
nasm -f bin software/taris.asm		-o build/taris
nasm -f bin software/mural.asm		-o build/mural

nasm -f bin kernel/library.asm		-o build/library
nasm -f bin kernel.asm			-o build/kernel
KERNEL_SIZE=`wc -c < build/kernel`

nasm -f bin zero/ap.asm			-o build/ap
nasm -f bin zero.asm			-o build/zero		-dKERNEL_FILE_SIZE_bytes=${KERNEL_SIZE} -dSELECTED_VIDEO_WIDTH_pixel=${WIDTH} -dSELECTED_VIDEO_HEIGHT_pixel=${HEIGHT}
ZERO_SIZE=`wc -c < build/zero`

nasm -f bin bootsector.asm		-o build/bootsector	-dZERO_FILE_SIZE_bytes=${ZERO_SIZE}

nasm -f bin disk.asm			-o build/cyjon.img
