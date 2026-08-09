@echo off
setlocal EnableExtensions
REM Start Transformierende Rettungsmechs on Windows without a preinstalled Godot editor.
REM Preference: exported build → GODOT env → portable download into .tools\

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

set "EXPORT_EXE=%ROOT%\build\windows\TransformierendeRettungsmechs.exe"
if exist "%EXPORT_EXE%" (
  echo Starte exportiertes Spiel...
  "%EXPORT_EXE%" %*
  exit /b %ERRORLEVEL%
)

if defined GODOT if exist "%GODOT%" (
  echo Starte mit GODOT=%GODOT%
  "%GODOT%" --path "%ROOT%" %*
  exit /b %ERRORLEVEL%
)

where godot >nul 2>&1
if %ERRORLEVEL%==0 (
  echo Starte mit System-Godot...
  godot --path "%ROOT%" %*
  exit /b %ERRORLEVEL%
)

set "GODOT_VERSION=4.4.1"
set "GODOT_TAG=4.4.1-stable"
set "TOOLS=%ROOT%\.tools"
set "GODOT_EXE=%TOOLS%\Godot_v%GODOT_VERSION%-stable_win64.exe"
set "ZIP=%TOOLS%\godot-win64.zip"
set "URL=https://github.com/godotengine/godot/releases/download/%GODOT_TAG%/Godot_v%GODOT_VERSION%-stable_win64.exe.zip"

if not exist "%GODOT_EXE%" (
  echo Lade portables Godot %GODOT_VERSION% ^(einmalig nach .tools\^)...
  if not exist "%TOOLS%" mkdir "%TOOLS%"
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Invoke-WebRequest -Uri '%URL%' -OutFile '%ZIP%'"
  if errorlevel 1 (
    echo Download fehlgeschlagen. Bitte Internetpruefen oder Godot installieren.
    exit /b 1
  )
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Expand-Archive -Path '%ZIP%' -DestinationPath '%TOOLS%' -Force"
  del /f /q "%ZIP%" >nul 2>&1
)

if not exist "%GODOT_EXE%" (
  echo Godot-Binary nicht gefunden unter "%GODOT_EXE%"
  exit /b 1
)

echo Starte mit portablem Godot...
"%GODOT_EXE%" --path "%ROOT%" %*
exit /b %ERRORLEVEL%
