; ClickFlow - sauvegarde complète des profils et paramètres.
; Le ZIP est validé et extrait dans TEMP avant toute modification du stockage.

CFBackupScript() {
    script := A_ScriptDir "\ClickFlow-Backup.ps1"
    if FileExist(script)
        return script
    script := A_ScriptDir "\..\src\ClickFlow-Backup.ps1"
    if FileExist(script)
        return script
    throw Error("Composant de sauvegarde ClickFlow manquant.")
}

CFBackupWorkFolder() {
    folder := A_Temp "\ClickFlow-Backup-" A_Pid "-" A_TickCount
    Loop 12 {
        candidate := folder "-" A_Index
        if !DirExist(candidate) {
            DirCreate(candidate)
            return candidate
        }
    }
    throw Error("Impossible de créer le dossier temporaire.")
}

CFBackupPowerShell(mode, archive, work) {
    global CF
    script := CFBackupScript()
    powerShell := A_WinDir "\System32\WindowsPowerShell\v1.0\powershell.exe"
    if !FileExist(powerShell)
        throw Error("Windows PowerShell est requis pour les archives ZIP.")
    args := '"' powerShell '" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' script '" -Mode ' mode ' -Archive "' archive '" -Settings "' CF.configFile '" -Profiles "' CF.profilesDir '" -Work "' work '"'
    exitCode := RunWait(args, , "Hide")
    if exitCode != 0
        throw Error("Archive ClickFlow non valide ou accès impossible (code " exitCode ").")
}

CFBackupExport(destination := "") {
    global CF
    if destination = "" {
        destination := FileSelect("S16", A_Desktop "\ClickFlow-Sauvegarde.zip",
            "Sauvegarder tous les profils et paramètres", "Archives ZIP (*.zip)")
        if destination = ""
            return false
    }
    if !RegExMatch(destination, "i)\.zip$")
        destination .= ".zip"
    if FileExist(destination) && !FileExist(destination ".partial.zip") {
        ; Remplacement volontaire uniquement si destination fournie par l'utilisateur.
        if MsgBox("Remplacer la sauvegarde existante ?", "ClickFlow",
            "YesNo Icon?") != "Yes"
            return false
    }
    SaveSettings()
    work := CFBackupWorkFolder()
    try {
        CFBackupPowerShell("Export", destination, work)
        CFProfileMessage("Sauvegarde complète créée : " destination)
        return true
    } finally {
        try DirDelete(work, true)
    }
}

CFBackupValidateRestoredProfiles(dir) {
    global CF
    count := 0
    names := Map()
    Loop Files dir "\*", "F" {
        if !RegExMatch(A_LoopFileName, "^profile-([1-9]\d{0,8})\.ini$", &match)
            throw Error("Fichier inattendu dans la sauvegarde.")
        if FileGetSize(A_LoopFileFullPath) > 65536
            throw Error("Profil trop volumineux.")
        if IniRead(A_LoopFileFullPath, "ClickFlowProfile", "FormatVersion", "") != "1"
            throw Error("Version du profil non prise en charge.")
        name := Trim(IniRead(A_LoopFileFullPath, "ClickFlowProfile", "Name", ""))
        if name = "" || StrLen(name) > 36 || names.Has(StrLower(name))
            throw Error("Nom de profil absent, trop long ou dupliqué.")
        names[StrLower(name)] := true
        count++
    }
    if count < 1 || count > 200
        throw Error("Sauvegarde sans profil valide.")
}

CFBackupReloadState() {
    global CF
    ; Recharger depuis settings.ini et les profils restaurés, en gardant
    ; le même processus WebView2. Ne pas laisser les anciennes touches actives.
    try CFGlobalUnregister()
    try UnregisterActivation()
    try UnregisterEmergency()
    CFDesktopReleaseFloat()
    CF.loading := true
    CF.emergencyKey := IniRead(CF.configFile, "General", "EmergencyKey", "F12")
    if CF.emergencyKey = "" || CF.emergencyKey = "Escape" || CF.emergencyKey = "!"
        CF.emergencyKey := "F12"
    CF.compactMode := IniRead(CF.configFile, "General", "CompactMode", "0") = "1"
    CF.profiles := []
    LoadSettings()
    CFDesktopReadPreferences()
    CFGlobalReadKeys()
    CF.loading := false
    RegisterEmergency()
    RegisterActivation()
    CFGlobalRegister()
    CFDesktopRebuildProfiles()
    CFDesktopRestoreMainBounds()
    CFDesktopUpdate()
    SendState()
    SendStats()
}

CFBackupRestore(source := "", confirm := true) {
    global CF
    if source = "" {
        source := FileSelect(1, A_Desktop, "Restaurer une sauvegarde ClickFlow",
            "Archives ZIP (*.zip)")
        if source = ""
            return false
    }
    if confirm && MsgBox("Remplacer TOUS les profils et paramètres actuels "
        "par ceux de cette sauvegarde ? ClickFlow conservera une copie "
        "temporaire pour revenir en arrière en cas d'erreur.",
        "Restaurer ClickFlow", "YesNo Icon!") != "Yes"
        return false
    work := CFBackupWorkFolder()
    changed := false
    oldProfiles := work "\rollback-profiles"
    oldSettings := work "\rollback-settings.ini"
    freshProfiles := work "\payload\profiles"
    freshSettings := work "\payload\settings.ini"
    try {
        ; Aucune donnée courante touchée avant validation du ZIP.
        CFBackupPowerShell("Import", source, work)
        CFBackupValidateRestoredProfiles(freshProfiles)
        SaveSettings()
        StopAll("Restauration des profils : clics arrêtés.")
        if CF.capture
            FinishCapture("")
        CFGlobalUnregister()
        UnregisterActivation()
        UnregisterEmergency()
        CF.loading := true
        changed := true
        if DirExist(CF.profilesDir)
            DirMove(CF.profilesDir, oldProfiles)
        if FileExist(CF.configFile)
            FileMove(CF.configFile, oldSettings)
        DirMove(freshProfiles, CF.profilesDir)
        FileMove(freshSettings, CF.configFile)
        CFBackupReloadState()
        SaveSettings()
        CFProfileMessage("Sauvegarde restaurée : profils et paramètres rechargés.")
        return true
    } catch as err {
        if changed {
            try CFDeleteDirectorySafe(CF.profilesDir)
            try FileDelete(CF.configFile)
            if DirExist(oldProfiles)
                try DirMove(oldProfiles, CF.profilesDir)
            if FileExist(oldSettings)
                try FileMove(oldSettings, CF.configFile)
        }
        ; Rétablir les raccourcis de la session après un échec.
        CF.loading := false
        try CFBackupReloadState()
        throw err
    } finally {
        CF.loading := false
        try DirDelete(work, true)
    }
}
