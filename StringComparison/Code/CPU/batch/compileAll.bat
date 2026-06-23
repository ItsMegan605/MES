@echo off
echo Starting C++ file compilation...

REM For loop iterating through base filenames (without .cpp extension)
for %%F in (MainCodeTrial OptimizedCodeTrial UltraOptimizedCodeTrial) do (
    echo.
    echo =========================================
    echo Processing: %%F.cpp
    echo =========================================

    echo [1/2] Standard compilation: g++ %%F.cpp -o %%F
    g++ %%F.cpp -o %%F

    echo [2/2] Optimized compilation: g++ -O3 %%F.cpp -o %%FO3
    g++ -O3 %%F.cpp -o %%FO3
)

echo.
echo All compilations completed!