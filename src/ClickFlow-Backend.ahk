; ClickFlow WebView2 - backend AutoHotkey (moteur et profils).
; Conserve le format de settings.ini des versions AutoHotkey 0.2.x.
; Les clics sont envoyés uniquement lorsque l'utilisateur active un raccourci.
#Include ClickFlow-Maintenance.ahk
#Include ClickFlow-ProfileStore.ahk
#Include ClickFlow-CpsTest.ahk
#Include ClickFlow-Desktop.ahk
#Include ClickFlow-GlobalHotkeys.ahk
#Include ClickFlow-Backup.ahk

global CF := {
    hwnd: 0, web: 0, event: 0,
    capture: false, inputHook: 0, pressed: false, armed: false,
    test: {active: false},
    desktopReady: false, trayProfiles: 0, floatGui: 0,
    closeToTray: false, minimizeToTray: false, floatShown: false,
    liveMonitor: true, compactChart: true, forceExit: false,
    floatGraph: false, floatTopMost: true, floatOpacity: 100,
    floatWidth: 340, floatHeight: 205, floatX: -99999, floatY: -99999,
    floatPoints: [], floatLastSample: 0, floatReady: false, floatBitmap: 0,
    floatBoundsOuter: false, floatLegacyClient: false,
    floatChartPaintCount: 0, floatGraphActive: false,
    overlayGui: 0, overlayVisible: false, overlayEditing: false,
    overlayAlwaysVisible: false, overlayOpacity: 85, overlayMargin: 20,
    overlaySize: "mini", overlayShowProfile: false,
    overlayAverageSeconds: 5,
    overlayMonitor: 1, overlayPosition: "tm",
    overlayX: -99999, overlayY: -99999, overlayUntil: 0,
    overlayRecent: [], overlayStart: 0,
    engineTimerActive: false, statsTimerActive: false,
    engineLoopRunning: false, precisionRequested: false, precisionHandle: 0,
    firstDispatchMs: "", firstDispatchKind: "", activationCounter: 0, qpcFrequency: 0,
    diagnosticsEnabled: false, gateDetectionMs: "", gateProbeStatus: "",
    gateHook: 0, gateHookCallback: 0, gateProbePending: false, gateProbeQpc: 0,
    gateWakeSignal: false, gateHookFailed: false,
    mouseDetectionMode: "auto", gateMethodLast: "none",
    gateMethodCurrent: "inactive", gateWaiting: false,
    gateEventUptime: 0, gateEventDelayMs: "", gateEventAverageMs: "", gateEventSamples: [],
    mainExpandedW: 1120, mainExpandedH: 800,
    mainCompactW: 480, mainCompactH: 600,
    target: 0, nextAt: 0, cpsNow: 0, nextVariation: 0,
    naturalCps: 12, naturalTarget: 12, naturalNoise: 0,
    naturalBurstLeft: 0, total: 0, recent: [],
    lastStatus: "", notice: "Prêt.", loading: true, shuttingDown: false,
    emergencyKey: "F12", compactMode: false, captureKind: "activation",
    globalKeys: Map(),
    profiles: [], selectedId: 1, nextId: 2,
    configFile: A_AppData "\ClickFlow\settings.ini",
    profilesDir: A_AppData "\ClickFlow\profiles",
    cfg: {mode: 1, variation: 2, min: 8, max: 14,
        clickButton: "Left", activation: "F6", hold: 1,
        mouseGate: 0, gateButton: "RButton", focusStop: 1}
}

BackendInit(hwnd, web) {
    global CF
    ; Ces hooks existaient dans la version classique 0.2.5.
    ; Ils distinguent l'etat physique de la souris des clics generes par SendInput.
    ; Sans hook, GetKeyState("LButton", "P") peut lire l'etat logique perturbe
    ; par nos propres clics, et interrompre la condition de maintien.
    InstallKeybdHook()
    InstallMouseHook()
    SendMode("Input")
    CF.hwnd := hwnd
    CF.web := web
    try {
        if FileExist(CF.configFile) && !FileExist(CF.configFile ".backup-webview2")
            FileCopy(CF.configFile, CF.configFile ".backup-webview2")
    }
    CF.emergencyKey := IniRead(CF.configFile, "General", "EmergencyKey", "F12")
    CF.compactMode := IniRead(CF.configFile, "General", "CompactMode", "0") = "1"
    ; Une chaîne vide est un choix explicite "Aucun", pas une erreur.
    ; F12 ne sert que de valeur initiale si la préférence n'existe pas.
    if CF.emergencyKey = "!" || CF.emergencyKey = "Escape"
        CF.emergencyKey := "F12"
    LoadSettings()
    CFDesktopReadPreferences()
    ; Au démarrage un raccourci d'urgence ne doit jamais entrer en conflit
    ; avec l'activation du profil actuel. On préfère une touche de secours.
    for p in CF.profiles {
        if SameKey(p.cfg.activation, CF.emergencyKey)
            p.cfg.activation := SameKey(CF.emergencyKey, "F6") ? "F7" : "F6"
    }
    if SameKey(CF.cfg.activation, CF.emergencyKey)
        CF.cfg.activation := SameKey(CF.emergencyKey, "F6") ? "F7" : "F6"
    CFGlobalReadKeys()
    CF.loading := false
    RegisterEmergency()
    RegisterActivation()
    CFGlobalRegister()
    ; Au repos le moteur est ENTIÈREMENT désactivé. La télémétrie
    ; ne se réveille qu'une fois par seconde, puis 5 fois/s en activité.
    CF.engineTimerActive := false
    CF.statsTimerActive := false
    SetTimer(UpdateStats, 1000)
    OnExit(BackendExit)
    SaveSettings()
    CFDesktopInit()
    SetNotice("Prêt. Choisis une fenêtre cible et utilise " DisplayKey(CF.cfg.activation) ".")
}

BackendExit(*) {
    global CF
    if CF.shuttingDown
        return
    CFDesktopCaptureMainBounds(CF.compactMode)
    CF.shuttingDown := true
    CFGateProbeStop()

    ; Aucun nouveau clic, timer ou message WebView2 pendant la fermeture.
    CFTestStop("fermeture")
    CF.armed := false
    CF.pressed := false
    try CFEngineSetTimer(false)
    try SetTimer(UpdateStats, 0)
    try SetTimer(SaveSettings, 0)
    try SetTimer(SendState, 0)
    CF.desktopReady := false
    CFDesktopReleaseFloat()
    if CF.capture {
        try CF.inputHook.Stop()
        CF.capture := false
    }
    try UnregisterActivation()
    try UnregisterEmergency()
    try CFGlobalUnregister()

    ; Sauvegarde AVANT la destruction de WebView2.
    CF.web := 0
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
    for p in CF.profiles {
        fav := p.HasOwnProp("favorite") && p.favorite ? "true" : "false"
        profiles .= (profiles = "" ? "" : ",") '{"id":' p.id ',"name":' JsonQuote(p.name) ',"favorite":' fav ',"settings":' ToUiCfg(p.cfg) '}'
    }
    CFDesktopRebuildProfiles()
    try CF.web.PostWebMessageAsString('{"type":"state","selected":' CF.selectedId ',"profiles":[' profiles '],"emergencyKey":' JsonQuote(DisplayKey(CF.emergencyKey)) ',"compact":' (CF.compactMode ? "true" : "false") ',"preferences":' CFDesktopPreferencesJson() ',"globalHotkeys":' CFGlobalJson() '}')
}

