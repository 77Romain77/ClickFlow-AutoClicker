; ClickFlow - gestion des profils individuels (AutoHotkey v2).
; settings.ini conserve les préférences générales et la sélection du profil.

CFProfileFile(id) {
    global CF
    if !RegExMatch(String(id), "^[1-9]\d{0,8}$")
        throw Error("Identifiant de profil invalide.")
    return CF.profilesDir "\profile-" id ".ini"
}

CFWriteProfile(profile) {
    global CF
    DirCreate(CF.profilesDir)
    path := CFProfileFile(profile.id)
    temporary := path ".writing"
    try {
        if FileExist(temporary)
            FileDelete(temporary)
        IniWrite("1", temporary, "ClickFlowProfile", "FormatVersion")
        IniWrite(profile.name, temporary, "ClickFlowProfile", "Name")
        IniWrite(profile.HasOwnProp("favorite") && profile.favorite ? 1 : 0,
            temporary, "ClickFlowProfile", "Favorite")
        IniWrite(profile.HasOwnProp("sortOrder") ? profile.sortOrder : profile.id,
            temporary, "ClickFlowProfile", "SortOrder")
        for field in ["mode", "variation", "min", "max", "rapidTarget",
            "rapidPreset", "rapidBetween", "rapidWithin", "rapidRpm", "hold", "mouseGate",
            "focusStop", "clickButton", "activation", "gateButton"]
            IniWrite(profile.cfg.%field%, temporary, "Settings", field)
        ; Déplacement avec remplacement : l'ancienne copie reste intacte
        ; si la préparation du fichier temporaire échoue.
        FileMove(temporary, path, 1)
    } catch as err {
        try FileDelete(temporary)
        throw err
    }
}

CFProfileQuarantine(path, reason) {
    global CF
    ; Ne jamais détruire ni réécrire un profil illisible au démarrage.
    ; Conserver son nom et son contenu dans un sous-dossier non chargé.
    folder := CF.profilesDir "\_recovery"
    moved := false
    try {
        DirCreate(folder)
        SplitPath(path, &filename)
        Loop 100 {
            dest := folder "\" filename "." A_Now "-" A_TickCount
                "-" A_Index ".damaged"
            if !FileExist(dest) {
                FileMove(path, dest)
                moved := true
                break
            }
        }
    } catch {
        ; Sans permission de déplacer, ignorer ce fichier pendant
        ; la session, sans le réécrire ni empêcher les autres de démarrer.
    }
    CF.profileRecoveryWarnings.Push(
        (moved ? "Profil isolé : " : "Profil ignoré (fichier conservé) : ")
        path " (" reason ")")
}

CFLoadSeparatedProfiles() {
    global CF
    CF.profileRecoveryWarnings := []
    if !DirExist(CF.profilesDir)
        return false
    loaded := []
    maxId := 0
    Loop Files CF.profilesDir "\profile-*.ini", "F" {
        if !RegExMatch(A_LoopFileName, "^profile-([1-9]\d{0,8})\.ini$", &match)
            continue
        id := match[1] + 0
        maxId := Max(maxId, id)
        path := A_LoopFileFullPath
        try {
            if FileGetSize(path) > 65536
                throw Error("Profil trop volumineux.")
            if IniRead(path, "ClickFlowProfile", "FormatVersion", "") != "1"
                throw Error("Format de profil illisible.")
            name := Trim(IniRead(path, "ClickFlowProfile", "Name", ""))
            if name = "" || StrLen(name) > 36
                throw Error("Nom de profil invalide.")
            for previous in loaded
                if StrLower(previous.name) = StrLower(name)
                    throw Error("Nom de profil déjà utilisé : " name)
            favorite := IniRead(path, "ClickFlowProfile", "Favorite", "0") = "1"
            rank := IniRead(path, "ClickFlowProfile", "SortOrder", String(id))
            if !RegExMatch(rank, "^\d{1,9}$")
                rank := id
            cfg := ReadConfig(path, "Settings", DefaultConfig())
            loaded.Push({id: id, name: name, favorite: favorite,
                sortOrder: rank + 0, cfg: cfg})
        } catch as err {
            CFProfileQuarantine(path, err.Message)
        }
    }
    if loaded.Length = 0 {
        ; Après migration, une suppression manuelle des fichiers ne doit pas
        ; restaurer des profils historiques cachés dans settings.ini.
        if IniRead(CF.configFile, "Profiles", "StorageVersion", "") != "2"
            && CF.profileRecoveryWarnings.Length = 0
            return false
        defaults := DefaultConfig()
        ; Si un profil corrompu n'a pas pu être déplacé, ne jamais
        ; réutiliser son identifiant en sauvegardant le profil de secours.
        fallbackId := maxId + 1
        CF.profiles := [{id: fallbackId, name: "Principal", cfg: defaults}]
        CF.selectedId := fallbackId
        CF.nextId := Max(fallbackId + 1,
            IniRead(CF.configFile, "Profiles", "NextId", 2) + 0)
        CF.cfg := defaults
        return true
    }
    ; L'ordre est stocké avec chaque profil, compatible avec les anciens INI.
    CFSortProfiles(loaded)
    CF.profiles := loaded
    file := CF.configFile
    CF.selectedId := IniRead(file, "Profiles", "Selected", loaded[1].id) + 0
    CF.nextId := Max(maxId + 1, IniRead(file, "Profiles", "NextId", maxId + 1) + 0)
    selected := 0
    for profile in loaded
        if profile.id = CF.selectedId
            selected := profile
    if !selected {
        selected := loaded[1]
        CF.selectedId := selected.id
    }
    CF.cfg := selected.cfg
    return true
}

