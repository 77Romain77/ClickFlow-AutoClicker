#Requires AutoHotkey v2.0
#SingleInstance Off
#ErrorStdOut "UTF-8"

; Exécuté depuis une copie temporaire par le backend, sans dépendance WebView2.
; Seul le mode et le PID sont acceptés : aucun chemin à effacer en argument.
if A_Args.Length != 2 || (A_Args[1] != "keep" && A_Args[1] != "all")
    ExitApp(2)
if !RegExMatch(A_Args[2], "^\d+$")
    ExitApp(2)
mode := A_Args[1]
parentPid := A_Args[2] + 0
localBase := EnvGet("LOCALAPPDATA")
roamingBase := EnvGet("APPDATA")
if localBase = "" || roamingBase = ""
    ExitApp(2)
installDir := localBase "\ClickFlow"
settingsDir := roamingBase "\ClickFlow"

try {
    ; Attendre que le moteur ait libéré le contrôleur et les fichiers WebView2.
    Loop 80 {
        if parentPid = 0 || !ProcessExist(parentPid)
            break
        Sleep(250)
    }
    if parentPid != 0 && ProcessExist(parentPid)
        throw Error("ClickFlow est encore en cours d'exécution.")
    CFUninstallShortcuts(installDir)
    CFUninstallRemoveFolder(installDir)
    if mode = "all"
        CFUninstallRemoveFolder(settingsDir)
} catch as err {
    if EnvGet("CLICKFLOW_UNINSTALL_CI") != "1"
        MsgBox("Désinstallation incomplète : " err.Message Chr(10)
            "Les dossiers peuvent être supprimés manuellement dans l'Explorateur.",
            "ClickFlow", "Icon!")
    ExitApp(1)
}

; Ne jamais supprimer un fichier de développement ou de test.
if RegExMatch(A_ScriptFullPath, "i)\\ClickFlow-Uninstall-[0-9A-F]{8}\.ahk$")
    try FileDelete(A_ScriptFullPath)
ExitApp(0)

CFUninstallShortcuts(installDir) {
    desktop := EnvGet("CLICKFLOW_SHORTCUT_TEST_DESKTOP")
    startMenu := EnvGet("CLICKFLOW_SHORTCUT_TEST_STARTMENU")
    if desktop = ""
        desktop := A_Desktop
    if startMenu = ""
        startMenu := A_Programs
    for folder in [desktop, startMenu] {
        for filename in ["ClickFlow - AutoCliker.lnk", "ClickFlow.lnk"] {
            linkPath := folder "\" filename
            if !FileExist(linkPath)
                continue
            try {
                link := ComObject("WScript.Shell").CreateShortcut(linkPath)
                ; Ne toucher qu'aux raccourcis qui pointent vers ClickFlow.
                if StrLower(link.TargetPath) = StrLower(A_AhkPath)
                    && InStr(StrLower(link.Arguments), StrLower(installDir "\ClickFlow.ahk"))
                    FileDelete(linkPath)
            }
        }
    }
}

CFUninstallRemoveFolder(path) {
    if !DirExist(path)
        return
    ; Protection contre une jonction racine vers un dossier tiers.
    attrs := DllCall("Kernel32\GetFileAttributesW", "Str", path, "UInt")
    if attrs = 0xFFFFFFFF || (attrs & 0x400)
        throw Error("Dossier ClickFlow lié à un autre emplacement : suppression refusée.")
    Loop 30 {
        try {
            DirDelete(path, true)
            return
        } catch as err {
            if A_Index = 30
                throw Error("Impossible de supprimer " path " : " err.Message)
            Sleep(250)
        }
    }
}
