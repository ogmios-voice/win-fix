:: safe mode - to take ownership from TrustedInstaller
:: usage: defender-folders.bat [1]
:: param: 1 = restore TrustedInstaller access, otherwise TrustedInstaller access is removed
@setlocal
@if "%~1" EQU "1" (@set ACCESS_REMOVE=0) else (@set ACCESS_REMOVE=)

@call :access_set "c:\ProgramData\Microsoft\Windows Defender"
@call :access_set "c:\ProgramData\Microsoft\Windows Defender Advanced Threat Protection"
@call :access_set "c:\Program Files\Windows Defender"
@call :access_set "c:\Program Files\Windows Defender Advanced Threat Protection"
@call :access_set "c:\Program Files (x86)\Windows Defender"
@goto :eof

:: param 1: folder
:access_set
@call :access_reset %1
@if "%ACCESS_REMOVE%" NEQ "0" @call :access_rm %1
@goto :eof

:: param 1: folder
:access_reset
takeown /a /r /d y /f %1 | findstr -ri "[a-z]" | findstr -v /c:"SUCCESS:"
icacls %1 /reset /t | findstr -v /c:"processed file:"
@goto :eof

:: param 1: folder
:access_rm
@REM attrib %1 +r
:: deny full control (F) with object inherit (OI) and container inherit (CI)
icacls %1 /deny SYSTEM:(OI)(CI)(F) "NT SERVICE\TrustedInstaller":(OI)(CI)(F) | findstr -v /c:"processed file:"
@goto :eof
