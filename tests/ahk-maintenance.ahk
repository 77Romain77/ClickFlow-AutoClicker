#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include ..\src\ClickFlow-Maintenance.ahk

; Tests both uninstall modes on fake folders under %TEMP%. Never touches real
; user data, and never sends mouse or keyboard input.
parent := A_Temp "\ClickFlow-Uninstall-Test-" A_TickCount
localApp := parent "\Local\ClickFlow"
roaming := parent "\Roaming\ClickFlow"
desktop := parent "\Desktop"
start := parent "\Start"
outside := parent "\outside.ahk"
p := {local:localApp, roaming:roaming, desktop:desktop, start:start}

SetUp() {
    global p, outside
    DirCreate(p.local "\Runtime-1.0.2")
    DirCreate(p.local "\WebView2")
    DirCreate(p.local "\WebView2Preview")
    DirCreate(p.roaming)
    DirCreate(p.desktop)
    DirCreate(p.start)
    FileAppend("active", p.local "\Runtime-1.0.2\.extracted-ok", "UTF-8")
    FileAppend("cache", p.local "\WebView2\cache.txt", "UTF-8")
    FileAppend("cache", p.local "\WebView2Preview\cache.txt", "UTF-8")
    FileAppend("; script", p.local "\ClickFlow.ahk", "UTF-8")
    FileAppend("icon", p.local "\ClickFlow.ico", "UTF-8")
    FileAppend("[Shortcuts]", p.local "\shortcuts.ini", "UTF-8")
    FileAppend("[Profiles]" Chr(10) "Count=2", p.roaming "\settings.ini", "UTF-8")
    FileAppend("backup", p.roaming "\settings.ini.backup-webview2", "UTF-8")
    if !FileExist(outside)
        FileAppend("untouched downloaded file", outside, "UTF-8")
    FileCreateShortcut(A_AhkPath, p.desktop "\ClickFlow - AutoCliker.lnk",
        p.local, '"' p.local '\ClickFlow.ahk"', "ClickFlow", p.local "\ClickFlow.ico")
    FileCreateShortcut(A_AhkPath, p.start "\ClickFlow.lnk",
        p.local, '"' p.local '\ClickFlow.ahk"', "ClickFlow", p.local "\ClickFlow.ico")
}

try {
    DirCreate(parent)
    SetUp()
    CFMaintenanceCleanup("keep", p)
    if FileExist(p.local "\ClickFlow.ahk") || DirExist(p.local "\Runtime-1.0.2")
        throw Error("Keep mode failed to remove the program/runtime.")
    if DirExist(p.local "\WebView2") || DirExist(p.local "\WebView2Preview")
        throw Error("Keep mode failed to remove browser caches.")
    if FileExist(p.desktop "\ClickFlow - AutoCliker.lnk") || FileExist(p.start "\ClickFlow.lnk")
        throw Error("Keep mode failed to remove installed shortcuts.")
    if !FileExist(p.roaming "\settings.ini") || !FileExist(p.roaming "\settings.ini.backup-webview2")
        throw Error("Keep mode damaged saved profiles or backups.")
    if !FileExist(outside)
        throw Error("Keep mode removed the downloaded file.")

    SetUp()
    CFMaintenanceCleanup("all", p)
    if DirExist(p.roaming)
        throw Error("Full mode did not remove personal data.")
    if FileExist(p.local "\ClickFlow.ahk") || DirExist(p.local "\Runtime-1.0.2")
        throw Error("Full mode did not remove the program.")
    if !FileExist(outside)
        throw Error("Full mode removed an unrelated download.")

    wrong := {local:parent "\Local", roaming:parent "\Roaming\ClickFlow",
        desktop:desktop, start:start}
    rejected := false
    try CFMaintenanceCleanup("all", wrong)
    catch
        rejected := true
    if !rejected
        throw Error("Unsafe folder passed root validation.")
    if !FileExist(outside)
        throw Error("Safety guard removed unrelated files.")

    FileAppend("Keep-data, full-uninstall and safety checks passed.", "*", "UTF-8")
    try DirDelete(parent, true)
    ExitApp(0)
} catch as err {
    FileAppend("UNINSTALL TEST FAILED: " err.Message, "*", "UTF-8")
    ExitApp(1)
}
