@echo off
setlocal
set "GODOT_PATH="

:: Search for Godot.exe in the entire user directory recursively
for /f "delims=" %%F in ('dir /s /b "%USERPROFILE%\Godot.exe" 2^>nul') do (
    set "GODOT_PATH=%%F"
    goto :found
)

:: If not found, display an error and exit
echo Godot.exe not found!
exit /b 1

:found
echo Found: %GODOT_PATH%
"%GODOT_PATH%" %*