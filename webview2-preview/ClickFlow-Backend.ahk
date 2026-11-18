; ClickFlow WebView2 - backend AutoHotkey (moteur et profils).
; Conserve le format de settings.ini des versions AutoHotkey 0.2.x.
; Les clics sont envoyés uniquement lorsque l'utilisateur active un raccourci.

global CF := {
    hwnd: 0, web: 0, event: 0,
    capture: false, inputHook: 0, pressed: false, armed: false,
    target: 0, nextAt: 0, cpsNow: 0, nextVariation: 0,
    naturalCps: 12, naturalTarget: 12, total: 0, recent: [],
    lastStatus: "", notice: "Prêt.", loading: true,
    profiles: [], selectedId: 1, nextId: 2,
    configFile: A_AppData "\ClickFlow\settings.ini",
    cfg: {mode: 1, variation: 2, min: 8, max: 14,
        clickButton: "Left", activation: "F6", hold: 1,
        mouseGate: 0, gateButton: "RButton", focusStop: 1}
}

BackendInit(hwnd, web) {
    global CF
    CF.hwnd := hwnd
    CF.web := web
    try {
        if FileExist(CF.configFile) && !FileExist(CF.configFile ".backup-webview2")
            FileCopy(CF.configFile, CF.configFile ".backup-webview2")
    }
    LoadSettings()
    CF.loading := false
    RegisterActivation()
    Hotkey("~*F12", EmergencyStop, "On")
    SetTimer(EngineTick, 10)
    SetTimer(UpdateStats, 200)
    OnExit(BackendExit)
    SaveSettings()
    SetNotice("Prêt. Choisis une fenêtre cible et utilise " DisplayKey(CF.cfg.activation) ".")
}

BackendExit(*) {
    global CF
    CF.armed := false
    SetTimer(EngineTick, 0)
    SetTimer(UpdateStats, 0)
    if CF.capture {
        try CF.inputHook.Stop()
    }
    SaveSettings()
}

JsonQuote(str) {
    v := String(str)
    v := StrReplace(v, Chr(92), Chr(92) Chr(92))
    v := StrReplace(v, Chr(34), Chr(92) Chr(34))
    v := StrReplace(v, Chr(13), Chr(92) "r")
    v := StrReplace(v, Chr(10), Chr(92) "n")
    v := StrReplace(v, Chr(9), Chr(92) "t")
    return Chr(34) v Chr(34)
}

ToUiCfg(cfg) {
    mode := ["fixed","random","natural"][cfg.mode]
    intensity := ["low","medium","high"][cfg.variation]
    activation := cfg.hold = 1 ? "hold" : "toggle"
    mouse := cfg.clickButton = "Left" ? "left" : cfg.clickButton = "Right" ? "right" : "middle"
    gate := cfg.gateButton = "LButton" ? "left" : cfg.gateButton = "RButton" ? "right" : cfg.gateButton = "MButton" ? "middle" : cfg.gateButton = "XButton1" ? "mouse4" : "mouse5"
    return '{"mode":' JsonQuote(mode) ',"min":' cfg.min ',"max":' cfg.max ',"intensity":' JsonQuote(intensity) ',"activation":' JsonQuote(activation) ',"mouse":' JsonQuote(mouse) ',"hotkey":' JsonQuote(DisplayKey(cfg.activation)) ',"gate":' (cfg.mouseGate ? "true" : "false") ',"gateButton":' JsonQuote(gate) ',"focus":' (cfg.focusStop ? "true" : "false") '}'
}

SendState() {
    global CF
    if !CF.web
        return
    profiles := ""
    for p in CF.profiles
        profiles .= (profiles = "" ? "" : ",") '{"id":' p.id ',"name":' JsonQuote(p.name) ',"settings":' ToUiCfg(p.cfg) '}'
    try CF.web.PostWebMessageAsString('{"type":"state","selected":' CF.selectedId ',"profiles":[' profiles ']}')
}

