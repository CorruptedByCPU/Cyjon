@echo off

IF EXIST "build\cyjon.vdi" ( DEL build\cyjon.vdi )

set PASS=0

VBoxManage convertfromraw --format vdi build\cyjon.img build\cyjon.vdi --uuid {43251798-1c0c-4cb2-a02b-28868482b33e}	&& echo. || set PASS=1

timeout /t 1 /nobreak >NUL

IF %PASS% == 1 (
	PAUSE
)
