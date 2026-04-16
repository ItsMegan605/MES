@echo off
echo Inizio la compilazione dei file C++...

REM Ciclo for che itera sui nomi base dei file (senza l'estensione .cpp)
for %%F in (MainCodeTrial OptimizedCodeTrial UltraOptimizedCodeTrial) do (
    echo.
    echo =========================================
    echo Elaborazione di: %%F.cpp
    echo =========================================

    echo [1/2] Compilazione normale per compiler: g++ -g %%F.cpp -o %%F_compiler
    g++ -g %%F.cpp -o %%F_compiler

    echo [2/2] Compilazione ottimizzata per compiler: g++ -g -O3 %%F.cpp -o %%FO3_compiler
    g++ -g -O3 %%F.cpp -o %%FO3_compiler
)

echo.
echo Tutte le compilazioni sono terminate!