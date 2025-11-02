; Use from: [Settings > Apps > Default apps](`ms-settings:defaultapps`)
; Setup / prerequisites:
; * update CLICK0 according to window layout, scale (use AHK's built in Window Spy)
; * set ASSOC_PATH
; * set ASSOC_ITEM
; * set ASSOC_DRY_RUN for testing
; * load this script into AHK
; Trigger with: Alt + A
; See FILE_LOG for logs.
;
; Tested on: Windows 11 25H2 (build 26200.6899)

#Requires AutoHotkey v2.0
#SingleInstance Force

; Win + Shift + R: reload script -- enable if needed
;#+R:: Reload()

#HotIf WinActive("ahk_class ApplicationFrameWindow")
!A::assocAll()
#HotIf

ASSOC_DEBUG   := true
ASSOC_DRY_RUN := false
FILE_LOG      := EnvGet("tmp") . "\assoc.log"

; Settings > Default Apps window / any point in label: "Set a default for a file type or link type" in client coordinates
ASSOC_CLICK0 := [500, 150]  ; 125% window scale
;ASSOC_CLICK0 := [400, 120]  ; 100% window scale

TITLE := "assoc.ahk"
; pairs of: file type (.extention), app path
ASSOC_PATH := [
    ;[".avi",  "c:\prg\mpv\mpv.exe"],
    ;[".flac", "c:\prg\mpv\mpv.exe"],
    ;[".flv",  "c:\prg\mpv\mpv.exe"],
    ;[".m4a",  "c:\prg\mpv\mpv.exe"],
    ;[".mka",  "c:\prg\mpv\mpv.exe"],
    ;[".mkv",  "c:\prg\mpv\mpv.exe"],
    ;[".mp2",  "c:\prg\mpv\mpv.exe"],
    ;[".mp3",  "c:\prg\mpv\mpv.exe"],
    ;[".mp4",  "c:\prg\mpv\mpv.exe"],
    ;[".mpeg", "c:\prg\mpv\mpv.exe"],
    ;[".mpg",  "c:\prg\mpv\mpv.exe"],
    ;[".ogg",  "c:\prg\mpv\mpv.exe"],
    ;[".opus", "c:\prg\mpv\mpv.exe"],
    ;[".jpeg", "c:\prg\irfanview\i_view64.exe"],
    ;[".jpg",  "c:\prg\irfanview\i_view64.exe"],
    ;[".gif",  "c:\prg\irfanview\i_view64.exe"],
    ;[".png",  "c:\prg\irfanview\i_view64.exe"],
    ;[".tif",  "c:\prg\irfanview\i_view64.exe"],
    ;[".pdf",  "c:\prg\pdf\SumatraPDF.exe"],
    ;[".json", "c:\prg\vscode\Code.exe"],
]

; pairs of: file (.extention) / link type, sugested item index (assign to Nth suggested app in the list)
ASSOC_ITEM := [
    ;[".htm",   1],
    ;[".html",  1],
    ;[".mhtml", 1],
    ;[".svg",   1],
    ;[".xht",   1],
    ;[".xhtml", 1],
    ;["http",   1],  ; 'https' association is changed automatically with 'http'
]

assocAll() {
    winSettingsHwnd := WinActive("A")
    assoc1 := AssocPath(winSettingsHwnd)
    assoc2 := AssocItem(winSettingsHwnd)
    assoc1.beep()
    assoc1.log(TITLE . " started (hwnd=" . winSettingsHwnd . ")")
    res := assoc1.run() && assoc2.run()
    if (ASSOC_DEBUG) {
        s := TITLE . (res ? " done" : " cancelled")
        assoc1.log(s . "`n")
        assoc1.beep()
        MsgBox(s, TITLE)
    }
}

class AssocBase {
    static D_SHT_MS := 200
    static D_LNG_MS := 500
    static D_CONT_S := 1
    static MSG_CONTINUE := "`n(Continuing automatically in " . AssocBase.D_CONT_S . "s.)"
    static MSG_OPT      := "1 T" . AssocBase.D_CONT_S

    isDebug  := ASSOC_DEBUG
    isDryRun := ASSOC_DRY_RUN
    res      := "OK"

    __New(winSettingsHwnd, assocList) {
        this.winSettingsHwnd := winSettingsHwnd
        this.assocList := assocList
    }

    run() {
        for (item in this.assocList) {
            if (this.isContinue()) {
                this.assoc(item)
            }
        }
        return this.isContinue()
    }

    assoc(item) {
        this.log(this.getAssocMsg(item))
        this.selectType(item[1])
        if (this.isDebug && this.isContinue()) {
            this.res := MsgBox(this.getAssocMsg(item) . AssocBase.MSG_CONTINUE, TITLE, AssocBase.MSG_OPT)
            Sleep(AssocBase.D_LNG_MS)
        }
        if (this.isContinue()) {
            hwnd := this.dialogSelectDefaultAppOpen()
            if (this.isContinue()) {
                this.assocSelect(item)
                this.dialogSelectDefaultAppClose(hwnd)
            }
        }
    }

    assocSelect(item) {  ; "abstract" placeholder
    }

    selectType(type) {
        if (this.isContinue() && this.isWinActive()) {
            this.selectInputType()
            this.sendSleep("^A",      AssocBase.D_LNG_MS)  ; select existing text
            this.sendSleep(type)
            this.sendSleep("{Enter}", AssocBase.D_LNG_MS)  ; select first item from popup list
            this.sendSleep("{Tab}",   AssocBase.D_LNG_MS)  ; move to selected type
        }
    }

    selectInputType() {
        this.sendSleep("{Click " . ASSOC_CLICK0[1] . " " . ASSOC_CLICK0[2] . "}")
    }

    ; open "Select a default app for ..." dialog
    ; return: new dialog hwnd
    dialogSelectDefaultAppOpen() {
        this.sendSleep("{Enter}", AssocBase.D_LNG_MS)
        hwnd := WinActive("A")
        this.log("Open  'Select a default app for ...' dialog (hwnd=" . hwnd . ")")
        return this.isWinInActive() ? hwnd : 0
    }

    dialogSelectDefaultAppClose(hwnd) {
        if (this.isContinue() && this.isWinActive(hwnd)) {
            this.log("Close 'Select a default app for ...' dialog (hwnd=" . hwnd . ")")
            if (this.isDryRun && this.isDebug) {
                Sleep(AssocBase.D_CONT_S * 1000)
            }
            this.sendSleep("{Enter}", AssocBase.D_LNG_MS)  ; select item and move to "Set default" button
            this.sendSleep(this.isDryRun ? "{Escape}" : "{Enter}", AssocBase.D_LNG_MS)  ; set default
        }
    }

    sendSleep(keys, d := AssocBase.D_SHT_MS) {
        SendInput(keys)
        Sleep(d)
    }

    isWinActive(hwnd := 0) {
        return this.isWinActive0(1, "Dialog window deactivated: ", hwnd)
    }

    isWinInActive(hwnd := 0) {
        return this.isWinActive0(0, "New dialog window not opened.", hwnd)
    }

    ; param isActive: boolean: check for active or inactive window
    isWinActive0(isActive, msg, hwnd := 0) {
        hwnd  := hwnd != 0 ? hwnd : this.winSettingsHwnd
        hwnda := WinActive("A")
        res := (hwnd = hwnda) = isActive  ; window is active / inactive as expected
        if (!res) {
            this.log("ERROR: " . msg . (isActive ? hwnd . " != " . hwnda : ""))
            this.stop()
        }
        return res
    }

    isContinue() {
        return this.res = "OK" || this.res = "Timeout"
    }

    stop() {
        this.log("Stopping")
        this.res := "Cancel"
        this.beep()
    }

    log(s) {
        FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") . " " . s . "`n", FILE_LOG)
    }

    beep() {
        SoundPlay(A_WinDir . "\Media\Windows Default.wav")
    }
}

class AssocPath extends AssocBase {
    __New(winSettingsHwnd) {
        super.__New(winSettingsHwnd, ASSOC_PATH)
    }

    getAssocMsg(item) {
        return "Assign '" . item[1] . "' to app: '" . item[2] . "'"
    }

    assocSelect(item) {
        this.itemChooseAppOnPC()
        this.dialogChooseAppOnPC(item[2])
    }

    ; select list item: "Choose an app on your PC"
    itemChooseAppOnPC() {
        this.sendSleep("+{Tab}")
    }

    dialogChooseAppOnPC(appPath) {
        this.sendSleep("{Enter}", AssocBase.D_LNG_MS)  ; open dialog
        this.sendSleep(appPath,   AssocBase.D_LNG_MS)  ; select app
        this.sendSleep("{Enter}", AssocBase.D_LNG_MS)  ; close dialog
        ;this.sendSleep(appPath . "{Enter}", AssocBase.D_LNG_MS)  ; close dialog
    }
}

class AssocItem extends AssocBase {
    __New(winSettingsHwnd) {
        super.__New(winSettingsHwnd, ASSOC_ITEM)
    }

    getAssocMsg(item) {
        return "Assign '" . item[1] . "' to list item[" . item[2] . "]"
    }

    assocSelect(item) {
        this.selectAppItem(item[2])
    }

    selectAppItem(idx) {
        if (idx > 0) {
            this.SendSleep("{Tab}")  ; go to list
            Loop idx + 1 {  ; select list item: "Suggested apps" + idx
                this.SendSleep("{Down}")
            }
        }
    }
}
