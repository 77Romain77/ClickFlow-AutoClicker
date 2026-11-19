#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include ..\src\ClickFlow-Backend.ahk

; Integration test for independently managed Windows shortcuts. No clicks sent.
try {
    dirs := CFShortcutPaths()
    DirCreate(dirs.app)
    DirCreate(dirs.desktop)
    DirCreate(dirs.start)
    if !FileExist(dirs.script)
        FileAppend("; ClickFlow test script", dirs.script, "UTF-8")
    FileCopy(A_ScriptDir "\..\src\assets\ClickFlow.ico", dirs.icon, true)

    desktopLink := dirs.desktop "\ClickFlow - AutoCliker.lnk"
    startLink := dirs.start "\ClickFlow - AutoCliker.lnk"
    oldDesktop := dirs.desktop "\ClickFlow.lnk"

    ; Clear only shortcuts owned by ClickFlow before starting.
    CFShortcutChange("desktop", "remove")
    CFShortcutChange("start", "remove")

    if CFShortcutHas("desktop") || CFShortcutHas("start")
        throw Error("Expected both locations to begin without ClickFlow shortcuts.")

    CFShortcutChange("desktop", "create")
    if !CFShortcutHas("desktop") || CFShortcutHas("start")
        throw Error("Desktop shortcut creation unexpectedly affected Start menu.")
    CFShortcutChange("start", "create")
    if !CFShortcutHas("start") || !CFShortcutHas("desktop")
        throw Error("Start menu creation failed.")

    ; User removes Desktop link manually in Explorer.
    FileDelete(desktopLink)
    if CFShortcutHas("desktop")
        throw Error("Removed desktop shortcut must not be considered installed.")
    if !CFShortcutHas("start")
        throw Error("Manual desktop removal affected Start menu.")
    ; Status reads must not recreate a manually deleted shortcut.
    CFShortcutHas("desktop")
    CFShortcutHas("start")
    if FileExist(desktopLink)
        throw Error("Status read reinstalled manually deleted desktop shortcut.")

    ; Legacy ClickFlow.lnk is recognised and can be migrated per location.
    FileCreateShortcut(A_AhkPath, oldDesktop, dirs.app,
        '"' dirs.script '"', "Legacy ClickFlow", dirs.icon)
    if !CFShortcutHas("desktop")
        throw Error("Expected recognition of legacy ClickFlow desktop shortcut.")
    CFShortcutChange("desktop", "create")
    if FileExist(oldDesktop) || !FileExist(desktopLink)
        throw Error("Legacy desktop link was not migrated.")
    CFShortcutChange("desktop", "remove")
    if CFShortcutHas("desktop") || !CFShortcutHas("start")
        throw Error("Removing Desktop shortcut affected Start menu.")

    CFShortcutChange("start", "remove")
    if CFShortcutHas("start")
        throw Error("Start menu shortcut removal failed.")

    ; Never overwrite or remove unrelated shortcuts even with the same name.
    FileCreateShortcut(A_WinDir "\System32\notepad.exe", desktopLink,
        dirs.desktop, "", "Unrelated shortcut")
    caught := false
    try CFShortcutChange("desktop", "create")
    catch
        caught := true
    if !caught
        throw Error("An unrelated shortcut was overwritten.")
    CFShortcutChange("desktop", "remove")
    if !FileExist(desktopLink)
        throw Error("An unrelated shortcut was deleted.")
    FileDelete(desktopLink)

    FileAppend("Independent shortcuts, legacy migration and manual deletion passed.", "*", "UTF-8")
    ExitApp(0)
} catch as err {
    FileAppend("SHORTCUT REGRESSION: " err.Message, "*", "UTF-8")
    ExitApp(1)
}
