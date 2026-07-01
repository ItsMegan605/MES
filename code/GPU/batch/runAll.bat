echo off
setlocal enabledelayedexpansion

:: Lista dei file da compilare ed eseguire (senza l'estensione .cu)
set FILES= StrideTail
::StrideCode StrideTail 
for %%f in (%FILES%) do (
    echo ========================================================
    echo [1/2] Compilazione di %%f.cu in corso...
    
    :: Compila il file CUDA con lo standard C++17
    nvcc -std=c++17 %%f.cu -o %%f.exe
    
    :: Controlla se la compilazione è andata a buon fine
    if !errorlevel! equ 0 (
        echo [2/2] Compilazione riuscita. Avvio di %%f.exe...
        
        :: Esegue il binario passando il nome per il CSV come parametro
        :: Es: %%f.exe KMP_results
        %%f.exe %%f_results
        
        echo Benchmark per %%f terminato.
    ) else (
        echo [ERRORE] La compilazione di %%f.cu e' fallita. Salto l'esecuzione.
    )
    echo.
)

echo ========================================================
echo Tutti i file sono stati elaborati e i benchmark terminati!
pause