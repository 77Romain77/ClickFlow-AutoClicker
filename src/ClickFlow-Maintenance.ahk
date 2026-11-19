; ClickFlow - AutoCliker: maintenance / uninstall support (AutoHotkey v2).
; Every deletion is restricted to owned ClickFlow directories, links and files.

CFMaintenancePaths() {
    localRoot := EnvGet("LOCALAPPDATA") "\ClickFlow"
    roamingRoot := EnvGet("APPDATA") "\ClickFlow"
    desktop := EnvGet("CLICKFLOW_SHORTCUT_TEST_DESKTOP")
    start := EnvGet("CLICKFLOW_SHORTCUT_TEST_STARTMENU")
    if desktop = ""
        desktop := A_Desktop
    if start = ""
        start := A_Programs
    return {local: localRoot, roaming: roamingRoot, desktop: desktop, start: start}
}

CFMaintenanceValidatePaths(p) {
    ; Both roots must refer to a directory literally called ClickFlow, not an
    ; arbitrary path supplied via an argument or a reparse point.
    if !RegExMatch(p.local, "i)\\ClickFlow$") || !RegExMatch(p.roaming, "i)\\ClickFlow$")
        throw Error("Le chemin de désinstallation ne correspond pas à ClickFlow.")
    if StrLower(p.local) = StrLower(p.roaming)
        throw Error("Les dossiers locaux et personnels ne doivent pas être identiques.")
    for folder in [p.local, p.roaming] {
        if CFDirIsReparse(folder)
            throw Error("Le dossier ClickFlow est un lien symbolique : suppression refusée.")
    }
}

CFDirIsReparse(dir) {
    if !DirExist(dir)
        return false
    attrs := DllCall("Kernel32\GetFileAttributesW", "WStr", dir, "UInt")
    return attrs != 0xFFFFFFFF && (attrs & 0x400) != 0
}

CFDeleteDirectorySafe(dir) {
    if !DirExist(dir)
        return
    if CFDirIsReparse(dir)
        throw Error("Lien symbolique détecté, dossier non supprimé : " dir)
    ; Refuse following links or junctions anywhere in a recursively deleted tree.
    Loop Files dir "\*", "FDR" {
        attrs := DllCall("Kernel32\GetFileAttributesW", "WStr", A_LoopFileFullPath, "UInt")
        if attrs != 0xFFFFFFFF && (attrs & 0x400)
            throw Error("Un lien symbolique a été détecté dans : " dir)
    }
    Loop 4 {
        try {
            DirDelete(dir, true)
            return
        } catch as err {
            if A_Index = 4
                throw err
            Sleep(500)
        }
    }
}

CFShortcutOwned(file, scriptFile) {
    if !FileExist(file)
        return false
    try {
        link := ComObject("WScript.Shell").CreateShortcut(file)
        ; Only remove shortcuts to the stable local script, no third-party links.
        return StrLower(Trim(link.Arguments, ' "')) = StrLower(scriptFile)
    }
    return false
}

CFRemoveInstalledShortcuts(p) {
    localScript := p.local "\ClickFlow.ahk"
    for folder in [p.desktop, p.start] {
        for name in ["ClickFlow - AutoCliker.lnk", "ClickFlow.lnk"] {
            shortcut := folder "\" name
            if CFShortcutOwned(shortcut, localScript)
                FileDelete(shortcut)
        }
    }
}

CFMaintenanceCleanup(mode, p) {
    if mode != "keep" && mode != "all"
        throw Error("Mode de désinstallation invalide.")
    CFMaintenanceValidatePaths(p)

    ; The launcher copied from Downloads is not touched. Only the stable copy,
    ; versioned runtimes, icon, shortcut preferences and browser caches are owned.
    CFRemoveInstalledShortcuts(p)
    if DirExist(p.local) {
        Loop Files p.local "\Runtime-*", "D" {
            folder := A_LoopFileFullPath
            if RegExMatch(A_LoopFileName, "^Runtime-\d+\.\d+\.\d+$")
                CFDeleteDirectorySafe(folder)
        }
        for name in ["WebView2", "WebView2Preview"]
            CFDeleteDirectorySafe(p.local "\" name)
        for name in ["ClickFlow.ahk", "ClickFlow.ico", "shortcuts.ini"] {
            file := p.local "\" name
            if FileExist(file)
                FileDelete(file)
        }
        ; Leave unknown contents untouched instead of recursively wiping user files.
        try DirDelete(p.local)
    }

    if mode = "all" {
        ; The roaming ClickFlow directory contains profiles, settings and backups.
        CFDeleteDirectorySafe(p.roaming)
    }
}
