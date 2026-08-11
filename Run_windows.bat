@echo off
REM Same starter as play-windows.bat (project mode by default so current figures show).
call "%~dp0play-windows.bat" %*
exit /b %ERRORLEVEL%
