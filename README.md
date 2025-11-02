# win-fix

Helper instructions and scripts to make windows somewhat usable.

General instructions:

* Run as **admin**. -- Almost all commands / scripts required administrator access rights.

## Associations / Default apps

* Settings > Apps > Default apps -- `ms-settings:defaultapps`
* old commands: `assoc`, `ftype` -- does NOT work in win 10+
* **Add portable apps** e.g.

    ```bat
    reg add "HKCR\Applications\mpv.exe\shell\open\command"        /t REG_SZ /d "\"c:\prg\mpv\mpv.exe\" \"%1\"" /f
    reg add "HKCR\Applications\SumatraPDF.exe\shell\open\command" /t REG_SZ /d "\"c:\prg\pdf\SumatraPDF.exe\" \"%1\"" /f
    ```

* **DISM** -- worked for me only partially
    * steps
        1. export: `dism /online /Export-DefaultAppAssociations:assoc.xml`
            * Win11 25H2 export: [assoc-win11-orig.xml](scripts\assoc-win11-orig.xml)
        2. update xml -- **Important**: do not remove any of the entries existing
            * association `ProgId` = file class, Progid defined by app, or `Applications\program.exe` registered under reg key: `HKCR\Applications`
            * sample: [assoc.xml](scripts\assoc.xml)
        3. import: `dism /online /Import-DefaultAppAssociations:assoc.xml`
            * saves to: `c:\Windows\System32\OEMDefaultAssociations.xml`
        4. (remove: `dism /online /Remove-DefaultAppAssociations`)
        5. ? Settings > Apps > Default apps / Reset all default apps
        6. ? restart
    * https://thewindowsclub.com/reset-export-import-default-app-associations
    * https://tenforums.com/tutorials/8703-restore-default-file-type-associations-windows-10-a.html
    * https://tenforums.com/tutorials/8744-export-import-default-app-associations-new-users-windows.html
* [SetUserFTA](https://setuserfta.com/)
* [PS-SFTA (PowerShell SFTA)](https://github.com/DanysysTeam/PS-SFTA)
    * [ninjaOne's extended PS-SFTA](https://ninjaone.com/script-hub/set-default-filetype-associations-powershell/)
* **AHK v2 script** - simulate UI actions (instructions inside): [assoc.ahk](scripts\assoc.ahk)
    * [Settings > Apps > Default apps / "Set a default for a file type or link type" (label)](scripts\assoc--settings-apps-default_apps.png)
* registry - did not work: even after stopping **UserChoice Protection Driver (UCPD Driver)** reg. changes were reverted back on any association based file open operation (e.g. opening a video)
    * https://kolbi.cz/blog/2024/04/03/userchoice-protection-driver-ucpd-sys/

## Windows Defender

* Even if there is another antivirus installed, if it is not set to start automatically windows will try to start Defender basically interfering with the other antivirus.
* https://lazyadmin.nl/win-11/turn-off-windows-defender-windows-11-permanently/
* **Important**: major windows updates, `sfc /scannow` (etc. ?) will fail if it cannot read Windows defender folders
    1. reset Defender folder access (`sudo defender-folders.bat 1`)
    2. run `sfc /scannow`
    3. disable Defender folder access (`sudo defender-folders.bat`)

* disable Defender services - **safe mode** (`sc config` still does not work)

    | Name      | Display name                                        | Path                                                                            | Start  | int |
    | --------- | --------------------------------------------------- | ------------------------------------------------------------------------------- | ------ | --: |
    | WdBoot    | MS Defender Avir Boot Driver                        | \SystemRoot\system32\drivers\wd\WdBoot.sys                                      | boot   |   0 |
    | WdFilter  | MS Defender Avir Mini-Filter Driver                 | \SystemRoot\system32\drivers\wd\WdFilter.sys                                    | boot   |   0 |
    | WdNisDrv  | MS Defender Avir Network Inspection System Driver   | system32\drivers\wd\WdNisDrv.sys                                                | manual |   3 |
    | WdNisSvc  | MS Defender Avir Network Inspection Service         | "C:\ProgramData\Microsoft\Windows Defender\Platform\4.18.25080.5-0\NisSrv.exe"  | manual |   3 |
    | WinDefend | MS Defender Avir Service                            | "C:\ProgramData\Microsoft\Windows Defender\Platform\4.18.25080.5-0\MsMpEng.exe" | auto   |   2 |
    | Sense     | Windows Defender Advanced Threat Protection Service | "C:\Program Files\Windows Defender Advanced Threat Protection\MsSense.exe"      | manual |   3 |

```bat
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
```

* disable/enable **TrustedInstaller access** to defender folders
    * **safe mode** to take ownership from **TrustedInstaller**

```bat
:: safe mode - to take ownership from TrustedInstaller
:: usage: defender-folders.bat [1]
:: param: 1 = restore TrustedInstaller access, otherwise TrustedInstaller access is removed
@setlocal
@if "%~1" EQU "0" (@set ACCESS_REMOVE=0) else (@set ACCESS_REMOVE=)

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
```
