@echo off
setlocal enabledelayedexpansion

:: percorso file
cd /d "%~dp0" 

set MIN_THREADS=1
set MAX_THREADS=12
set ITERAZIONI=5

:: =====================================================================

if "%~1"=="" (
    echo Errore: Devi fornire il nome dell'eseguibile come parametro.
    exit /b 1
)

:: Controllo che il terzo argomento sia presente
if "%~2"=="" (
    echo Errore: Devi fornire la parola target come terzo argomento.
    exit /b 1
)

:: Assegna il terzo parametro alla variabile
set "TARGET_STRING=%~2"

:: Estrae SOLO il nome del file ignorando il percorso (es. MainCodeTrial.exe)
set "ESEGUIBILE_NOME=%~nx1"

:: Imposta il nome del CSV basandosi sul nome dell'eseguibile e controlla "uneven"
if /I "%TARGET_STRING%"=="uneven" (
    set "OUTPUT_CSV=%~n1Uneven.csv"
) else (
    set "OUTPUT_CSV=%~n1.csv"
)

if not exist "!ESEGUIBILE_NOME!" (
    echo Errore: L'eseguibile "!ESEGUIBILE_NOME!" non e' stato trovato in questa cartella.
    exit /b 1
)

if not exist "gigante.txt" (
    echo [ATTENZIONE] Il file "gigante.txt" non e' presente nella directory. 
    echo.
)

:: MODIFICA 1: Uso del punto e virgola (;) e rinominato in "durata"
echo thread;iterazione;durata > "%OUTPUT_CSV%"

echo Inizio del benchmark...
echo I risultati verranno salvati in: %OUTPUT_CSV%
echo Eseguibile rilevato: !ESEGUIBILE_NOME!
echo Parola di test: %TARGET_STRING%
echo.

for /L %%T in (%MIN_THREADS%, 1, %MAX_THREADS%) do (
    echo Esecuzione test con %%T thread...
    
    for /L %%I in (1, 1, %ITERAZIONI%) do (
        
        :: Esecuzione pulita: essendo nella stessa cartella, basta chiamare il nome del file
        for /f "delims=" %%R in ('!ESEGUIBILE_NOME! %TARGET_STRING% %%T') do (
            set THROUGHPUT=%%R
        )
        echo Iterazione %%I: Throughput = !THROUGHPUT! ms
        
        :: MODIFICA 2: Sostituite le virgole con il punto e virgola (;)
        echo %%T;%%I;!THROUGHPUT! >> "%OUTPUT_CSV%"
    )
)

echo.
echo Benchmark completato con successo!
endlocal