@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Start Transformierende Rettungsmechs on Windows without a preinstalled Godot editor.
REM Preference: fresh exported build → GODOT env → portable download into .tools\
REM Stale exports (older than project/art) are skipped so current sprites stay visible.

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

set "EXPORT_EXE=%ROOT%\build\windows\TransformierendeRettungsmechs.exe"
set "USE_EXPORT=0"

if exist "%EXPORT_EXE%" (
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$exe='%EXPORT_EXE%'; $root='%ROOT%'; $et=(Get-Item -LiteralPath $exe).LastWriteTimeUtc; $pt=(Get-Item -LiteralPath (Join-Path $root 'project.godot')).LastWriteTimeUtc; $artDir=Join-Path $root 'assets\art'; $at=$pt; if (Test-Path -LiteralPath $artDir) { $latest=Get-ChildItem -LiteralPath $artDir -File -Recurse -ErrorAction SilentlyContinue | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1; if ($null -ne $latest) { $at=$latest.LastWriteTimeUtc } }; if ($pt -gt $et -or $at -gt $et) { exit 1 } else { exit 0 }"
  if !ERRORLEVEL! EQU 0 (
    set "USE_EXPORT=1"
  ) else (
    echo Hinweis: Export unter build\windows\ ist aelter als Projekt/Art — starte Projektmodus ^(aktuelle Sprites^).
    echo          Neu bauen: Godot Export-Preset Windows, Ziel build\windows\
  )
)

if "%USE_EXPORT%"=="1" (
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
    echo Download fehlgeschlagen. Bitte Internet pruefen oder Godot installieren.
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
