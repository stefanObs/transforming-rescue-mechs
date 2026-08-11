@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Start Transformierende Rettungsmechs on Windows without a preinstalled Godot editor.
REM Default: project mode (--path) so CURRENT sprites/figures are visible.
REM Stale or unofficial build\windows\ exports hid characters (no Windows export preset).
REM Optional: set PLAY_USE_EXPORT=1 to launch a fresh export instead.

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
cd /d "%ROOT%"

set "EXPORT_EXE=%ROOT%\build\windows\TransformierendeRettungsmechs.exe"
set "GODOT_VERSION=4.4.1"
set "GODOT_TAG=4.4.1-stable"
set "TOOLS=%ROOT%\.tools"
set "GODOT_EXE=%TOOLS%\Godot_v%GODOT_VERSION%-stable_win64.exe"
set "ZIP=%TOOLS%\godot-win64.zip"
set "URL=https://github.com/godotengine/godot/releases/download/%GODOT_TAG%/Godot_v%GODOT_VERSION%-stable_win64.exe.zip"

if /I "%PLAY_USE_EXPORT%"=="1" if exist "%EXPORT_EXE%" (
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$exe='%EXPORT_EXE%'; $root='%ROOT%'; $et=(Get-Item -LiteralPath $exe).LastWriteTimeUtc; $latest=$et; foreach ($rel in @('project.godot','assets','scripts','scenes')) { $p=Join-Path $root $rel; if (Test-Path -LiteralPath $p) { $item=Get-Item -LiteralPath $p; if ($item.PSIsContainer) { $hit=Get-ChildItem -LiteralPath $p -File -Recurse -ErrorAction SilentlyContinue | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1; if ($null -ne $hit -and $hit.LastWriteTimeUtc -gt $latest) { $latest=$hit.LastWriteTimeUtc } } elseif ($item.LastWriteTimeUtc -gt $latest) { $latest=$item.LastWriteTimeUtc } } }; if ($latest -gt $et) { exit 1 } else { exit 0 }"
  if !ERRORLEVEL! EQU 0 (
    echo Starte exportiertes Spiel ^(PLAY_USE_EXPORT=1^)...
    "%EXPORT_EXE%" %*
    exit /b %ERRORLEVEL%
  )
  echo Hinweis: Export unter build\windows\ ist aelter als Projekt/Scripts/Art — Projektmodus.
)

set "RUN_GODOT="
if defined GODOT if exist "%GODOT%" set "RUN_GODOT=%GODOT%"
if not defined RUN_GODOT (
  where godot >nul 2>&1
  if !ERRORLEVEL! EQU 0 (
    for /f "delims=" %%G in ('where godot') do (
      if not defined RUN_GODOT set "RUN_GODOT=%%G"
    )
  )
)
if not defined RUN_GODOT (
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
  if exist "%GODOT_EXE%" set "RUN_GODOT=%GODOT_EXE%"
)

if not defined RUN_GODOT (
  echo Kein Godot gefunden. Bitte Godot 4.4.1 installieren, GODOT= setzen, oder Internet fuer den Download.
  exit /b 1
)

if not exist "%ROOT%\.godot\imported\*" (
  echo Importiere Art/Szenen ^(erster Start, noetig fuer sichtbare Figuren^)...
  "%RUN_GODOT%" --headless --path "%ROOT%" --import
  if errorlevel 1 (
    echo Hinweis: Import meldete einen Fehler — starte trotzdem.
  )
)

echo Starte Projektmodus mit aktuellen Figuren...
"%RUN_GODOT%" --path "%ROOT%" %*
exit /b %ERRORLEVEL%
