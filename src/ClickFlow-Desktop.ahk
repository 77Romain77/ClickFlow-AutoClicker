; ClickFlow v1.6 - intégration Windows : notification, mini-fenêtre, préférences.
; Pas de fichier de scores. La fermeture par défaut quitte toujours ClickFlow.
CFDesktopReadPreferences() {
    global CF
    CF.closeToTray := IniRead(CF.configFile, "General", "CloseToTray", "0") = "1"
    CF.minimizeToTray := IniRead(CF.configFile, "General", "MinimizeToTray", "0") = "1"
    CF.floatShown := IniRead(CF.configFile, "General", "FloatShown", "0") = "1"
    CF.liveMonitor := IniRead(CF.configFile, "General", "LiveMonitor", "1") != "0"
}

CFDesktopPreferencesJson() {
    global CF
    return '{"closeToTray":' (CF.closeToTray ? "true" : "false") ',"minimizeToTray":' (CF.minimizeToTray ? "true" : "false") ',"floatShown":' (CF.floatShown ? "true" : "false") ',"liveMonitor":' (CF.liveMonitor ? "true" : "false") '}'
}

CFDesktopInit() {
    global CF
    ; Remplace les items AHK par un menu de notification ClickFlow.
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Ouvrir ClickFlow", CFDesktopOpen)
    A_TrayMenu.Default := "Ouvrir ClickFlow"
    A_TrayMenu.Add("Arrêter les clics", CFDesktopStop)
    A_TrayMenu.Add("Afficher la mini-fenêtre", CFDesktopToggleFloat)
    A_TrayMenu.Add()
    CF.trayProfiles := Menu()
    A_TrayMenu.Add("Choisir un profil", CF.trayProfiles)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Quitter ClickFlow", CFDesktopQuit)
    CF.desktopReady := true
    CFDesktopRebuildProfiles()
    if CF.floatShown
        CFDesktopSetFloat(true, false)
    CFDesktopUpdate()
}

CFDesktopOpen(*) {
    global CF
    if !CF.hwnd
        return
    DetectHiddenWindows(true)
    try WinShow("ahk_id " CF.hwnd)
    try WinRestore("ahk_id " CF.hwnd)
    try WinActivate("ahk_id " CF.hwnd)
    DetectHiddenWindows(false)
}

CFDesktopHide(*) {
    global CF
    if CF.hwnd
        try WinHide("ahk_id " CF.hwnd)
}

CFDesktopStop(*) {
    StopAll("Arrêt demandé depuis la zone de notification.")
}

CFDesktopQuit(*) {
    global CF
    CF.forceExit := true
    ; Le gestionnaire de fermeture libère WebView2 proprement.
    if CF.hwnd {
        try DllCall("User32\PostMessageW", "Ptr", CF.hwnd,
            "UInt", 0x10, "Ptr", 0, "Ptr", 0)
    } else {
        ExitApp()
    }
}

CFDesktopSelectProfile(id, *) {
    SelectProfileById(id)
    CFDesktopUpdate()
}

CFDesktopRebuildProfiles() {
    global CF
    if !CF.desktopReady
        return
    try CF.trayProfiles.Delete()
    for p in CF.profiles {
        label := "Profil " p.id " - " p.name
        CF.trayProfiles.Add(label, CFDesktopSelectProfile.Bind(p.id))
        if p.id = CF.selectedId
            CF.trayProfiles.Check(label)
    }
}

CFDesktopCreateFloat() {
    global CF
    if IsObject(CF.floatGui)
        return
    mini := Gui("+AlwaysOnTop +ToolWindow", "ClickFlow - Mini")
    mini.MarginX := 12
    mini.MarginY := 10
    mini.BackColor := "142136"
    mini.SetFont("s10 cF0F5FF", "Segoe UI")
    CF.floatProfile := mini.Add("Text", "xm ym w218 h23", "Profil : Principal")
    mini.SetFont("s9 cA6C5E1", "Segoe UI")
    CF.floatStatus := mini.Add("Text", "xm y+4 w218 h20", "Prêt")
    mini.SetFont("s11 cFFFFFF bold", "Segoe UI")
    CF.floatCps := mini.Add("Text", "xm y+4 w218 h24", "0 CPS")
    mini.SetFont("s9 norm", "Segoe UI")
    mini.Add("Button", "xm y+8 w105 h30", "Ouvrir").OnEvent("Click", CFDesktopOpen)
    mini.Add("Button", "x+8 yp w105 h30", "STOP").OnEvent("Click", CFDesktopStop)
    mini.OnEvent("Close", CFDesktopCloseFloat)
    CF.floatGui := gui
}

CFDesktopCloseFloat(*) {
    CFDesktopSetFloat(false)
    return true
}

CFDesktopSetFloat(visible, persist := true) {
    global CF
    CF.floatShown := !!visible
    if CF.desktopReady {
        if CF.floatShown {
            CFDesktopCreateFloat()
            CF.floatGui.Show("NA w242 h165")
            CFDesktopUpdate()
        } else if IsObject(CF.floatGui)
            CF.floatGui.Hide()
        if CF.floatShown {
            try A_TrayMenu.Check("Afficher la mini-fenêtre")
        } else {
            try A_TrayMenu.Uncheck("Afficher la mini-fenêtre")
        }
    }
    if persist {
        SaveSettings()
        SendState()
    }
}

CFDesktopToggleFloat(*) {
    global CF
    CFDesktopSetFloat(!CF.floatShown)
}

CFDesktopSetPreference(field, value) {
    global CF
    enabled := value = "1"
    switch field {
        case "closeToTray":
            CF.closeToTray := enabled
        case "minimizeToTray":
            CF.minimizeToTray := enabled
        case "floatShown":
            CFDesktopSetFloat(enabled, false)
        case "liveMonitor":
            CF.liveMonitor := enabled
        default:
            return
    }
    SaveSettings()
    SendState()
}

CFDesktopUpdate() {
    global CF
    if !CF.desktopReady
        return
    status := CF.test.active ? "Test CPS en cours"
        : CF.armed ? (CF.cfg.mouseGate
            && !GetKeyState(CF.cfg.gateButton, "P") ? "En attente" : "Clics actifs")
        : "Prêt"
    p := CFProfileById(CF.selectedId)
    name := IsObject(p) ? p.name : "Principal"
    try A_IconTip := "ClickFlow - " status " - " name
    if CF.floatShown && IsObject(CF.floatGui) {
        CF.floatProfile.Text := "Profil : " name
        CF.floatStatus.Text := status
        CF.floatCps.Text := CF.recent.Length " CPS - " CF.total " clics"
    }
}
