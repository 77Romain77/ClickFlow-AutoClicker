; ClickFlow - raccourcis globaux OPTIONNELS (aucun par défaut).
; Les raccourcis F6 d'activation et F12 d'arrêt d'urgence sont inchangés.

CFGlobalKeys() {
    return ["next", "previous", "overlay", "test", "open"]
}

CFGlobalKeyLabel(action) {
    switch action {
        case "next": return "Profil suivant"
        case "previous": return "Profil précédent"
        case "overlay": return "Afficher / masquer l'overlay"
        case "test": return "Ouvrir le Test CPS"
        case "open": return "Ouvrir ClickFlow"
    }
    throw Error("Action globale inconnue.")
}

CFGlobalIniKey(action) {
    switch action {
        case "next": return "GlobalNextKey"
        case "previous": return "GlobalPreviousKey"
        case "overlay": return "GlobalOverlayKey"
        case "test": return "GlobalTestKey"
        case "open": return "GlobalOpenKey"
    }
    throw Error("Action globale inconnue.")
}

CFGlobalReadKeys() {
    global CF
    if !CF.HasOwnProp("globalKeys")
        CF.globalKeys := Map()
    for action in CFGlobalKeys() {
        key := IniRead(CF.configFile, "General", CFGlobalIniKey(action), "")
        ; Ne pas activer des valeurs mal formées issues d'un ancien INI.
        if StrLen(key) > 32 || key = "Escape" || key = "Esc"
            key := ""
        CF.globalKeys[action] := key
    }
    ; Ne jamais bloquer le démarrage pour un conflit dans un vieux fichier.
    for action in CFGlobalKeys() {
        key := CF.globalKeys[action]
        if key = ""
            continue
        if CFGlobalConflicts(key, action)
            CF.globalKeys[action] := ""
    }
}

CFGlobalConflicts(key, exceptAction := "") {
    global CF
    if key = "" || SameKey(key, CF.emergencyKey)
        return key != ""
    for profile in CF.profiles
        if SameKey(key, profile.cfg.activation)
            return true
    for action in CFGlobalKeys()
        if action != exceptAction && CF.globalKeys.Has(action)
            && CF.globalKeys[action] != "" && SameKey(key, CF.globalKeys[action])
            return true
    return false
}

CFGlobalJson() {
    global CF
    pairs := ""
    for action in CFGlobalKeys()
        pairs .= (pairs = "" ? "" : ",") JsonQuote(action) ":"
            JsonQuote(DisplayKey(CF.globalKeys.Get(action, "")))
    return "{" pairs "}"
}

CFGlobalRegister() {
    global CF
    for action in CFGlobalKeys() {
        key := CF.globalKeys.Get(action, "")
        if key = ""
            continue
        Hotkey("~*" key, CFGlobalTrigger.Bind(action), "On")
    }
}

CFGlobalUnregister() {
    global CF
    for action in CFGlobalKeys() {
        key := CF.globalKeys.Get(action, "")
        if key != ""
            try Hotkey("~*" key, "Off")
    }
}

CFGlobalSet(action, key) {
    global CF
    if !HasValue(CFGlobalKeys(), action)
        throw Error("Action globale invalide.")
    if key != "" {
        if StrLen(key) > 32 || !GetKeyVK(key)
            throw Error("Raccourci non reconnu.")
        if key = "Escape" || key = "Esc"
            throw Error("Échap est réservé à l'annulation.")
        if CFGlobalConflicts(key, action)
            throw Error("Cette touche est déjà utilisée par une action ou un profil.")
    }
    prior := CF.globalKeys[action]
    CFGlobalUnregister()
    CF.globalKeys[action] := key
    try CFGlobalRegister()
    catch as err {
        CFGlobalUnregister()
        CF.globalKeys[action] := prior
        CFGlobalRegister()
        throw err
    }
    SaveSettings()
    SendState()
}

CFGlobalTrigger(action, *) {
    global CF
    if CF.capture || CF.test.active || CF.shuttingDown
        return
    switch action {
        case "next", "previous":
            n := CF.profiles.Length
            if n < 2
                return
            current := 1
            for i, profile in CF.profiles
                if profile.id = CF.selectedId
                    current := i
            index := Mod(current - 1 + (action = "next" ? 1 : n - 1), n) + 1
            SelectProfileById(CF.profiles[index].id)
        case "overlay":
            CFDesktopToggleFloat()
        case "open":
            CFDesktopOpen()
        case "test":
            StopAll("Ouverture du Test CPS.")
            if CF.compactMode {
                CFDesktopCaptureMainBounds(true)
                CF.compactMode := false
                ApplyWindowMode()
                SaveSettings()
                SendState()
            }
            CFDesktopOpen()
            if CF.web
                try CF.web.PostWebMessageAsString('{"type":"navigate","page":"cps"}')
    }
}
