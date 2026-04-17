@echo off
setlocal enabledelayedexpansion

:: Set current directory to script path
cd /d "%~dp0"

set MIN_THREADS=1
set MAX_THREADS=16
set ITERATIONS=5

:: =====================================================================

if "%~1 Resource"==" " (
    echo Error: You must provide the executable name as a parameter.
    exit /b 1
)

:: Check if the second argument (target word) is present
if "%~2"=="" (
    echo Error: You must provide the target word as the second argument.
    exit /b 1
)

:: Assign the second parameter to the variable
set "TARGET_STRING=%~2"

:: Extract ONLY the filename, ignoring the path (e.g., MainCodeTrial.exe)
set "EXE_NAME=%~nx1"

:: Set CSV name based on the executable name and check for "uneven"
if /I "%TARGET_STRING%"=="uneven" (
    set "OUTPUT_CSV=%~n1Uneven.csv"
) else (
    set "OUTPUT_CSV=%~n1.csv"
)

if not exist "!EXE_NAME!" (
    echo Error: The executable "!EXE_NAME!" was not found in this folder.
    exit /b 1
)

if not exist "giant_file.txt" (
    echo [WARNING] The file "giant_file.txt" is not present in the directory.
    echo.
)

:: Header: Using semicolon (;) as a separator and "duration" for clarity
echo thread;iteration;duration > "%OUTPUT_CSV%"

echo Starting benchmark...
echo Results will be saved to: %OUTPUT_CSV%
echo Detected executable: !EXE_NAME!
echo Test word: %TARGET_STRING%
echo.

for /L %%T in (%MIN_THREADS%, 1, %MAX_THREADS%) do (
    echo Running tests with %%T threads...

    for /L %%I in (1, 1, %ITERATIONS%) do (

        :: Clean execution: since it's in the same folder, just call the filename
        for /f "delims=" %%R in ('!EXE_NAME! %TARGET_STRING% %%T') do (
            set THROUGHPUT=%%R
        )
        echo Iteration %%I: Throughput = !THROUGHPUT! ms

        :: Save to CSV using semicolon (;) separator
        echo %%T;%%I;!THROUGHPUT! >> "%OUTPUT_CSV%"
    )
)

echo.
echo Benchmark completed successfully!
endlocal