; Use from: [Settings > Apps > Default apps](`ms-settings:defaultapps`)
; Setup / prerequisites:
; * update CLICK0 according to window layout, scale (use AHK's built in Window Spy)
; * set ASSOC_PATH
; * set ASSOC_ITEM
; * load this ahk script
; Trigger with: Alt + A
;
; Tested on: Windows 11 25H2 (build 26200.6899)

#Requires AutoHotkey v2.0
#SingleInstance Force

; Win + Shift + R: reload script -- enable if needed
;#+R:: Reload()

;#HotIf WinActive("ahk_exe ApplicationFrameHost.exe")
#HotIf WinActive("ahk_class ApplicationFrameWindow")
!A::assocAll()
#HotIf

; client coordinates - points to label: "Set a default for a file type or link type"
CLICK0 := [500, 150]

; pairs of: file type (.extention), app path
ASSOC_PATH := [
    ;[".jpeg", "c:\prg\irfanview\i_view64.exe"],
    ;[".jpg",  "c:\prg\irfanview\i_view64.exe"],
]

; pairs of: file (.extention) / link type, sugested item index (assign to Nth suggested app in the list)
ASSOC_ITEM := [
    ;[".htm",   1],
    ;[".html",  1],
    ;["http",   1],
    ;["https",  1],  ; automatically changes with 'http' ?
]

D_SHT := 100
D_LNG := 500
MSG_CONTINUE := "`n(Continuing automatically in 3s.)"
MSG_OPT := "1 T3"


assocAll() {
    global hwndSettings
    hwndSettings := WinActive()
    res := "OK"
    for (a in ASSOC_PATH) {
        if (!isContinue(res)) {
            break
        }
        res := assocPath(a[1], a[2])
    }
    for (a in ASSOC_ITEM) {
        if (!isContinue(res)) {
            break
        }
        res := assocItem(a[1], a[2])
    }
    if (!isContinue(res)) {
        MsgBox("Script cancelled.", "Info")
    }
}

assocPath(type, appPath) {
    res := selectType(type)
    if (isContinue(res)) {
        ;res := MsgBox("Assigning '" . type . "' to app: '" . appPath . "'..." . MSG_CONTINUE, "Info", MSG_OPT)
    }
    if (isContinue(res)) {
        dialogSelectDefaultAppOpen()
        itemChooseAppOnPC()
        dialogChooseAppOnPC(appPath)
        dialogSelectDefaultAppClose()
        Sleep(D_LNG)
    }
    return res
}

assocItem(type, idx) {
    res := selectType(type)
    if (isContinue(res)) {
        ;res := MsgBox("Assigning '" . type . "' to list item[" . idx . "]..." . MSG_CONTINUE, "Info", MSG_OPT)
    }
    if (isContinue(res)) {
        dialogSelectDefaultAppOpen()
        selectAppItem(idx)
        res := dialogSelectDefaultAppClose()
        Sleep(D_LNG)
    }
    return res
}

selectInputType() {
    Send("{Click " . CLICK0[1] . " " . CLICK0[2] . "}")
    Sleep(D_SHT)
}

selectType(type) {
    global hwndSettings
    if (hwndSettings = WinActive()) {
        selectInputType()
        Send("^A")  ; select existing text
        Sleep(D_SHT)
        SendText(type)
        Sleep(D_SHT)
        Send("{Enter}")  ; select first item from popup list
        Sleep(D_LNG)
        Send("{Tab}")  ; move to selected type
        Sleep(D_SHT)
        return "OK"
    } else {  ; another window has been activated
        return "Cancel"
    }
}

; open "Select a default app for ..." dialog
dialogSelectDefaultAppOpen() {
    Send("{Enter}")
    Sleep(D_LNG)
}

dialogSelectDefaultAppClose() {
    Send("{Enter}")  ; select item and move to "Set default" button
    Sleep(D_LNG)
    Send("{Enter}")  ; set default
    return "OK"
}

; select list item: "Choose an app on your PC"
itemChooseAppOnPC() {
    Send("+{Tab}")
    Sleep(D_SHT)
}

dialogChooseAppOnPC(appPath) {
    Send("{Enter}")  ; open dialog
    Sleep(D_LNG)
    SendText(appPath)
    Sleep(D_LNG)
    Send("{Enter}")  ; close dialog
    Sleep(D_LNG)
}

selectAppItem(idx) {
    Send("{Tab}")  ; go to list
    if (idx > 0) {
        Sleep(D_SHT)
        Send("{Down}")  ; select list item: "Suggested apps"
        Loop idx {
            Sleep(D_SHT)
            Send("{Down}")  ; select next list item
        }
    }
    Sleep(D_LNG)
}

isContinue(res) {
    return res = "OK" || res = "Timeout"
}
