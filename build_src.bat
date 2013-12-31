@echo off
set /P version=Enter version (Format: x.y.z):

REM Create the .love file
7z a -tzip ".\build\temp.zip" ".\src\*" -mx5
rename build\temp.zip cclite-%version%.love

REM Windows build
set win_build_folder=.\build\cclite-%version%-win\
if exist love-dist\windows (
	xcopy love-dist\windows %win_build_folder% /E
	copy /b %win_build_folder%\love.exe+build\cclite-%version%.love %win_build_folder%\cclite.exe
	7z a -tzip ".\build\cclite-%version%-win.zip" %win_build_folder% -mx5
)

REM OSX build
set win_build_folder=.\build\cclite-%version%-osx\
REM TODO: Copy love.app, insert OSX_Info.plist and .love into Resources/
if exist love-dist\macosx (
	
)

pause