SendStats() {
    global CF
    if !CF.web
        return
    waiting := CF.armed && CF.cfg.mouseGate && !GetKeyState(CF.cfg.gateButton, "P")
    try CF.web.PostWebMessageAsString('{"type":"stats","armed":' (CF.armed ? "true" : "false") ',"waiting":' (waiting ? "true" : "false") ',"capturing":' (CF.capture ? "true" : "false") ',"cps":' CF.recent.Length ',"total":' CF.total ',"hotkey":' JsonQuote(DisplayKey(CF.cfg.activation)) ',"notice":' JsonQuote(CF.notice) '}')
}

NormalizeName(name, ignoreId := 0) {
    global CF
    name := Trim(StrReplace(StrReplace(StrReplace(name, Chr(9), " "), Chr(13), " "), Chr(10), " "))
    if name = "" || StrLen(name) > 36
        return ""
    for p in CF.profiles
        if p.id != ignoreId && StrLower(p.name) = StrLower(name)
            return ""
    return name
}

SelectProfileById(id) {
    global CF
    for p in CF.profiles {
        if p.id = id {
            StopAll("Changement de profil : clics arrêtés.")
            UnregisterActivation()
            CF.cfg := p.cfg
            CF.selectedId := id
            CF.pressed := false
            try RegisterActivation()
            catch {
                CF.cfg.activation := "F6"
                RegisterActivation()
            }
            SaveSettings()
            SendState()
            return
        }
    }
}

EditConfig(field, value) {
    global CF
    cfg := CF.cfg
    switch field {
        case "mode":
            cfg.mode := value = "fixed" ? 1 : value = "random" ? 2 : value = "natural" ? 3 : cfg.mode
        case "intensity":
            cfg.variation := value = "low" ? 1 : value = "medium" ? 2 : value = "high" ? 3 : cfg.variation
        case "activation":
            cfg.hold := value = "hold" ? 1 : value = "toggle" ? 2 : cfg.hold
        case "mouse":
            cfg.clickButton := value = "left" ? "Left" : value = "right" ? "Right" : value = "middle" ? "Middle" : cfg.clickButton
        case "gateButton":
            gate := Map("left","LButton","right","RButton","middle","MButton","mouse4","XButton1","mouse5","XButton2")
            if gate.Has(value)
                cfg.gateButton := gate[value]
        case "gate":
            cfg.mouseGate := value = "1" ? 1 : 0
        case "focus":
            cfg.focusStop := value = "1" ? 1 : 0
        case "min", "max":
            if !RegExMatch(value, "^\d{1,3}$")
                return
            n := Max(1, Min(100, value + 0))
            cfg.%field% := n
            if cfg.min > cfg.max {
                if field = "min"
                    cfg.max := cfg.min
                else
                    cfg.min := cfg.max
            }
        default:
            return
    }
    StopAll("Configuration modifiée. Réactive le raccourci.")
    SetTimer(SaveSettings, -350)
    SetTimer(SendState, -160)
}

BackendMessage(sender, args) {
    global CF
    try {
        raw := args.TryGetWebMessageAsString()
        parts := StrSplit(raw, Chr(9))
        cmd := parts[1]
        if cmd = "ready" {
            SendState()
            SendStats()
            return
        }
        if cmd = "connected" {
            probe := EnvGet("CLICKFLOW_WEBVIEW_SMOKE_FILE")
            if probe != ""
                FileAppend("WebView2 and backend connected", probe ".bridge", "UTF-8")
            return
        }
        if cmd = "set" && parts.Length >= 3 {
            EditConfig(parts[2], parts[3])
            return
        }
        if cmd = "stop" {
            EmergencyStop()
            return
        }
        if cmd = "capture" {
            StartCapture()
            return
        }
        if cmd = "select" && parts.Length >= 2 {
            if RegExMatch(parts[2], "^\d+$")
                SelectProfileById(parts[2] + 0)
            return
        }
        if cmd = "new" || cmd = "duplicate" {
            if parts.Length < 2
                return
            name := NormalizeName(parts[2])
            if name = "" {
                SetNotice("Nom de profil invalide ou déjà utilisé.")
                SendState()
                return
            }
            StopAll("Création d'un profil.")
            id := CF.nextId
            CF.nextId += 1
            cfg := cmd = "duplicate" ? CopyConfig(CF.cfg) : DefaultConfig()
            CF.profiles.Push({id:id, name:name, cfg:cfg})
            SelectProfileById(id)
            return
        }
        if cmd = "rename" && parts.Length >= 2 {
            name := NormalizeName(parts[2], CF.selectedId)
            if name = "" {
                SetNotice("Nom de profil invalide ou déjà utilisé.")
                SendState()
                return
            }
            for p in CF.profiles
                if p.id = CF.selectedId
                    p.name := name
            SaveSettings()
            SendState()
            return
        }
        if cmd = "delete" && CF.profiles.Length > 1 {
            StopAll("Profil supprimé.")
            id := CF.selectedId
            for index, p in CF.profiles {
                if p.id = id {
                    CF.profiles.RemoveAt(index)
                    break
                }
            }
            try IniDelete(CF.configFile, "Profile_" id)
            SelectProfileById(CF.profiles[1].id)
            return
        }
    } catch as err {
        SetNotice("Erreur de communication : " err.Message)
    }
}

