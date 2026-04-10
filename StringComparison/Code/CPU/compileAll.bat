@echo off
echo Inizio la compilazione dei file C++...

REM Ciclo for che itera sui nomi base dei file (senza l'estensione .cpp)
for %%F in (MainCodeTrial OptimizedCodeTrial UltraOptimizedCodeTrial) do (
    echo.
    echo =========================================
    echo Elaborazione di: %%F.cpp
    echo =========================================

    echo [1/2] Compilazione normale: g++ %%F.cpp -o %%F
    g++ %%F.cpp -o %%F

    echo [2/2] Compilazione ottimizzata: g++ -O3 %%F.cpp -o %%FO3
    g++ -O3 %%F.cpp -o %%FO3
)

echo.
echo Tutte le compilazioni sono terminate!