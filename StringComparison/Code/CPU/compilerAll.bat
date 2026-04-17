@echo off
echo Starting C++ file compilation...

REM For loop iterating through base filenames (without .cpp extension)
for %%F in (MainCodeTrial OptimizedCodeTrial UltraOptimizedCodeTrial) do (
    echo.
    echo =========================================
    echo Processing: %%F.cpp for VTune
    echo =========================================

    echo [1/2] Standard compilation for compiler: g++ -g %%F.cpp -o %%F_compiler
    g++ -g %%F.cpp -o %%F_compiler

    echo [2/2] Optimized compilation for compiler: g++ -g -O3 %%F.cpp -o %%FO3_compiler
    g++ -g -O3 %%F.cpp -o %%FO3_compiler
)

echo.
echo All compilations completed!