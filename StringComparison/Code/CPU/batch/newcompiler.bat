@echo off
setlocal enabledelayedexpansion

:: Cattura tutti gli argomenti passati allo script (es. -g -lcrypto)
set "EXTRA_FLAGS=%*"

echo Starting C++ file compilation...
if not "%EXTRA_FLAGS%"=="" (
    echo Using additional flags: %EXTRA_FLAGS%
)

:: Ciclo for che itera sui nomi base dei file
for %%F in (MainCodeTrial OptimizedCodeTrial UltraOptimizedCodeTrial) do (
    echo.
    echo =========================================
    echo Processing: %%F.cpp
    echo =========================================

    echo [-] Standard compilation: g++ %%F.cpp -o %%F !EXTRA_FLAGS!
    g++ %%F.cpp -o %%F !EXTRA_FLAGS!

    :: Compila con -O3 solo se il file NON è MainCodeTrial
    if /I "%%F"=="UltraOptimizedCodeTrial" (
        echo [-] Optimized compilation: g++ -O3 %%F.cpp -o %%FO3 !EXTRA_FLAGS!
        g++ -O3 %%F.cpp -o %%FO3 !EXTRA_FLAGS!
    )
)

echo.
echo All compilations completed!
endlocal