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
