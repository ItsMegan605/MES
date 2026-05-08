@echo off
setlocal enabledelayedexpansion

:: =====================================================================
:: COSTANTI DI CONFIGURAZIONE
:: =====================================================================
set MIN_THREADS=1
set MAX_THREADS=16
set NUM_REP=10
set STRINGS=------------ unevenstring abracadabra
set SIZES= 500 1000 2000
:: set EXECUTABLES=MainCodeTrial.exe OptimizedCodeTrial.exe UltraOptimizedCodeTrial.exe UltraOptimizedCodeTrialO3.exe
set EXECUTABLES= original.exe
:: Configurazione per MainCodeTrial
set MAIN_LIMIT=2000
:: =====================================================================

echo Ricorda di disattivare il risparmio energetico -w-
:: 2. SCELTA MODALITÀ
set /p MODE="Vuoi eseguire la modalita completa? (y/n): "

:: 3. COMPILAZIONE
echo Avvio compilazione tramite newcompile.bat...
call newcompiler.bat
echo Compilazione terminata.

:: 4. LOGICA DI ESECUZIONE
echo Inizio della sessione di benchmark...
for %%E in (%EXECUTABLES%) do (
    if not exist "%%E" (
        echo [ATTENZIONE] %%E non trovato. Salto...
    ) else (
        set "BASE_NAME=%%~nE"
        
        if /I "%MODE%"=="y" (
            set "OUTPUT_CSV=!BASE_NAME!Full.csv"
            echo thread;rep;throughput;target_string;file_size > "!OUTPUT_CSV!"
            
            for %%S in (%STRINGS%) do (
                for %%Z in (%SIZES%) do (
                    :: Controllo limite per MainCodeTrial
                    set "SKIP=n"
                    if /I "%%E"=="MainCodeTrial.exe" if %%Z GTR %MAIN_LIMIT% set "SKIP=y"
                    
                    if "!SKIP!"=="n" (
                        echo.
                        echo Esecuzione: %%E ^| Stringa base: %%S ^| Taglia file: %%Z MB
                        echo -------------------------------------------------
                        for /L %%T in (%MIN_THREADS%, 1, %MAX_THREADS%) do (
                            for /L %%R in (1, 1, %NUM_REP%) do (
                                :: AGGIUNTA: Stampa del progresso in tempo reale
                                echo   -^> Progresso: Thread %%T ^| Ripetizione %%R di %NUM_REP% ^| Stringa "%%S" ^| Dim. %%Z MB
                                
                                for /f "delims=" %%A in ('%%E %%S %%T %%Z') do set "RESULT=%%A"
                                echo %%T;%%R;!RESULT!;%%S;%%Z >> "!OUTPUT_CSV!"
                            )
                        )
                    ) else (
                        echo.
                        echo [SKIP] %%E non supporta la taglia %%Z MB.
                    )
                )
            )
        ) else (
            set "OUTPUT_CSV=!BASE_NAME!.csv"
            echo thread;rep;throughput;target_string > "!OUTPUT_CSV!"
            
            for %%S in (%STRINGS%) do (
                echo.
                echo Esecuzione: %%E ^| Stringa base: %%S
                echo -------------------------------------------------
                for /L %%T in (%MIN_THREADS%, 1, %MAX_THREADS%) do (
                    for /L %%R in (1, 1, %NUM_REP%) do (
                        :: AGGIUNTA: Stampa del progresso in tempo reale (senza dimensione)
                        echo   -^> Progresso: Thread %%T ^| Ripetizione %%R di %NUM_REP% ^| Stringa "%%S"
                        
                        :: Se è MainCodeTrial passo il limite di 2000, altrimenti nulla
                        if /I "%%E"=="MainCodeTrial.exe" (
                            for /f "delims=" %%A in ('%%E %%S %%T %MAIN_LIMIT%') do set "RESULT=%%A"
                        ) else (
                            for /f "delims=" %%A in ('%%E %%S %%T') do set "RESULT=%%A"
                        )
                        echo %%T;%%R;!RESULT!;%%S >> "!OUTPUT_CSV!"
                    )
                )
            )
        )
    )
)

echo Benchmark completato.

echo Fine.
endlocal