; Gestion indépendante des raccourcis Windows. L'état affiché est celui
; des fichiers présents sur le disque et non d'une ancienne préférence INI.
; Une suppression manuelle n'entraîne donc aucune recréation.
CFShortcutPaths() {
    appRoot := EnvGet("LOCALAPPDATA") "\ClickFlow"
    desktop := EnvGet("CLICKFLOW_SHORTCUT_TEST_DESKTOP")
    startMenu := EnvGet("CLICKFLOW_SHORTCUT_TEST_STARTMENU")
    if desktop = ""
        desktop := A_Desktop
    if startMenu = ""
        startMenu := A_Programs
    return {app: appRoot, desktop: desktop, start: startMenu,
        script: appRoot "\ClickFlow.ahk", icon: appRoot "\ClickFlow.ico",
        ini: appRoot "\shortcuts.ini"}
}

CFShortcutIsOwned(file) {
    if !FileExist(file)
        return false
    paths := CFShortcutPaths()
    try {
        link := ComObject("WScript.Shell").CreateShortcut(file)
        return StrLower(link.TargetPath) = StrLower(A_AhkPath)
            && InStr(StrLower(link.Arguments), StrLower(paths.script)) != 0
    }
    return false
}

CFShortcutHas(place) {
    paths := CFShortcutPaths()
    folder := place = "desktop" ? paths.desktop : place = "start" ? paths.start : ""
    if folder = ""
        return false
    return CFShortcutIsOwned(folder "\ClickFlow - AutoCliker.lnk")
        || CFShortcutIsOwned(folder "\ClickFlow.lnk")
}

CFShortcutChange(place, action) {
    if place != "desktop" && place != "start"
        throw Error("Emplacement de raccourci inconnu.")
    if action != "create" && action != "remove"
        throw Error("Action de raccourci inconnue.")
    paths := CFShortcutPaths()
    folder := place = "desktop" ? paths.desktop : paths.start
    target := folder "\ClickFlow - AutoCliker.lnk"
    old := folder "\ClickFlow.lnk"

    if action = "create" {
        if !FileExist(paths.script) || !FileExist(paths.icon)
            throw Error("Lance le fichier unique ClickFlow pour installer les raccourcis.")
        if FileExist(target) && !CFShortcutIsOwned(target)
            throw Error("Un autre raccourci utilise déjà ce nom.")
        DirCreate(folder)
        FileCreateShortcut(A_AhkPath, target, paths.app,
            '"' paths.script '"', "ClickFlow - AutoCliker", paths.icon)
        if CFShortcutIsOwned(old)
            FileDelete(old)
    } else {
        ; Ne jamais supprimer un raccourci appartenant à un autre logiciel.
        if CFShortcutIsOwned(target)
            FileDelete(target)
        if CFShortcutIsOwned(old)
            FileDelete(old)
    }
    ; La préférence de chaque destination est distincte, mais aucun raccourci
    ; n'est restauré automatiquement : seule une action explicite le crée.
    IniWrite(action = "create" ? "1" : "0", paths.ini,
        "Shortcuts", place = "desktop" ? "Desktop" : "StartMenu")
}

CFSendShortcutStatus(errorMessage := "") {
    global CF
    if !CF.web
        return
    d := CFShortcutHas("desktop") ? "true" : "false"
    m := CFShortcutHas("start") ? "true" : "false"
    try CF.web.PostWebMessageAsString('{"type":"shortcuts","desktop":' d
        ',"start":' m ',"error":' JsonQuote(errorMessage) '}')
}


