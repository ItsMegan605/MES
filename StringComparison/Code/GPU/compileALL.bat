@echo off
setlocal enabledelayedexpansion

:: Lista dei file da compilare (senza l'estensione .cu)
set FILES= StrideTail
::StrideCode StrideTail

for %%f in (%FILES%) do (
    echo ========================================================
    echo Compilazione di %%f.cu in corso...
    
    :: Compila il file CUDA con lo standard C++17
    nvcc -lineinfo -std=c++17 %%f.cu -o %%f.exe
    
    :: Controlla se la compilazione è andata a buon fine
    if !errorlevel! equ 0 (
        echo [OK] Compilazione di %%f.cu riuscita. L'eseguibile %%f.exe e' pronto.
    ) else (
        echo [ERRORE] La compilazione di %%f.cu e' fallita.
    )
    echo.
)

echo ========================================================
echo Tutti i file sono stati elaborati! Compilazione terminata.
pause