CFProfileById(id) {
    global CF
    for profile in CF.profiles
        if profile.id = id
            return profile
    return 0
}

CFUniqueImportedName(name) {
    base := Trim(StrReplace(StrReplace(StrReplace(name, Chr(9), " "),
        Chr(10), " "), Chr(13), " "))
    if base = ""
        throw Error("Ce profil ne possède pas de nom.")
    base := SubStr(base, 1, 36)
    if NormalizeName(base) != ""
        return base
    Loop 99 {
        suffix := " (" (A_Index + 1) ")"
        candidate := SubStr(base, 1, 36 - StrLen(suffix)) suffix
        if NormalizeName(candidate) != ""
            return candidate
    }
    throw Error("Impossible de générer un nom de profil unique.")
}

CFProfileMessage(message, failed := false) {
    global CF
    if CF.web
        try CF.web.PostWebMessageAsString('{"type":"profileAction","message":'
            JsonQuote(message) ',"error":' (failed ? "true" : "false") '}')
}

CFExportProfile(id) {
    profile := CFProfileById(id)
    if !profile
        throw Error("Ce profil n'existe plus.")
    filename := RegExReplace(profile.name, "[^[:alnum:] _-]", "_")
    destination := FileSelect("S16", A_Desktop "\ClickFlow-" filename ".ini",
        "Exporter le profil ClickFlow", "Profil ClickFlow (*.ini)")
    if destination = ""
        return
    if !RegExMatch(destination, "i)\.ini$")
        destination .= ".ini"
    source := CFProfileFile(profile.id)
    if StrLower(source) = StrLower(destination)
        throw Error("Choisis un autre emplacement que le stockage interne.")
    CFWriteProfile(profile)
    FileCopy(source, destination, true)
    CFProfileMessage("Profil exporté : " profile.name)
}

CFImportProfileFromFile(source) {
    global CF
    if !FileExist(source)
        throw Error("Le fichier sélectionné est introuvable.")
    if FileGetSize(source) > 65536
        throw Error("Ce fichier de profil est trop volumineux.")
    if IniRead(source, "ClickFlowProfile", "FormatVersion", "") != "1"
        throw Error("Format de profil ClickFlow incompatible.")
    name := CFUniqueImportedName(IniRead(source, "ClickFlowProfile", "Name", ""))
    cfg := ReadConfig(source, "Settings", DefaultConfig())
    id := CF.nextId
    imported := {id: id, name: name, cfg: cfg}
    ; Le nouveau profil doit être correctement sauvegardé avant son activation.
    CFWriteProfile(imported)
    CF.nextId += 1
    CF.profiles.Push(imported)
    return imported
}

CFImportProfile() {
    source := FileSelect(1, A_Desktop, "Importer un profil ClickFlow",
        "Profil ClickFlow (*.ini)")
    if source = ""
        return
    imported := CFImportProfileFromFile(source)
    SelectProfileById(imported.id)
    CFProfileMessage("Profil importé : " imported.name)
}


CFSortProfiles(profiles) {
    ; Tri stable et sans dépendance externe (nombre de profils limité).
    length := profiles.Length
    if length < 2
        return
    Loop length - 1 {
        i := A_Index + 1
        while i > 1 {
            a := profiles[i - 1]
            b := profiles[i]
            left := a.HasOwnProp("sortOrder") ? a.sortOrder : a.id
            right := b.HasOwnProp("sortOrder") ? b.sortOrder : b.id
            if left < right || (left = right && a.id <= b.id)
                break
            profiles[i - 1] := b
            profiles[i] := a
            i -= 1
        }
    }
}

CFReorderProfile(id, direction) {
    global CF
    if direction != "up" && direction != "down"
        return
    found := 0
    for i, p in CF.profiles
        if p.id = id
            found := i
    if !found
        return
    other := found + (direction = "up" ? -1 : 1)
    if other < 1 || other > CF.profiles.Length
        return
    temp := CF.profiles[found]
    CF.profiles[found] := CF.profiles[other]
    CF.profiles[other] := temp
    for i, p in CF.profiles
        p.sortOrder := i
    SaveSettings()
    SendState()
}

CFToggleProfileFavorite(id) {
    global CF
    p := CFProfileById(id)
    if !p
        return
    p.favorite := !(p.HasOwnProp("favorite") && p.favorite)
    SaveSettings()
    SendState()
}