SendStats() {
    global CF
    if !CF.web
        return
    waiting := CF.armed && CF.cfg.mouseGate && !GetKeyState(CF.cfg.gateButton, "P")
    try CF.web.PostWebMessageAsString('{"type":"stats","armed":' (CF.armed ? "true" : "false") ',"waiting":' (waiting ? "true" : "false") ',"capturing":' (CF.capture ? "true" : "false") ',"captureKind":' JsonQuote(CF.captureKind) ',"cps":' CF.recent.Length ',"total":' CF.total ',"hotkey":' JsonQuote(DisplayKey(CF.cfg.activation)) ',"notice":' JsonQuote(CF.notice) ',"diagnosticsEnabled":' (CF.diagnosticsEnabled ? "true" : "false") ',"firstDispatchMs":' (!CF.diagnosticsEnabled || CF.firstDispatchMs = "" ? "null" : CF.firstDispatchMs) ',"firstDispatchKind":' JsonQuote(CF.firstDispatchKind) ',"gateDetectionMs":' (!CF.diagnosticsEnabled || CF.gateDetectionMs = "" ? "null" : CF.gateDetectionMs) ',"gateEventDelayMs":' (!CF.diagnosticsEnabled || CF.gateEventDelayMs = "" ? "null" : CF.gateEventDelayMs) ',"gateEventAverageMs":' (!CF.diagnosticsEnabled || CF.gateEventAverageMs = "" ? "null" : CF.gateEventAverageMs) ',"gateEventSamples":' CF.gateEventSamples.Length ',"gateProbeStatus":' JsonQuote(CF.gateProbeStatus) ',"mouseDetectionMode":' JsonQuote(CF.mouseDetectionMode) ',"gateMethodCurrent":' JsonQuote(CF.gateMethodCurrent) ',"gateMethodLast":' JsonQuote(CF.gateMethodLast) ',"gateHookInstalled":' (CF.gateHook ? "true" : "false") '}')
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

CFOpenStorageFolder(kind) {
    if kind != "program" && kind != "profiles"
        return
    folder := kind = "program" ? EnvGet("LOCALAPPDATA") "\ClickFlow"
        : EnvGet("APPDATA") "\ClickFlow"
    try {
        DirCreate(folder)
        Run('explorer.exe "' folder '"')
    } catch as err {
        SetNotice("Impossible d'ouvrir ce dossier : " err.Message)
    }
}

CFStartUninstall(mode) {
    global CF
    if mode != "keep" && mode != "all"
        return
    if CF.shuttingDown
        return

    if mode = "keep" {
        answer := MsgBox("Désinstaller ClickFlow de ce PC ?"
            Chr(10) Chr(10) "Seront supprimés : les raccourcis ClickFlow, les versions locales du programme, son icône et ses caches WebView2."
            Chr(10) Chr(10) "Seront CONSERVÉS : les profils, les raccourcis configurés dans les profils, et les paramètres dans %APPDATA%\ClickFlow."
            Chr(10) Chr(10) "Le fichier .ahk présent dans Téléchargements ne sera pas supprimé.",
            "ClickFlow - Conserver mes données", "YesNo Icon!")
        if answer != "Yes"
            return
    } else {
        answer := MsgBox("Supprimer ClickFlow ET toutes ses données personnelles ?"
            Chr(10) Chr(10) "Les raccourcis, les fichiers locaux, les profils et leurs sauvegardes seront effacés."
            Chr(10) "Cette opération est irréversible."
            Chr(10) Chr(10) "Le fichier téléchargé en dehors des dossiers ClickFlow ne sera pas supprimé.",
            "ClickFlow - Suppression complète", "YesNo Icon!")
        if answer != "Yes"
            return
        verification := InputBox('Pour confirmer, écris exactement SUPPRIMER :',
            "Confirmation de suppression définitive", "w370 h150")
        if verification.Result != "OK" || verification.Value != "SUPPRIMER" {
            SetNotice("Désinstallation complète annulée.")
            return
        }
    }

    ; Une copie du désinstallateur doit survivre à la suppression du runtime.
    helperSource := A_ScriptDir "\ClickFlow-Uninstall.ahk"
    maintenanceSource := A_ScriptDir "\ClickFlow-Maintenance.ahk"
    if !FileExist(helperSource) || !FileExist(maintenanceSource) {
        SetNotice("Les composants de désinstallation sont introuvables.")
        return
    }

    tempFolder := A_Temp "\ClickFlow-Uninstall-" A_TickCount "-" DllCall("Kernel32\GetCurrentProcessId", "UInt")
    try {
        DirCreate(tempFolder)
        FileCopy(helperSource, tempFolder "\ClickFlow-Uninstall.ahk", true)
        FileCopy(maintenanceSource, tempFolder "\ClickFlow-Maintenance.ahk", true)
        StopAll("Désinstallation de ClickFlow.")
        SaveSettings()
        parentPid := DllCall("Kernel32\GetCurrentProcessId", "UInt")
        Run('"' A_AhkPath '" "' tempFolder '\ClickFlow-Uninstall.ahk" ' mode ' ' parentPid, , "Hide")
    } catch as err {
        SetNotice("Impossible de lancer la désinstallation : " err.Message)
        return
    }
    ; Ignorer la fermeture vers la zone de notification lors de la désinstallation.
    CF.forceExit := true
    ; Le Close handler désactive les raccourcis et libère WebView2 proprement.
    DllCall("User32\PostMessageW", "Ptr", CF.hwnd, "UInt", 0x10,
        "Ptr", 0, "Ptr", 0)
}

BackendMessage(sender, args) {
    global CF
    try {
        raw := args.TryGetWebMessageAsString()
        parts := StrSplit(raw, Chr(9))
        cmd := parts[1]
        if cmd = "uiError" {
            probe := EnvGet("CLICKFLOW_WEBVIEW_SMOKE_FILE")
            if probe != "" && parts.Length >= 2
                FileAppend(parts[2] "`n", probe ".js-error", "UTF-8")
            return
        }
        if cmd = "ready" {
            probe := EnvGet("CLICKFLOW_WEBVIEW_SMOKE_FILE")
            if probe != ""
                FileAppend("received ready", probe ".ready", "UTF-8")
            SendState()
            SendStats()
            CFSendShortcutStatus()
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
        if cmd = "quickSettings" && parts.Length >= 6 {
            try CFApplyQuickSettings(parts[2], parts[3], parts[4],
                parts[5], parts[6])
            catch as err
                CFProfileMessage("Réglages rapides refusés : " err.Message, true)
            return
        }
        if cmd = "favorite" && parts.Length >= 2 {
            if RegExMatch(parts[2], "^[1-9]\d{0,8}$")
                CFToggleProfileFavorite(parts[2] + 0)
            return
        }
        if cmd = "reorder" && parts.Length >= 3 {
            if RegExMatch(parts[2], "^[1-9]\d{0,8}$")
                CFReorderProfile(parts[2] + 0, parts[3])
            return
        }
        if cmd = "preference" && parts.Length >= 3 {
            CFDesktopSetPreference(parts[2], parts[3])
            return
        }
        if cmd = "desktop" && parts.Length >= 2 {
            if parts[2] = "show"
                CFDesktopOpen()
            else if parts[2] = "float"
                CFDesktopToggleFloat()
            else if parts[2] = "hide"
                CFDesktopHide()
            else if parts[2] = "overlayEdit"
                CFOverlaySetEdit(true)
            else if parts[2] = "overlayDone"
                CFOverlaySetEdit(false)
            return
        }
        if cmd = "stop" {
            EmergencyStop()
            return
        }
        if cmd = "capture" {
            StartCapture("activation")
            return
        }
        if cmd = "captureStop" {
            StartCapture("emergency")
            return
        }
        ; Même la commande cancel sans argument (2 champs) doit passer.
        if cmd = "globalHotkey" && parts.Length >= 2 {
            try {
                ; Clavier capturé par WebView2 : contrairement à InputHook,
                ; les frappes ne sont pas perdues dans le processus Chromium.
                switch parts[2] {
                    case "begin", "capture":
                        ; globalHotkey + begin + action = 3 champs.
                        if parts.Length >= 3
                            CFWebShortcutBegin(parts[3])
                    case "set":
                        ; globalHotkey + set + action + touche = 4 champs.
                        if parts.Length >= 4
                            CFWebShortcutFinish(parts[3], parts[4])
                    case "cancel":
                        if CF.capture && (CF.captureKind = "emergency"
                            || SubStr(CF.captureKind, 1, 7) = "global:")
                            FinishCapture("")
                    case "clear":
                        ; globalHotkey + clear + action = 3 champs.
                        if parts.Length >= 3 {
                            if CF.capture
                                FinishCapture("")
                            if parts[3] = "emergency"
                                CFSetEmergencyKey("")
                            else
                                CFGlobalSet(parts[3], "")
                            SendState()
                        }
                }
            } catch as err {
                if CF.capture && (CF.captureKind = "emergency"
                    || SubStr(CF.captureKind, 1, 7) = "global:")
                    FinishCapture("")
                SetNotice("Raccourci refusé : " err.Message)
                CFProfileMessage("Raccourci refusé : " err.Message, true)
                SendState()
            }
            return
        }
        if cmd = "export" && parts.Length >= 2 {
            try {
                if RegExMatch(parts[2], "^\d{1,9}$")
                    CFExportProfile(parts[2] + 0)
            } catch as err {
                CFProfileMessage("Export impossible : " err.Message, true)
            }
            return
        }
        if cmd = "import" {
            try CFImportProfile()
            catch as err
                CFProfileMessage("Import impossible : " err.Message, true)
            return
        }
        if cmd = "backup" && parts.Length >= 2 {
            try {
                if parts[2] = "export"
                    CFBackupExport()
                else if parts[2] = "restore"
                    CFBackupRestore()
            } catch as err {
                CFProfileMessage("Sauvegarde impossible : " err.Message, true)
            }
            return
        }
        if cmd = "cpsTest" && parts.Length >= 2 {
            switch parts[2] {
                case "open":
                    StopAll("Test CPS : clics automatiques arrêtés.")
                case "start":
                    try {
                        if parts.Length < 5
                            throw Error("Commande de test incomplète.")
                        CFTestStart(parts[3], parts[4], parts[5])
                    } catch as err {
                        CFTestPost('{"type":"cpsTest","state":"error","run":'
                            (parts.Length >= 4 && RegExMatch(parts[4], "^[1-9]\d{0,8}$") ? parts[4] : "0")
                            ',"message":' JsonQuote(err.Message) '}')
                    }
                case "stop":
                    CFTestStop("annulé")
            }
            return
        }
        if cmd = "storage" && parts.Length >= 2 {
            CFOpenStorageFolder(parts[2])
            return
        }
        if cmd = "uninstall" && parts.Length >= 2 {
            CFStartUninstall(parts[2])
            return
        }
        if cmd = "shortcuts" && parts.Length >= 2 {
            if parts[2] = "status" {
                CFSendShortcutStatus()
                return
            }
            if parts.Length < 3
                return
            try {
                CFShortcutChange(parts[2], parts[3])
                CFSendShortcutStatus()
            } catch as err {
                CFSendShortcutStatus(err.Message)
            }
            return
        }
        if cmd = "view" && parts.Length >= 2 {
            compact := parts[2] = "compact"
            if compact != CF.compactMode {
                CFDesktopCaptureMainBounds(CF.compactMode)
                CF.compactMode := compact
                StopAll("Mode d'affichage changé.")
                ApplyWindowMode()
                SaveSettings()
            }
            SendState()
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
            try FileDelete(CFProfileFile(id))
            SelectProfileById(CF.profiles[1].id)
            return
        }
    } catch as err {
        SetNotice("Erreur de communication : " err.Message)
    }
}


CFApplyQuickSettings(id, mode, minimum, maximum, variation) {
    global CF
    if !RegExMatch(id, "^[1-9]\d{0,8}$")
        throw Error("Identifiant invalide.")
    profile := CFProfileById(id + 0)
    if !profile
        throw Error("Profil introuvable.")
    if !RegExMatch(minimum, "^\d{1,3}$") || !RegExMatch(maximum, "^\d{1,3}$")
        throw Error("Indique des CPS compris entre 1 et 100.")
    low := minimum + 0
    high := maximum + 0
    if low < 1 || high > 100 || high < low
        throw Error("La valeur maximale doit être supérieure ou égale au minimum.")
    if !HasValue(["fixed", "random", "natural"], mode)
        throw Error("Mode invalide.")
    if !HasValue(["low", "medium", "high"], variation)
        throw Error("Intensité invalide.")
    StopAll("Profil ajusté depuis le Test CPS.")
    profile.cfg.mode := mode = "fixed" ? 1 : mode = "random" ? 2 : 3
    profile.cfg.min := low
    profile.cfg.max := high
    profile.cfg.variation := variation = "low" ? 1 : variation = "medium" ? 2 : 3
    SaveSettings()
    SendState()
}

SameKey(a, b) {
    if a = b
        return true
    try {
        vka := GetKeyVK(a)
        return vka != 0 && vka = GetKeyVK(b)
    }
    return false
}

RegisterEmergency() {
    global CF
    if CF.emergencyKey != ""
        Hotkey("~*" CF.emergencyKey, EmergencyStop, "On")
}

UnregisterEmergency() {
    global CF
    if CF.emergencyKey != ""
        try Hotkey("~*" CF.emergencyKey, "Off")
}

CFSetEmergencyKey(key) {
    global CF
    if key = CF.emergencyKey {
        SendState()
        return
    }
    if key != "" {
        if key = "Escape" || key = "Esc" || key = "!" || !GetKeyVK(key)
            throw Error("Touche d'arrêt non prise en charge.")
        for profile in CF.profiles
            if SameKey(key, profile.cfg.activation)
                throw Error("Cette touche sert déjà à l'activation d'un profil.")
        for action in CFGlobalKeys()
            if CF.globalKeys.Get(action, "") != ""
                && SameKey(key, CF.globalKeys[action])
                throw Error("Cette touche sert déjà à un autre raccourci global.")
    }
    ; Un changement de raccourci n'est jamais appliqué en pleine rafale.
    StopAll("Modification de l'arrêt d'urgence.")
    previous := CF.emergencyKey
    UnregisterEmergency()
    CF.emergencyKey := key
    try RegisterEmergency()
    catch as err {
        CF.emergencyKey := previous
        try RegisterEmergency()
        throw err
    }
    SaveSettings()
    SendState()
    SetNotice(key = "" ? "Raccourci d'arrêt d'urgence désactivé."
        : "Arrêt d'urgence : " DisplayKey(key) ".")
}

ApplyWindowMode() {
    global CF
    if !CF.hwnd
        return
    CFDesktopRestoreMainBounds()
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

CFEngineSetTimer(active) {
    global CF
    active := !!active
    if active = CF.engineTimerActive
        return
    CF.engineTimerActive := active
    if active {
        ; Timer Windows haute resolution natif : pas d'arrondi SetTimer AHK
        ; ni de demande 1 ms globale, et utilisable en fenetre masquee.
        CF.precisionHandle := DllCall("Kernel32\CreateWaitableTimerExW",
            "Ptr", 0, "Ptr", 0, "UInt", 0x2, "UInt", 0x1F0003, "Ptr")
        if !CF.precisionHandle {
            ; Repli pour d'anciens Windows si ce timer n'est pas disponible.
            CF.precisionRequested := DllCall("Winmm\timeBeginPeriod", "UInt", 1, "UInt") = 0
        }
        if CF.precisionHandle || CF.precisionRequested
            SetTimer(CFEngineRun, -1)
        else
            SetTimer(EngineTick, 10)
    } else {
        SetTimer(CFEngineRun, 0)
        SetTimer(EngineTick, 0)
        if CF.precisionHandle {
            DllCall("Kernel32\CancelWaitableTimer", "Ptr", CF.precisionHandle)
            DllCall("Kernel32\CloseHandle", "Ptr", CF.precisionHandle)
            CF.precisionHandle := 0
        }
        if CF.precisionRequested {
            DllCall("Winmm\timeEndPeriod", "UInt", 1, "UInt")
            CF.precisionRequested := false
        }
    }
}

CFPrecisionSleep(milliseconds) {
    global CF
    milliseconds := Max(1, Min(8, milliseconds))
    if CF.precisionHandle {
        due := Buffer(8, 0)
        ; Une valeur negative exprime une echeance relative en tranches 100ns.
        NumPut("Int64", -milliseconds * 10000, due)
        if DllCall("Kernel32\SetWaitableTimerEx", "Ptr", CF.precisionHandle,
            "Ptr", due.Ptr, "Int", 0, "Ptr", 0, "Ptr", 0, "Ptr", 0,
            "UInt", 0, "Int") {
            ; Attente interruptible par les messages quand la souris est
            ; conditionnée : le hook Windows réveille le moteur sans polling.
            if CF.armed && CF.cfg.mouseGate && CF.gateHook && !CF.gateWakeSignal {
                handles := Buffer(A_PtrSize, 0)
                NumPut("Ptr", CF.precisionHandle, handles)
                DllCall("User32\MsgWaitForMultipleObjectsEx",
                    "UInt", 1, "Ptr", handles.Ptr, "UInt", 16,
                    "UInt", 0x04FF, "UInt", 0x0004, "UInt")
            } else {
                ; Timeout de sécurité : pas d'attente infinie.
                DllCall("Kernel32\WaitForSingleObject", "Ptr", CF.precisionHandle,
                    "UInt", 16, "UInt")
            }
            return
        }
    }
    if CF.armed && CF.cfg.mouseGate && CF.gateHook && !CF.gateWakeSignal
        DllCall("User32\MsgWaitForMultipleObjectsEx", "UInt", 0,
            "Ptr", 0, "UInt", milliseconds, "UInt", 0x04FF, "UInt", 0x0004, "UInt")
    else
        DllCall("Kernel32\Sleep", "UInt", milliseconds)
}

CFActivationRefreshPressed() {
    global CF
    ; La boucle haute précision peut retarder la notification "Up" AHK.
    ; En Basculer, lire aussi l'état physique pour ne pas bloquer le
    ; prochain appui lorsque cette notification a été manquée.
    if CF.cfg.hold = 2 && CF.pressed
        && !GetKeyState(CF.cfg.activation, "P")
        CF.pressed := false
}

CFEngineRun() {
    global CF
    if !CF.engineTimerActive || CF.engineLoopRunning
        return
    CF.engineLoopRunning := true
    try {
        while CF.engineTimerActive && !CF.shuttingDown {
            CFActivationRefreshPressed()
            EngineTick()
            if !CF.engineTimerActive
                break
            now := CFNowMs()
            if CF.test.active {
                untilNext := Min(CF.test.nextAt - now,
                    CF.test.started + CF.test.duration * 1000 - now)
            } else if CF.armed {
                untilNext := CF.nextAt - now
                if CF.cfg.mouseGate && !CF.gateWakeSignal
                    && !GetKeyState(CF.cfg.gateButton, "P")
                    untilNext := 8
            } else {
                break
            }
            ; Attente native, sans busy spin. Sleep(-1) rend les raccourcis,
            ; l'arret d'urgence et les messages WebView2 interruptibles.
            CFPrecisionSleep(untilNext - 1)
            Sleep(-1)
        }
    } finally {
        CF.engineLoopRunning := false
        if CF.engineTimerActive && !CF.shuttingDown
            SetTimer(CFEngineRun, -1)
    }
}

; Souris conditionnelle : le hook détecte l'appui physique et réveille
; la boucle d'attente sans injecter de clic depuis le callback Windows.
; Il n'est actif QUE pendant l'attente du bouton, pas au repos ni pendant
; les clics continus. La lecture physique reste un repli si hook absent.
; Les timestamps sont opt-in ; aucun chronométrage si diagnostic coupé.
CFDiagToggle(enabled) {
    global CF
    enabled := !!enabled
    if CF.diagnosticsEnabled = enabled
        return
    if CF.armed
        StopAll("Diagnostics modifiés : réactive ton profil pour mesurer.")
    CFGateProbeStop()
    CF.diagnosticsEnabled := enabled
    CF.firstDispatchMs := ""
    CF.firstDispatchKind := ""
    CF.gateDetectionMs := ""
    CF.gateProbeStatus := ""
    CF.gateEventDelayMs := ""
    CF.gateEventAverageMs := ""
    CF.gateEventSamples := []
    SendStats()
}

CFGateTrackEvent(msg, mouseData, flags, eventTime) {
    global CF
    if !CF.armed || !CF.cfg.mouseGate || (flags & 0x3)
        return
    gate := CF.cfg.gateButton
    down := gate = "LButton" && msg = 0x201
        || gate = "RButton" && msg = 0x204
        || gate = "MButton" && msg = 0x207
    up := gate = "LButton" && msg = 0x202
        || gate = "RButton" && msg = 0x205
        || gate = "MButton" && msg = 0x208
    if !down && !up && (gate = "XButton1" || gate = "XButton2")
        && (msg = 0x20B || msg = 0x20C) {
        xButton := (mouseData >> 16) & 0xFFFF
        if xButton = (gate = "XButton1" ? 1 : 2) {
            down := msg = 0x20B
            up := msg = 0x20C
        }
    }
    if up {
        CF.gateWakeSignal := false
    } else if down {
        CF.gateWakeSignal := true
        if CF.gateProbePending && !CF.gateProbeQpc {
            CF.gateEventUptime := eventTime
            CF.gateProbeQpc := CFPerfCounter()
        }
    }
}

CFGateProbeProc(code, msg, data) {
    global CF
    if code >= 0 && data && CF.armed && CF.cfg.mouseGate
        CFGateTrackEvent(msg, NumGet(data, 8, "UInt"),
            NumGet(data, 12, "UInt"), NumGet(data, 16, "UInt"))
    return DllCall("User32\CallNextHookEx", "Ptr", CF.gateHook,
        "Int", code, "UPtr", msg, "Ptr", data, "Ptr")
}

CFGateProbeStart() {
    global CF
    if !CF.armed || !CF.cfg.mouseGate || CF.mouseDetectionMode = "classic"
        || CF.gateHook || CF.gateHookFailed
        return
    CF.gateWakeSignal := false
    CF.gateProbePending := CF.diagnosticsEnabled && CF.firstDispatchMs = ""
    CF.gateProbeQpc := 0
    CF.gateEventUptime := 0
    if CF.gateProbePending
        CF.gateProbeStatus := "waiting"
    callback := CallbackCreate(CFGateProbeProc, "Fast", 3)
    hook := DllCall("User32\SetWindowsHookExW", "Int", 14,
        "Ptr", callback, "Ptr", 0, "UInt", 0, "Ptr")
    if hook {
        CF.gateHookCallback := callback
        CF.gateHook := hook
    } else {
        CF.gateHookFailed := true
        CF.gateProbePending := false
        if CF.diagnosticsEnabled && CF.firstDispatchMs = ""
            CF.gateProbeStatus := "unavailable"
        CallbackFree(callback)
    }
}

CFGateProbeStop() {
    global CF
    CF.gateProbePending := false
    CF.gateWakeSignal := false
    if CF.gateHook {
        DllCall("User32\UnhookWindowsHookEx", "Ptr", CF.gateHook, "Int")
        CF.gateHook := 0
    }
    if CF.gateHookCallback {
        CallbackFree(CF.gateHookCallback)
        CF.gateHookCallback := 0
    }
}

CFPerfCounter() {
    ticks := 0
    DllCall("Kernel32\QueryPerformanceCounter", "Int64*", &ticks, "Int")
    return ticks
}

CFNowMs() {
    global CF
    if !CF.qpcFrequency {
        frequency := 0
        DllCall("Kernel32\QueryPerformanceFrequency", "Int64*", &frequency, "Int")
        if frequency <= 0
            throw Error("Horloge haute resolution Windows indisponible.")
        CF.qpcFrequency := frequency
    }
    return 1000.0 * CFPerfCounter() / CF.qpcFrequency
}

CFStatsSetTimer(active) {
    global CF
    active := !!active
    if active = CF.statsTimerActive
        return
    CF.statsTimerActive := active
    ; Statistiques : 200 ms en activité et 1000 ms au repos.
    SetTimer(UpdateStats, active ? 200 : 1000)
}

ActivationDown(*) {
    global CF
    activationStarted := CF.diagnosticsEnabled ? CFPerfCounter() : 0
    if CF.capture || CF.pressed || CF.test.active
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
    CF.activationCounter := activationStarted
    CF.firstDispatchMs := ""
    CF.firstDispatchKind := ""
    CF.gateDetectionMs := ""
    CF.gateEventDelayMs := ""
    CF.gateProbeStatus := ""
    CF.gateHookFailed := false
    CF.gateWakeSignal := false
    CF.gateWaiting := false
    CF.gateMethodCurrent := "inactive"
    CF.gateMethodLast := "none"
    CF.overlayStart := A_TickCount
    CF.overlayUntil := 0
    CF.overlayRecent := []
    CF.target := current
    CF.nextAt := CFNowMs()
    CFNaturalReset(CF.cfg)
    ; Premier clic : exécuté dans le callback de la touche lui-même.
    ; EngineTick calcule et programme nextAt pour le clic suivant :
    ; aucun clic double au lancement du cadenceur précis.
    EngineTick(true)
    ; La condition souris installe elle-même son hook d'attente dans
    ; EngineTick. Pas de hook si le bouton est déjà tenu au départ.
    ; Montrer l'overlay pendant que la touche d'activation est encore
    ; traitée, avant que le cadenceur haute précision prenne la main.
    CFDesktopUpdate()
    if CF.armed {
        CFStatsSetTimer(true)
        CFEngineSetTimer(true)
    }
    SetNotice(CF.emergencyKey != ""
        ? "Clics actifs. " DisplayKey(CF.emergencyKey) " pour arrêter."
        : "Clics actifs. Pour arrêter, utilise ClickFlow ou la zone de notification.")
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
    StopAll(CF.emergencyKey != ""
        ? "Arrêt d'urgence (" DisplayKey(CF.emergencyKey) ")."
        : "Arrêt demandé depuis l'interface.")
}

StopAll(message) {
    global CF
    wasArmed := CF.armed
    CFTestStop(message)
    CF.armed := false
    CF.gateWaiting := false
    CF.gateMethodCurrent := "inactive"
    CFGateProbeStop()
    CFEngineSetTimer(false)
    CFStatsSetTimer(false)
    if wasArmed {
        CF.overlayUntil := A_TickCount + 2200
        ; Avec les statistiques au repos à 1 Hz, garder néanmoins
        ; l'extinction visuelle de l'overlay à environ 2,2 secondes.
        if CF.floatShown && !CF.overlayAlwaysVisible
            SetTimer(CFDesktopUpdate, -2300)
    }
    CF.overlayRecent := []
    CF.overlayStart := 0
    CF.target := 0
    CF.nextAt := 0
    CF.cpsNow := 0
    SetNotice(message)
    CFDesktopUpdate()
}

SetNotice(message) {
    global CF
    CF.notice := message
    SendStats()
}

EngineTick(firstFromActivation := false) {
    global CF
    if CF.test.active {
        CFTestTick()
        return
    }
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
    ; L'événement ActivationDown prouve déjà que la touche vient d'être
    ; pressée. Éviter une lecture de l'état physique trop tôt pour le
    ; premier clic en mode Maintenir. Dès le tick suivant, contrôle normal.
    if CF.cfg.hold = 1 && !firstFromActivation
        && !GetKeyState(CF.cfg.activation, "P") {
        StopAll("Arrêt : touche d'activation relâchée.")
        return
    }
    if CF.cfg.mouseGate && !CF.gateWakeSignal
        && !GetKeyState(CF.cfg.gateButton, "P") {
        CF.gateWaiting := true
        CF.cpsNow := 0
        CF.nextAt := CFNowMs()
        if CF.mouseDetectionMode = "classic"
            CF.gateMethodCurrent := "classic"
        else {
            CFGateProbeStart()
            CF.gateMethodCurrent := CF.gateHook ? "event"
                : CF.gateHookFailed ? (CF.mouseDetectionMode = "auto"
                    ? "fallback" : "unavailable") : "event"
        }
        return
    }

    now := CFNowMs()
    if CF.cfg.mouseGate {
        if CF.gateWaiting {
            ; En mode événementiel forcé, ne jamais passer silencieusement
            ; sur la méthode classique : si le hook échoue, rester en attente.
            if CF.mouseDetectionMode = "event" && !CF.gateWakeSignal {
                CF.gateMethodCurrent := CF.gateHookFailed ? "unavailable" : "event"
                return
            }
            ; En Auto, distinguer le vrai réveil hook et le contrôle
            ; physique de secours, même si un hook était installé.
            CF.gateMethodLast := CF.mouseDetectionMode = "classic" ? "classic"
                : CF.gateWakeSignal ? "event" : "fallback"
            CF.gateMethodCurrent := CF.gateMethodLast
            CF.gateWaiting := false
            CF.nextAt := now
        } else if CF.gateMethodLast = "none" {
            ; Bouton déjà maintenu lors du lancement : aucune attente.
            CF.gateMethodLast := "already-held"
            CF.gateMethodCurrent := "already-held"
        }
    } else {
        CF.gateMethodCurrent := "disabled"
    }
    if now < CF.nextAt
        return
    intervalMs := GetNextIntervalMs(CF.cfg, now)
    CF.cpsNow := 1000 / intervalMs

    ; Les clics sont envoyes a la position actuelle du curseur.
    ; SendInput n'intercepte pas les clics manuels et n'injecte rien dans le jeu.
    ; Mesurer une seule fois le premier clic réellement envoyé, même si
    ; la condition souris a retardé son émission après l'activation.
    firstClick := CF.diagnosticsEnabled && CF.firstDispatchMs = ""
    measureStart := firstClick ? (firstFromActivation ? CF.activationCounter : CFPerfCounter()) : 0
    if firstClick && !firstFromActivation && (CF.cfg.mouseGate || CF.gateProbePending) {
        if CF.gateProbeQpc > 0 && CF.qpcFrequency > 0 && measureStart >= CF.gateProbeQpc {
            CF.gateDetectionMs := Round(1000.0 * (measureStart - CF.gateProbeQpc) / CF.qpcFrequency, 2)
            CF.gateProbeStatus := "measured"
            ; La structure MSLLHOOKSTRUCT contient aussi le temps de
            ; l'événement Windows. Il peut être quantifié à ~15,6ms.
            ; À utiliser comme ESTIMATION et non comme mesure exacte.
            uptime := DllCall("Kernel32\GetTickCount64", "UInt64")
            eventDelay := (uptime - CF.gateEventUptime) & 0xFFFFFFFF
            if eventDelay <= 1000 {
                CF.gateEventDelayMs := eventDelay
                CF.gateEventSamples.Push(eventDelay)
                if CF.gateEventSamples.Length > 10
                    CF.gateEventSamples.RemoveAt(1)
                sumDelay := 0
                for sample in CF.gateEventSamples
                    sumDelay += sample
                CF.gateEventAverageMs := Round(sumDelay / CF.gateEventSamples.Length, 1)
            }
        } else if CF.gateProbeStatus != "unavailable"
            CF.gateProbeStatus := "unobserved"
    }
    SendInput("{Click " CF.cfg.clickButton "}")
    if firstClick && CF.qpcFrequency > 0 {
        CF.firstDispatchMs := Round(1000.0 * (CFPerfCounter() - measureStart) / CF.qpcFrequency, 2)
        CF.firstDispatchKind := firstFromActivation ? "activation" : "condition"
        if firstFromActivation && CF.cfg.mouseGate
            CF.gateProbeStatus := "already-held"
    }
    if CF.gateHook
        CFGateProbeStop() ; ne surveiller que pendant l'attente physique
    CF.total += 1
    CF.recent.Push(now)
    if CF.floatShown
        CF.overlayRecent.Push(A_TickCount) ; l'overlay reste sur son horloge historique
    ; Evite les rafales de rattrapage apres une interruption.
    CF.nextAt := now + intervalMs
}

; Un état de cadence par session : reset à chaque activation ou banc de test.
; Les valeurs de CPS minimum/maximum définissent la plage de cadence normale.
; Les micro-hésitations peuvent allonger ponctuellement l'intervalle.
CFNaturalReset(cfg) {
    global CF
    CF.naturalCps := (cfg.min + cfg.max) / 2
    CF.naturalTarget := CF.naturalCps
    CF.nextVariation := 0
    CF.naturalNoise := 0
    CF.naturalBurstLeft := 0
}

; Cadence cible à évolution progressive. Le niveau faible de la v1.5
; utilise déjà presque toute la plage CPS (ancien niveau élevé).
GetNextCps(cfg := 0, now := "") {
    global CF
    if !IsObject(cfg)
        cfg := CF.cfg
    if now = ""
        now := CFNowMs()
    minimum := cfg.min
    maximum := cfg.max
    if cfg.mode = 1
        return minimum
    if cfg.mode = 2
        return Random(minimum, maximum)

    intensity := Max(1, Min(3, cfg.variation))
    if now >= CF.nextVariation {
        center := (minimum + maximum) / 2
        radius := (maximum - minimum) * (intensity = 1 ? 0.46 : 0.5)
        low := Max(minimum, center - radius)
        high := Min(maximum, center + radius)
        ; Les intensités fortes visitent plus souvent les extrêmes.
        edgeChance := intensity = 1 ? 16 : intensity = 2 ? 29 : 43
        if Random(1, 100) <= edgeChance
            CF.naturalTarget := Random(0, 1) ? maximum : minimum
        else
            CF.naturalTarget := Random(low, high)
        CF.nextVariation := now + (intensity = 1
            ? Random(550, 1500)
            : intensity = 2 ? Random(380, 1200) : Random(250, 900))
    }
    smoothing := intensity = 1 ? 0.25 : intensity = 2 ? 0.36 : 0.52
    CF.naturalCps += (CF.naturalTarget - CF.naturalCps) * smoothing
    return Max(minimum, Min(maximum, CF.naturalCps))
}

; Le même intervalle est utilisé par le moteur SendInput et le banc de
; test CPS. Le mode Fixe et le mode Aléatoire restent inchangés.
GetNextIntervalMs(cfg := 0, now := "") {
    global CF
    if !IsObject(cfg)
        cfg := CF.cfg
    if now = ""
        now := CFNowMs()
    cps := GetNextCps(cfg, now)
    if cfg.mode != 3
        return Max(10, Round(1000 / cps))

    intensity := Max(1, Min(3, cfg.variation))
    ; Bruit partiellement corrélé : les clics voisins ne sont pas
    ; parfaitement indépendants, mais gardent des imperfections.
    CF.naturalNoise := 0.28 * CF.naturalNoise
        + 0.72 * Random(-1.0, 1.0)
    jitter := intensity = 1 ? 0.11 : intensity = 2 ? 0.21 : 0.34
    interval := (1000 / cps) * (1 + jitter * CF.naturalNoise)

    ; Très courte accélération spontanée sur quelques clics.
    burstChance := intensity = 1 ? 45 : intensity = 2 ? 140 : 280
    if CF.naturalBurstLeft > 0 {
        CF.naturalBurstLeft -= 1
        interval *= intensity = 1 ? 0.95 : intensity = 2 ? 0.87 : 0.79
    } else if Random(1, 10000) <= burstChance {
        CF.naturalBurstLeft := Random(1, intensity = 1 ? 2 : 3)
        interval *= intensity = 1 ? 0.95 : intensity = 2 ? 0.87 : 0.79
    }

    ; Hors hésitations, aucun intervalle ne sort de la plage CPS prévue.
    shortest := Max(10, Ceil(1000 / cfg.max))
    longest := Max(shortest, Ceil(1000 / cfg.min))
    interval := Max(shortest, Min(longest, Round(interval)))

    ; Imperfection rare : un retard isolé, jamais rattrapé en rafale.
    hesitationChance := intensity = 1 ? 55 : intensity = 2 ? 160 : 300
    if Random(1, 10000) <= hesitationChance {
        factor := intensity = 1 ? Random(1.18, 1.42)
            : intensity = 2 ? Random(1.3, 1.85) : Random(1.5, 2.25)
        interval := Round(interval * factor)
    }
    return Max(10, interval)
}

UpdateStats() {
    global CF
    now := CFNowMs()
    while CF.recent.Length && CF.recent[1] < now - 1000
        CF.recent.RemoveAt(1)
    windowStart := A_TickCount - CF.overlayAverageSeconds * 1000
    while CF.overlayRecent.Length && CF.overlayRecent[1] < windowStart
        CF.overlayRecent.RemoveAt(1)
    SendStats()
    CFDesktopUpdate()
}

CFWebShortcutBegin(action) {
    global CF
    if action != "emergency" && !HasValue(CFGlobalKeys(), action)
        throw Error("Action globale inconnue.")
    if CF.capture
        FinishCapture("")
    StopAll("Choix du raccourci global.")
    ; Seule l'interface WebView2 écoute les touches pendant la capture.
    ; On désactive temporairement les hotkeys Windows (y compris F12).
    CF.capture := true
    CF.captureKind := action = "emergency" ? "emergency" : "global:" action
    CF.inputHook := 0
    UnregisterActivation()
    UnregisterEmergency()
    CFGlobalUnregister()
    SendStats()
    SetNotice("Appuie sur une touche dans ClickFlow ou Échap pour annuler.")
}

CFWebShortcutFinish(action, key) {
    global CF
    expected := action = "emergency" ? "emergency" : "global:" action
    if !CF.capture || CF.captureKind != expected
        throw Error("Aucune capture en cours pour cette action.")
    ; Le client envoie un code virtuel Windows (vkNN) ou un nom AHK.
    ; Pas de touche vide par erreur : utiliser le bouton Aucun.
    if key = "" || StrLen(key) > 32 || !GetKeyVK(key)
        throw Error("Touche non reconnue par Windows.")
    if key = "Escape" || key = "Esc"
        throw Error("Échap est réservé à l'annulation.")
    FinishCapture(key)
}

StartCapture(kind := "activation") {
    global CF
    StopAll("Sélection de la touche...")
    if CF.capture
        FinishCapture("")
    CF.capture := true
    CF.captureKind := kind
    ; Suspendre tous les raccourcis pendant la capture, puis les restaurer.
    UnregisterActivation()
    UnregisterEmergency()
    CFGlobalUnregister()
    SendStats()
    ih := InputHook("V")
    ih.KeyOpt("{All}", "N")
    ih.OnKeyDown := CapturedKey
    CF.inputHook := ih
    for mouseKey in ["LButton", "RButton", "MButton", "XButton1", "XButton2"]
        Hotkey("~*" mouseKey, CapturedMouse.Bind(mouseKey), "On")
    ih.Start()
    SetNotice(kind = "emergency"
        ? "Appuie sur la nouvelle touche d'arrêt d'urgence (Échap annule)."
        : "Appuie sur la touche d'activation (Échap annule).")
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
    kind := CF.captureKind
    try CF.inputHook.Stop()
    CF.inputHook := 0
    for mouseKey in ["LButton", "RButton", "MButton", "XButton1", "XButton2"]
        try Hotkey("~*" mouseKey, "Off")

    isGlobal := SubStr(kind, 1, 7) = "global:"
    action := isGlobal ? SubStr(kind, 8) : ""
    if isGlobal && !HasValue(CFGlobalKeys(), action)
        key := ""
    previous := isGlobal ? CF.globalKeys.Get(action, "")
        : kind = "emergency" ? CF.emergencyKey : CF.cfg.activation
    rejected := false
    if key != "" {
        if isGlobal
            rejected := CFGlobalConflicts(key, action)
        else if kind = "emergency" {
            for p in CF.profiles
                if SameKey(key, p.cfg.activation)
                    rejected := true
            for globalAction in CFGlobalKeys()
                if CF.globalKeys[globalAction] != "" && SameKey(key, CF.globalKeys[globalAction])
                    rejected := true
        } else {
            rejected := SameKey(key, CF.emergencyKey)
            for globalAction in CFGlobalKeys()
                if CF.globalKeys[globalAction] != "" && SameKey(key, CF.globalKeys[globalAction])
                    rejected := true
        }
    }
    if rejected
        key := ""
    if key != "" {
        if isGlobal
            CF.globalKeys[action] := key
        else if kind = "emergency"
            CF.emergencyKey := key
        else
            CF.cfg.activation := key
    }
    try {
        RegisterEmergency()
        RegisterActivation()
        CFGlobalRegister()
    } catch as err {
        try UnregisterActivation()
        try UnregisterEmergency()
        CFGlobalUnregister()
        if isGlobal
            CF.globalKeys[action] := previous
        else if kind = "emergency"
            CF.emergencyKey := previous
        else
            CF.cfg.activation := previous
        try RegisterEmergency()
        try RegisterActivation()
        try CFGlobalRegister()
        SetNotice("Touche non prise en charge : " err.Message)
        key := ""
    }
    CF.pressed := false
    SendState()
    SaveSettings()
    if rejected
        SetNotice("Touche déjà utilisée : choisis un autre raccourci.")
    else if key != ""
        SetNotice((isGlobal ? CFGlobalKeyLabel(action)
            : kind = "emergency" ? "Arrêt d'urgence" : "Activation")
            " : " DisplayKey(key) ".")
    else
        SetNotice("Capture annulée. Raccourci conservé.")
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
    global CF
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
    if cfg.activation = "" || cfg.activation = "!" || SameKey(cfg.activation, CF.emergencyKey)
        cfg.activation := SameKey(CF.emergencyKey, "F6") ? "F7" : "F6"
    return cfg
}

LoadSettings() {
    global CF
    if CFLoadSeparatedProfiles()
        return
    ; Migration des profils v1.1 (la sauvegarde normale produit les fichiers).
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
        DirCreate(RegExReplace(CF.configFile, "\\[^\\]+$"))
        DirCreate(CF.profilesDir)
        ids := ""
        for p in CF.profiles {
            CFWriteProfile(p)
            ids .= (ids = "" ? "" : ",") p.id
        }
        IniWrite(ids, CF.configFile, "Profiles", "Ids")
        IniWrite("2", CF.configFile, "Profiles", "StorageVersion")
        IniWrite(CF.selectedId, CF.configFile, "Profiles", "Selected")
        IniWrite(CF.nextId, CF.configFile, "Profiles", "NextId")
        IniWrite(CF.emergencyKey, CF.configFile, "General", "EmergencyKey")
        for action in CFGlobalKeys()
            IniWrite(CF.globalKeys.Get(action, ""), CF.configFile,
                "General", CFGlobalIniKey(action))
        IniWrite(CF.compactMode ? 1 : 0, CF.configFile, "General", "CompactMode")
        IniWrite(CF.closeToTray ? 1 : 0, CF.configFile, "General", "CloseToTray")
        IniWrite(CF.minimizeToTray ? 1 : 0, CF.configFile, "General", "MinimizeToTray")
        IniWrite(CF.floatShown ? 1 : 0, CF.configFile, "General", "FloatShown")
        IniWrite(CF.liveMonitor ? 1 : 0, CF.configFile, "General", "LiveMonitor")
        IniWrite(CF.diagnosticsEnabled ? 1 : 0, CF.configFile, "General", "DiagnosticsEnabled")
        IniWrite(CF.mouseDetectionMode, CF.configFile, "General", "MouseDetectionMode")
        IniWrite(CF.compactChart ? 1 : 0, CF.configFile, "General", "CompactChart")
        IniWrite(CF.floatShown ? 1 : 0, CF.configFile, "General", "OverlayEnabled")
        IniWrite(CF.overlayAlwaysVisible ? 1 : 0, CF.configFile, "General", "OverlayAlwaysVisible")
        IniWrite(CF.overlayOpacity, CF.configFile, "General", "OverlayOpacity")
        IniWrite(CF.overlayMargin, CF.configFile, "General", "OverlayMargin")
        IniWrite(CF.overlayAverageSeconds, CF.configFile, "General", "OverlayAverageSeconds")
        IniWrite(CF.overlaySize, CF.configFile, "General", "OverlaySize")
        IniWrite(CF.overlayShowProfile ? 1 : 0, CF.configFile, "General", "OverlayShowProfile")
        IniWrite(CF.overlayMonitor, CF.configFile, "General", "OverlayMonitor")
        IniWrite(CF.overlayPosition, CF.configFile, "General", "OverlayPosition")
        IniWrite(CF.overlayX, CF.configFile, "General", "OverlayX")
        IniWrite(CF.overlayY, CF.configFile, "General", "OverlayY")
        IniWrite(CF.mainExpandedW, CF.configFile, "General", "MainExpandedWidth")
        IniWrite(CF.mainExpandedH, CF.configFile, "General", "MainExpandedHeight")
        IniWrite(CF.mainCompactW, CF.configFile, "General", "MainCompactWidth")
        IniWrite(CF.mainCompactH, CF.configFile, "General", "MainCompactHeight")
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
