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
        for field in ["mode", "variation", "min", "max", "hold", "mouseGate",
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

CFLoadSeparatedProfiles() {
    global CF
    if !DirExist(CF.profilesDir)
        return false
    loaded := []
    maxId := 0
    Loop Files CF.profilesDir "\profile-*.ini", "F" {
        if !RegExMatch(A_LoopFileName, "^profile-([1-9]\d{0,8})\.ini$", &match)
            continue
        id := match[1] + 0
        path := A_LoopFileFullPath
        if FileGetSize(path) > 65536
            throw Error("Profil trop volumineux : " A_LoopFileName)
        if IniRead(path, "ClickFlowProfile", "FormatVersion", "") != "1"
            throw Error("Profil illisible : " A_LoopFileName)
        name := Trim(IniRead(path, "ClickFlowProfile", "Name", ""))
        if name = "" || StrLen(name) > 36
            throw Error("Nom de profil invalide : " A_LoopFileName)
        for previous in loaded
            if StrLower(previous.name) = StrLower(name)
                throw Error("Deux profils utilisent le même nom : " name)
        loaded.Push({id: id, name: name,
            cfg: ReadConfig(path, "Settings", DefaultConfig())})
        maxId := Max(maxId, id)
    }
    if loaded.Length = 0
        return false
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