RegisterActivation() {
    global CF
    name := CF.cfg.activation
    Hotkey("~*" name, ActivationDown, "On")
    Hotkey("~*" name " Up", ActivationUp, "On")
}

UnregisterActivation() {
    global CF
    try Hotkey("~*" CF.cfg.activation, "Off")
    try Hotkey("~*" CF.cfg.activation " Up", "Off")
}

ActivationDown(*) {
    global CF
    if CF.capture || CF.pressed
        return
    CF.pressed := true
    if CF.armed {
        if CF.cfg.hold = 2
            StopAll("Arrêt par raccourci.")
        return
    }

    current := WinExist("A")
    if !current || current = CF.hwnd {
        SetNotice("Active d'abord la fenêtre cible, puis utilise le raccourci.")
        return
    }

    CF.armed := true
    CF.target := current
    CF.nextAt := A_TickCount
    CF.naturalCps := (CF.cfg.min + CF.cfg.max) / 2
    CF.naturalTarget := CF.naturalCps
    CF.nextVariation := 0
    SetNotice("Clics actifs dans la fenêtre choisie. F12 pour arrêter.")
}

ActivationUp(*) {
    global CF
    CF.pressed := false
    if CF.cfg.hold = 1 && CF.armed
        StopAll("Touche relâchée.")
}

EmergencyStop(*) {
    global CF
    if CF.capture
        FinishCapture("")
    StopAll("Arrêt d'urgence (F12).")
}

StopAll(message) {
    global CF
    CF.armed := false
    CF.target := 0
    CF.nextAt := 0
    CF.cpsNow := 0
    SetNotice(message)
}

SetNotice(message) {
    global CF
    CF.notice := message
    SendStats()
}

EngineTick() {
    global CF
    if !CF.armed || CF.capture
        return

    current := WinExist("A")
    if !current || current = CF.hwnd {
        StopAll("Arrêt : la fenêtre ClickFlow a repris le focus.")
        return
    }
    if CF.cfg.focusStop && current != CF.target {
        StopAll("Arrêt : changement de fenêtre détecté.")
        return
    }
    if CF.cfg.hold = 1 && !GetKeyState(CF.cfg.activation, "P") {
        StopAll("Arrêt : touche d'activation relâchée.")
        return
    }
    if CF.cfg.mouseGate && !GetKeyState(CF.cfg.gateButton, "P") {
        CF.cpsNow := 0
        CF.nextAt := A_TickCount
        return
    }

    now := A_TickCount
    if now < CF.nextAt
        return
    cps := GetNextCps()
    CF.cpsNow := cps

    ; Les clics sont envoyes a la position actuelle du curseur.
    ; SendInput n'intercepte pas les clics manuels et n'injecte rien dans le jeu.
    SendInput("{Click " CF.cfg.clickButton "}")
    CF.total += 1
    CF.recent.Push(now)
    ; Evite les rafales de rattrapage apres une interruption.
    CF.nextAt := now + Max(10, Round(1000 / cps))
}

