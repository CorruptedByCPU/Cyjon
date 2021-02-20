@echo off

IF EXIST "build\disk.vdi" ( DEL build\disk.vdi )

set PASS=0

VBoxManage convertfromraw --format vdi build\disk.raw build\disk.vdi --uuid {43251798-1c0c-4cb2-a02b-28868482b33e}	&& echo. || set PASS=1

timeout /t 1 /nobreak >NUL

IF %PASS% == 1 (
	PAUSE
)
