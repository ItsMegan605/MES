@echo off
setlocal enabledelayedexpansion

set MIN_THREADS=1
set MAX_THREADS=16
set NUM_REP=10
set STRINGS=------------ unevenstring abracadabra
set SIZES= 500 1000 2000
set EXECUTABLES=MainCodeTrial.exe OptimizedCodeTrial.exe UltraOptimizedCodeTrial.exe UltraOptimizedCodeTrialO3.exe

::  per MainCodeTrial
set MAIN_LIMIT=2000
:: =====================================================================

echo Ricorda di disattivare il risparmio energetico -w-

set /p MODE="Vuoi eseguire la modalita completa? (y/n): "

echo Avvio compilazione tramite newcompile.bat...
call newcompiler.bat
echo Compilazione terminata.

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
                        
                        echo   -^> Progresso: Thread %%T ^| Ripetizione %%R di %NUM_REP% ^| Stringa "%%S"
                        
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