GetNextCps() {
    global CF
    minimum := CF.cfg.min
    maximum := CF.cfg.max
    if CF.cfg.mode = 1
        return minimum
    if CF.cfg.mode = 2
        return Random(minimum, maximum)

    now := A_TickCount
    if now >= CF.nextVariation {
        intensity := CF.cfg.variation
        radius := (maximum - minimum) * (intensity = 1 ? 0.22 : intensity = 2 ? 0.38 : 0.5)
        center := (minimum + maximum) / 2
        low := Max(minimum, Round(center - radius))
        high := Min(maximum, Round(center + radius))
        CF.naturalTarget := Random(low, high)
        CF.nextVariation := now + Random(350, 1100)
    }
    CF.naturalCps += (CF.naturalTarget - CF.naturalCps) * 0.2
    return Max(minimum, Min(maximum, CF.naturalCps))
}

UpdateStats() {
    global CF
    now := A_TickCount
    while CF.recent.Length && CF.recent[1] < now - 1000
        CF.recent.RemoveAt(1)
    SendStats()
}

StartCapture(*) {
    global CF
    StopAll("Sélection de la touche...")
    CF.capture := true
    SendStats()
    UnregisterActivation()
    ; Interception pour ecouter uniquement : ne bloque pas les touches.
    ih := InputHook("V")
    ih.KeyOpt("{All}", "N")
    ih.OnKeyDown := CapturedKey
    CF.inputHook := ih
    for key in ["LButton", "RButton", "MButton", "XButton1", "XButton2"]
        Hotkey("~*" key, CapturedMouse.Bind(key), "On")
    ih.Start()
    SetNotice("Appuie sur une touche clavier ou souris. Échap pour annuler.")
}

CapturedKey(ih, vk, sc) {
    global CF
    if !CF.capture
        return
    name := GetKeyName(Format("vk{:02X}sc{:03X}", vk, sc))
    if name = "Esc" || name = "Escape" {
        FinishCapture("")
        return
    }
    if name = "F12" {
        FinishCapture("")
        SetNotice("F12 est réservée à l'arrêt d'urgence.")
        return
    }
    if name = "" || InStr("|Shift|LShift|RShift|Ctrl|LCtrl|RCtrl|Alt|LAlt|RAlt|LWin|RWin|", "|" name "|")
        return
    FinishCapture(Format("vk{:02X}", vk))
}

CapturedMouse(key, *) {
    global CF
    if CF.capture
        FinishCapture(key)
}

FinishCapture(key) {
    global CF
    if !CF.capture
        return
    CF.capture := false
    if IsObject(CF.inputHook)
        CF.inputHook.Stop()
    CF.inputHook := 0
    for mouseKey in ["LButton", "RButton", "MButton", "XButton1", "XButton2"]
        try Hotkey("~*" mouseKey, "Off")

    old := CF.cfg.activation
    if key != ""
        CF.cfg.activation := key
    try {
        RegisterActivation()
    } catch as err {
        CF.cfg.activation := old
        RegisterActivation()
        SetNotice("Touche non prise en charge : " err.Message)
        key := ""
    }
    CF.pressed := false
    SendState()
    if key != "" {
        SaveSettings()
        SetNotice("Activation définie : " DisplayKey(CF.cfg.activation) ".")
    } else if old = CF.cfg.activation {
        SetNotice("Capture annulée. Activation conservée : " DisplayKey(old) ".")
    }
}

DefaultConfig() {
    return {mode: 1, variation: 2, min: 8, max: 14,
        clickButton: "Left", activation: "F6", hold: 1,
        mouseGate: 0, gateButton: "RButton", focusStop: 1}
}

CopyConfig(cfg) {
    return {mode: cfg.mode, variation: cfg.variation, min: cfg.min, max: cfg.max,
        clickButton: cfg.clickButton, activation: cfg.activation, hold: cfg.hold,
        mouseGate: cfg.mouseGate, gateButton: cfg.gateButton, focusStop: cfg.focusStop}
}

SelectedProfileIndex() {
    global CF
    for index, profile in CF.profiles {
        if profile.id = CF.selectedId
            return index
    }
    return 1
}

