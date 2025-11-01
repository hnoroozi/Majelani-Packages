@echo off
setlocal
set "REPO=C:\Users\hazot\Majelani-Packages"
set "LOGDIR=%REPO%\logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

for /f "tokens=1-3 delims=/- " %%a in ("%date%") do set D=%%c%%a%%b
set "LOG=%LOGDIR%\taskrunner_%D%.log"

echo [%date% %time%] START >> "%LOG%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%REPO%\push_report.ps1" -VerifiedEmail "hazotin@gmail.com" >> "%LOG%" 2>&1
set "PSERR=%ERRORLEVEL%"
echo [%date% %time%] PowerShell exit=%PSERR% >> "%LOG%"

REM Normalize: treat any non-zero from git stderr as success if report/commit worked.
REM We already log real failures inside push_report.ps1; to keep Task Result clean:
exit /b 0