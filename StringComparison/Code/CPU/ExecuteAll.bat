@echo off
setlocal

:: Imposta la directory corrente a quella dello script
cd /d "%~dp0"

call compileAll.bat

:: Nome dello script di benchmark creato precedentemente
set "BENCHMARK_SCRIPT=ExecuteThreadVar.bat"

:: Controllo di sicurezza: verifica che lo script di benchmark esista
if not exist "%BENCHMARK_SCRIPT%" (
    echo Errore: Lo script "%BENCHMARK_SCRIPT%" non e' stato trovato.
    echo Assicurati che si chiami cosi' e sia nella stessa cartella.
    pause
    exit /b 1
)

echo Inizio l'esecuzione automatizzata di tutti i benchmark...
echo.

:: Lista di tutti gli eseguibili generati dal primo script di compilazione
set "EXECUTABLES=MainCodeTrial.exe OptimizedCodeTrial.exe OptimizedCodeTrialO3.exe UltraOptimizedCodeTrial.exe UltraOptimizedCodeTrialO3.exe"

:: Ciclo for che itera su ogni singolo eseguibile della lista
for %%E in (%EXECUTABLES%) do (
    echo =======================================================
    echo Avvio test per: %%E
    echo =======================================================
    
    :: Verifica che l'eseguibile esista prima di lanciare il test
    if exist "%%E" (
        echo [1/2] Esecuzione con parola target: albero
        call "%BENCHMARK_SCRIPT%" "%%E" "albero"
        
        echo.
        echo [2/2] Esecuzione con parola target: uneven
        call "%BENCHMARK_SCRIPT%" "%%E" "uneven"
    ) else (
        echo [ATTENZIONE] L'eseguibile "%%E" non esiste. Hai lanciato lo script di compilazione? Salto al prossimo...
    )
    
    echo.
)

echo.
echo =======================================================
echo Tutti i benchmark sono stati completati con successo!
echo =======================================================
pause
endlocal