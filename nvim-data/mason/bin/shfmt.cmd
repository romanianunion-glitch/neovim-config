@ECHO off
GOTO start
:find_dp0
SET dp0=%~dp0
EXIT /b
:start
SETLOCAL
CALL :find_dp0

endLocal & goto #_undefined_# 2>NUL || title %COMSPEC% & "%dp0%\..\packages\shfmt\shfmt_v3.14.1_windows_amd64.exe" %*