ReadConfig(file, section, base) {
    cfg := CopyConfig(base)
    if !FileExist(file)
        return cfg
    for field in ["mode", "variation", "min", "max", "hold", "mouseGate", "focusStop"] {
        value := IniRead(file, section, field, cfg.%field%)
        if RegExMatch(value, "^\d+$")
            cfg.%field% := value + 0
    }
    for field in ["clickButton", "activation", "gateButton"]
        cfg.%field% := IniRead(file, section, field, cfg.%field%)

    cfg.mode := Max(1, Min(3, cfg.mode))
    cfg.variation := Max(1, Min(3, cfg.variation))
    cfg.min := Max(1, Min(100, cfg.min))
    cfg.max := Max(cfg.min, Min(100, cfg.max))
    cfg.hold := Max(1, Min(2, cfg.hold))
    cfg.mouseGate := cfg.mouseGate ? 1 : 0
    cfg.focusStop := cfg.focusStop ? 1 : 0
    if !HasValue(["Left", "Right", "Middle"], cfg.clickButton)
        cfg.clickButton := "Left"
    if !HasValue(["LButton", "RButton", "MButton", "XButton1", "XButton2"], cfg.gateButton)
        cfg.gateButton := "RButton"
    if cfg.activation = "" || cfg.activation = "!" || cfg.activation = "F12" || cfg.activation = "vk7B"
        cfg.activation := "F6"
    return cfg
}

LoadSettings() {
    global CF
    file := CF.configFile
    ; Conserve les réglages précédents dans le profil Principal.
    savedIds := FileExist(file) ? IniRead(file, "Profiles", "Ids", "") : ""
    if savedIds = "" {
        first := ReadConfig(file, "ClickFlow", DefaultConfig())
        CF.profiles := [{id: 1, name: "Principal", cfg: first}]
        CF.cfg := first
        CF.selectedId := 1
        CF.nextId := 2
        return
    }

    CF.profiles := []
    maxId := 0
    for raw in StrSplit(savedIds, ",") {
        raw := Trim(raw)
        if !RegExMatch(raw, "^\d+$")
            continue
        id := raw + 0
        if id < 1
            continue
        duplicate := false
        for prior in CF.profiles {
            if prior.id = id
                duplicate := true
        }
        if duplicate
            continue
        section := "Profile_" id
        name := Trim(IniRead(file, section, "Name", "Profil " id))
        if name = ""
            name := "Profil " id
        cfg := ReadConfig(file, section, DefaultConfig())
        CF.profiles.Push({id: id, name: name, cfg: cfg})
        maxId := Max(maxId, id)
    }
    if CF.profiles.Length = 0 {
        first := ReadConfig(file, "ClickFlow", DefaultConfig())
        CF.profiles.Push({id: 1, name: "Principal", cfg: first})
        maxId := 1
    }

    CF.selectedId := IniRead(file, "Profiles", "Selected", CF.profiles[1].id) + 0
    CF.nextId := Max(maxId + 1, IniRead(file, "Profiles", "NextId", maxId + 1) + 0)
    found := false
    for p in CF.profiles {
        if p.id = CF.selectedId {
            CF.cfg := p.cfg
            found := true
            break
        }
    }
    if !found {
        CF.selectedId := CF.profiles[1].id
        CF.cfg := CF.profiles[1].cfg
    }
}

SaveSettings(*) {
    global CF
    if CF.loading
        return
    try {
        DirCreate(A_AppData "\ClickFlow")
        ids := ""
        for p in CF.profiles {
            ids .= (ids = "" ? "" : ",") p.id
            section := "Profile_" p.id
            IniWrite(p.name, CF.configFile, section, "Name")
            for field in ["mode", "variation", "min", "max", "hold", "mouseGate",
                "focusStop", "clickButton", "activation", "gateButton"] {
                IniWrite(p.cfg.%field%, CF.configFile, section, field)
            }
        }
        IniWrite(ids, CF.configFile, "Profiles", "Ids")
        IniWrite(CF.selectedId, CF.configFile, "Profiles", "Selected")
        IniWrite(CF.nextId, CF.configFile, "Profiles", "NextId")
    } catch as err {
        SetNotice("Sauvegarde impossible : " err.Message)
    }
}

HasValue(array, value) {
    for item in array
        if item = value
            return true
    return false
}

DisplayKey(key) {
    if SubStr(key, 1, 2) = "vk" {
        try return GetKeyName(key)
    }
    return key
}
