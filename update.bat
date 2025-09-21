@echo off
setlocal enabledelayedexpansion

:: --- Paths ---
set "configFile=%~dp0\..\config\config.txt"
set "logFolder=%~dp0\..\logs"

:: --- Make sure logs folder exists ---
if not exist "%logFolder%" mkdir "%logFolder%"

:: --- Read newfolder and oldfolder from config.txt ---
set "newfolder="
set "oldfolder="
for /f "usebackq tokens=1,* delims==" %%A in ("%configFile%") do (
    set "name=%%A"
    set "value=%%B"
    :: Trim leading spaces
    for /f "tokens=* delims= " %%X in ("!value!") do set "value=%%X"
    if /i "!name!"=="newfolder" set "newfolder=!value!"
    if /i "!name!"=="oldfolder" set "oldfolder=!value!"
)

:: --- Debug: show what was read ---
echo New folder: "%newfolder%"
echo Old folder: "%oldfolder%"

:: --- Validate folders ---
if "!newfolder!"=="" (
    echo ERROR: newfolder is not set in config.txt
    pause
    exit /b
)
if "!oldfolder!"=="" (
    echo ERROR: oldfolder is not set in config.txt
    pause
    exit /b
)
if not exist "!newfolder!" (
    echo ERROR: Source folder does not exist: !newfolder!
    pause
    exit /b
)
if not exist "!oldfolder!" (
    echo ERROR: Destination folder does not exist: !oldfolder!
    pause
    exit /b
)

:: --- Duplicate/mismatch checker ---
echo Checking for duplicates and mismatches...
for /r "!oldfolder!" %%F in (*) do (
    set "oldFile=%%F"
    set "relPath=%%~pnxF"
    set "fileName=%%~nxF"
    set "sourceFile=!newfolder!\!fileName!"
    if exist "!sourceFile!" (
        set "oldSize=%%~zF"
        for %%S in ("!sourceFile!") do set "newSize=%%~zS"
        if not "!oldSize!"=="!newSize!" (
            echo Deleting mismatched file: !oldFile!
            del /f "!oldFile!"
        )
    )
)

:: --- Determine log filename with auto-increment ---
set "logFile=%logFolder%\log.txt"
set count=1
:checkLog
if exist "!logFile!" (
    set "logFile=%logFolder%\log (%count%).txt"
    set /a count+=1
    goto checkLog
)

:: --- Run robocopy ---
robocopy "!newfolder!" "!oldfolder!" /E /COPY:DAT /R:2 /W:2 /V /NP /LOG:"!logFile!"

echo Update complete. Log saved to "!logFile!"
pause
