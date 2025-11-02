:: safe mode - to disable services
:: query
sc qc WdBoot
sc qc WdFilter
sc qc WdNisDrv
sc qc WdNisSvc
sc qc WinDefend
sc qc Sense

:: disable
:: TODO does not work
@REM sc config WdBoot    start= disabled
@REM sc config WdFilter  start= disabled
@REM sc config WdNisDrv  start= disabled
@REM sc config WdNisSvc  start= disabled
@REM sc config WinDefend start= disabled
@REM sc config Sense     start= disabled

reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdBoot"    /v Start /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdFilter"  /v Start /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdNisDrv"  /v Start /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdNisSvc"  /v Start /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WinDefend" /v Start /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Sense"     /v Start /t REG_DWORD /d "4" /f
