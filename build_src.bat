@echo off
set /P version=Enter version (Format: x.y.z): 
cd src\
7z a -tzip "..\build\temp.zip" ".\*" -mx5
cd ..\
rename build\temp.zip cclite-beta-%version%.love
pause