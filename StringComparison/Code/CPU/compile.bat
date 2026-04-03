@echo off
setlocal enabledelayedexpansion

:: Controlla se è stato passato almeno un argomento
if "%~1"=="" (
    echo Errore: Nessun file specificato.
    echo Utilizzo: %~nx0 ^<nome_file.cpp^> [flag opzionali...]
    echo Esempio: %~nx0 OptimizedCodeTrial.cpp -g -O3
    exit /b 1
)

:: Salva il nome del file (con estensione) e il nome base (senza estensione)
set "FILENAME=%~1"
set "BASENAME=%~n1"
set "FLAGS="

:: Ciclo per raccogliere tutti i flag aggiuntivi passati dopo il nome del file
:collect_flags
shift
if "%~1"=="" goto compile
set "FLAGS=!FLAGS! %1"
goto collect_flags

:compile
:: Costruisce la stringa di compilazione
set "COMPILE_CMD=g++!FLAGS! "%FILENAME%" -o "%BASENAME%" -I"C:\Program Files (x86)\Intel\oneAPI\vtune\latest\include" -L"C:\Program Files (x86)\Intel\oneAPI\vtune\latest\lib64" -littnotify"

echo Esecuzione del comando:
echo %COMPILE_CMD%
echo.

:: Esegue il comando
%COMPILE_CMD%

endlocal