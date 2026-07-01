@echo off
setlocal enabledelayedexpansion

:: Cattura tutti gli argomenti passati allo script
set "EXTRA_FLAGS=%*"

echo Starting C++ file compilation...
if not "%EXTRA_FLAGS%"=="" (
    echo Using additional flags: %EXTRA_FLAGS%
)

for %%F in (MainCodeTrial OptimizedCodeTrial UltraOptimizedCodeTrial) do (
    echo.
    echo =========================================
    echo Processing: %%F.cpp
    echo =========================================

    echo [-] Standard compilation: g++ %%F.cpp -o %%F !EXTRA_FLAGS!
    g++ %%F.cpp -o %%F !EXTRA_FLAGS!

    :: Compila con -O3 solo se il file è UltraOptimizedCodeTrial
    if /I "%%F"=="UltraOptimizedCodeTrial" (
        echo [-] Optimized compilation: g++ -O3 %%F.cpp -o %%FO3 !EXTRA_FLAGS!
        g++ -O3 %%F.cpp -o %%FO3 !EXTRA_FLAGS!
    )
)

echo.
echo All compilations completed!
endlocal