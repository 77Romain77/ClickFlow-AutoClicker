; ClickFlow v1.8.0 - Tray Windows et overlay d'état léger.
; Pas de WebView2 secondaire, de courbe GDI, ni d'historique disque.
CFDesktopInt(value, fallback, minimum, maximum) {
    if !RegExMatch(String(value), "^-?\d{1,7}$")
        return fallback
    return Max(minimum, Min(maximum, value + 0))
}

CFDesktopReadPreferences() {
    global CF
    file := CF.configFile
    CF.closeToTray := IniRead(file, "General", "CloseToTray", "0") = "1"
    CF.minimizeToTray := IniRead(file, "General", "MinimizeToTray", "0") = "1"
    ; Compatibilité avec l'ancienne option mini-fenêtre.
    CF.floatShown := IniRead(file, "General", "OverlayEnabled",
        IniRead(file, "General", "FloatShown", "0")) = "1"
    CF.liveMonitor := IniRead(file, "General", "LiveMonitor", "1") != "0"
    CF.compactChart := IniRead(file, "General", "CompactChart", "1") != "0"
    CF.overlayAlwaysVisible := IniRead(file, "General", "OverlayAlwaysVisible", "0") = "1"
    CF.overlayOpacity := CFDesktopInt(IniRead(file, "General",
        "OverlayOpacity", "85"), 85, 0, 100)
    CF.overlayMargin := CFDesktopInt(IniRead(file, "General",
        "OverlayMargin", "20"), 20, 0, 100)
    CF.overlayMonitor := CFDesktopInt(IniRead(file, "General",
        "OverlayMonitor", "1"), 1, 1, Max(1, MonitorGetCount()))
    pos := IniRead(file, "General", "OverlayPosition", "tm")
    CF.overlayPosition := HasValue(["tl", "tm", "tr", "bl", "bm", "br", "custom"],
        pos) ? pos : "tm"
    CF.overlayX := CFDesktopInt(IniRead(file, "General",
        "OverlayX", "-99999"), -99999, -30000, 30000)
    CF.overlayY := CFDesktopInt(IniRead(file, "General",
        "OverlayY", "-99999"), -99999, -30000, 30000)
    CF.overlayEditing := false
    CF.overlayVisible := false
    CF.overlayGui := 0
    CF.overlayUntil := 0
    CF.overlayRecent := []
    CF.overlayStart := 0
}

CFDesktopPreferencesJson() {
    global CF
    return '{"closeToTray":' (CF.closeToTray ? "true" : "false")
        . ',"minimizeToTray":' (CF.minimizeToTray ? "true" : "false")
        . ',"floatShown":' (CF.floatShown ? "true" : "false")
        . ',"liveMonitor":' (CF.liveMonitor ? "true" : "false")
        . ',"compactChart":' (CF.compactChart ? "true" : "false")
        . ',"overlayAlwaysVisible":' (CF.overlayAlwaysVisible ? "true" : "false")
        . ',"overlayOpacity":' CF.overlayOpacity
        . ',"overlayMargin":' CF.overlayMargin
        . ',"overlayMonitor":' CF.overlayMonitor
        . ',"overlayMonitorCount":' Max(1, MonitorGetCount())
        . ',"overlayPosition":' JsonQuote(CF.overlayPosition)
        . ',"overlayEditing":' (CF.overlayEditing ? "true" : "false") '}'
}

CFDesktopInit() {
    global CF
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Ouvrir l'interface", CFDesktopOpen)
    A_TrayMenu.Default := "Ouvrir l'interface"
    A_TrayMenu.Add("Arrêter les clics", CFDesktopStop)
    A_TrayMenu.Add("Activer l'overlay", CFDesktopToggleFloat)
    A_TrayMenu.Add()
    CF.trayProfiles := Menu()
    A_TrayMenu.Add("Choisir un profil", CF.trayProfiles)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Quitter ClickFlow", CFDesktopQuit)
    CF.desktopReady := true
    OnMessage(0x201, CFOverlayStartDrag)
    OnMessage(0x232, CFDesktopExitSizeMove)
    CFDesktopRebuildProfiles()
    CFDesktopSetFloat(CF.floatShown, false)
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
    if CF.hwnd {
        try DllCall("User32\PostMessageW", "Ptr", CF.hwnd,
            "UInt", 0x10, "Ptr", 0, "Ptr", 0)
    } else
        ExitApp()
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
    for profile in CF.profiles {
        label := StrReplace(profile.name, "&", "&&")
        CF.trayProfiles.Add(label, CFDesktopSelectProfile.Bind(profile.id))
        if profile.id = CF.selectedId
            CF.trayProfiles.Check(label)
    }
}

CFDesktopCaptureMainBounds(compact := "") {
    global CF
    if !CF.hwnd || CF.loading || CF.shuttingDown
        return
    try {
        if WinGetMinMax("ahk_id " CF.hwnd) != 0
            return
        WinGetPos(, , &w, &h, "ahk_id " CF.hwnd)
        if w < 460 || h < 450
            return
        if compact = ""
            compact := CF.compactMode
        if compact {
            CF.mainCompactW := w
            CF.mainCompactH := h
        } else {
            CF.mainExpandedW := w
            CF.mainExpandedH := h
        }
    }
}

CFDesktopMonitorArea(index, &left, &top, &right, &bottom) {
    index := Max(1, Min(Max(1, MonitorGetCount()), index))
    MonitorGetWorkArea(index, &left, &top, &right, &bottom)
}

CFDesktopCenterMain(hwnd, width, height) {
    ; Toujours dans la surface utilisable de l'écran : fonctionne aussi
    ; après changement de résolution ou débranchement d'un moniteur.
    monitor := MonitorGetPrimary()
    try MouseGetPos(&mx, &my)
    Loop MonitorGetCount() {
        CFDesktopMonitorArea(A_Index, &l, &t, &rr, &bb)
        if mx >= l && mx < rr && my >= t && my < bb {
            monitor := A_Index
            break
        }
    }
    CFDesktopMonitorArea(monitor, &left, &top, &right, &bottom)
    w := Min(width, Max(460, right - left - 36))
    h := Min(height, Max(420, bottom - top - 36))
    x := left + Floor((right - left - w) / 2)
    y := top + Floor((bottom - top - h) / 2)
    WinMove(x, y, w, h, "ahk_id " hwnd)
    return {x: x, y: y, w: w, h: h, monitor: monitor}
}

CFDesktopRestoreMainBounds() {
    global CF
    if !CF.hwnd
        return
    w := CF.compactMode ? CF.mainCompactW : CF.mainExpandedW
    h := CF.compactMode ? CF.mainCompactH : CF.mainExpandedH
    CFDesktopCenterMain(CF.hwnd, w, h)
}

CFDesktopFloatPositionValid(x, y, width, height) {
    if x = -99999 || y = -99999
        return false
    Loop MonitorGetCount() {
        CFDesktopMonitorArea(A_Index, &left, &top, &right, &bottom)
        if x + width >= left + 60 && x <= right - 60
            && y + height >= top + 25 && y <= bottom - 25
            return true
    }
    return false
}

CFOverlayPositionCoords() {
    global CF
    width := 226, height := 48
    if CF.overlayPosition = "custom"
        && CFDesktopFloatPositionValid(CF.overlayX, CF.overlayY, width, height)
        return {x: CF.overlayX, y: CF.overlayY}
    CFDesktopMonitorArea(CF.overlayMonitor, &l, &t, &rr, &bb)
    margin := CF.overlayMargin
    h := SubStr(CF.overlayPosition, 2, 1)
    v := SubStr(CF.overlayPosition, 1, 1)
    x := h = "l" ? l + margin
        : h = "r" ? rr - width - margin
        : l + Floor((rr - l - width) / 2)
    y := v = "b" ? bb - height - margin : t + margin
    return {x: x, y: y}
}

CFOverlayCreate() {
    global CF
    if IsObject(CF.overlayGui)
        return
    gui := Gui("-Caption +ToolWindow +AlwaysOnTop +E0x20",
        "ClickFlow - Overlay")
    gui.MarginX := 0
    gui.MarginY := 0
    gui.BackColor := "121F32"
    gui.SetFont("s9 bold c9AE4D4", "Segoe UI")
    CF.overlayStatusText := gui.Add("Text",
        "x12 y11 w98 h25 +0x100 0x200", "ARRÊTÉ")
    gui.SetFont("s11 bold cEDF6FF", "Segoe UI")
    CF.overlayCpsText := gui.Add("Text",
        "x111 y7 w105 h31 Right 0x200 +0x100", "0,0 CPS")
    CF.overlayGui := gui
    gui.Show("NA Hide w226 h48")
    CFOverlayApplyTransparency()
}

CFOverlayApplyTransparency() {
    global CF
    if !IsObject(CF.overlayGui)
        return
    ; 0-100 %, sans palier : 0 = entièrement invisible.
    percent := CF.overlayEditing ? 100 : CF.overlayOpacity
    try WinSetTransparent(Round(percent * 255 / 100),
        "ahk_id " CF.overlayGui.Hwnd)
    try WinSetExStyle(CF.overlayEditing ? "-0x20" : "+0x20",
        "ahk_id " CF.overlayGui.Hwnd)
}

CFOverlayPlace() {
    global CF
    if !IsObject(CF.overlayGui)
        return
    pt := CFOverlayPositionCoords()
    WinMove(pt.x, pt.y, 226, 48, "ahk_id " CF.overlayGui.Hwnd)
}

CFOverlayShow(visible) {
    global CF
    if visible && !IsObject(CF.overlayGui)
        CFOverlayCreate()
    if CF.overlayVisible = !!visible
        return
    CF.overlayVisible := !!visible
    if visible {
        CFOverlayPlace()
        CF.overlayGui.Show("NA")
        CFOverlayApplyTransparency()
    } else if IsObject(CF.overlayGui)
        CF.overlayGui.Hide()
}

CFOverlayAverage(now) {
    global CF
    if !CF.armed || !CF.overlayRecent.Length
        return 0
    elapsed := Max(200, Min(5000, now - CF.overlayStart))
    return Round(CF.overlayRecent.Length * 1000 / elapsed, 1)
}

CFDesktopUpdate() {
    global CF
    if !CF.desktopReady
        return
    status := CF.armed ? (CF.cfg.mouseGate
        && !GetKeyState(CF.cfg.gateButton, "P") ? "EN ATTENTE" : "ACTIF")
        : "ARRÊTÉ"
    profile := CFProfileById(CF.selectedId)
    name := IsObject(profile) ? profile.name : "Principal"
    try A_IconTip := "ClickFlow - " status " - " name
    if !CF.floatShown {
        CFOverlayShow(false)
        return
    }
    now := A_TickCount
    show := CF.overlayEditing || CF.overlayAlwaysVisible
        || CF.armed || now < CF.overlayUntil
    CFOverlayShow(show)
    if !show
        return
    if !IsObject(CF.overlayGui)
        return
    if CF.overlayEditing
        status := "PLACEMENT"
    CF.overlayStatusText.Text := status
    CF.overlayStatusText.Opt(status = "ACTIF" ? "c9AE4D4"
        : status = "EN ATTENTE" ? "cF2D097"
        : status = "PLACEMENT" ? "c87BAFF" : "cABB9CE")
    CF.overlayCpsText.Text := StrReplace(
        Format("{:.1f}", CFOverlayAverage(now)), ".", ",") " CPS"
}

CFOverlaySaveLocation() {
    global CF
    if !IsObject(CF.overlayGui)
        return
    WinGetPos(&x, &y, , , "ahk_id " CF.overlayGui.Hwnd)
    CF.overlayX := x
    CF.overlayY := y
    CF.overlayPosition := "custom"
    ; Actualiser le moniteur choisi après déplacement entre écrans.
    Loop MonitorGetCount() {
        CFDesktopMonitorArea(A_Index, &l, &t, &rr, &bb)
        if x >= l && x < rr && y >= t && y < bb {
            CF.overlayMonitor := A_Index
            break
        }
    }
    SaveSettings()
}

CFOverlayStartDrag(wParam, lParam, msg, hwnd) {
    global CF
    if !CF.overlayEditing || !IsObject(CF.overlayGui)
        return
    if hwnd != CF.overlayGui.Hwnd
        && hwnd != CF.overlayStatusText.Hwnd
        && hwnd != CF.overlayCpsText.Hwnd
        return
    DllCall("user32\ReleaseCapture")
    DllCall("user32\PostMessageW", "Ptr", CF.overlayGui.Hwnd,
        "UInt", 0xA1, "Ptr", 2, "Ptr", 0)
    return 0
}

CFDesktopExitSizeMove(wParam, lParam, msg, hwnd) {
    global CF
    if CF.overlayEditing && IsObject(CF.overlayGui)
        && hwnd = CF.overlayGui.Hwnd
        CFOverlaySaveLocation()
}

CFOverlaySetEdit(enabled) {
    global CF
    if enabled {
        CF.floatShown := true
        CF.overlayEditing := true
        CFOverlayShow(true)
    } else {
        CFOverlaySaveLocation()
        CF.overlayEditing := false
    }
    CFOverlayApplyTransparency()
    CFDesktopUpdate()
    SaveSettings()
    SendState()
}

CFDesktopSetFloat(visible, persist := true) {
    global CF
    CF.floatShown := !!visible
    if !CF.floatShown
        CF.overlayEditing := false
    if CF.desktopReady
        CFDesktopUpdate()
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
        case "compactChart":
            CF.compactChart := enabled
        case "overlayAlwaysVisible":
            CF.overlayAlwaysVisible := enabled
        case "overlayOpacity":
            if !RegExMatch(value, "^(100|[1-9]?\d)$")
                return
            CF.overlayOpacity := value + 0
            CFOverlayApplyTransparency()
        case "overlayMargin":
            if !RegExMatch(value, "^(\d|[1-9]\d|100)$")
                return
            CF.overlayMargin := value + 0
            if CF.overlayPosition != "custom"
                CFOverlayPlace()
        case "overlayPosition":
            if !HasValue(["tl", "tm", "tr", "bl", "bm", "br", "custom"], value)
                return
            if value = "custom" && !CFDesktopFloatPositionValid(
                CF.overlayX, CF.overlayY, 226, 48)
                return
            CF.overlayPosition := value
            CFOverlayPlace()
        case "overlayMonitor":
            if !RegExMatch(value, "^\d{1,2}$")
                return
            if value + 0 < 1 || value + 0 > MonitorGetCount()
                return
            CF.overlayMonitor := value + 0
            if CF.overlayPosition = "custom"
                CF.overlayPosition := "tm"
            CFOverlayPlace()
        default:
            return
    }
    CFDesktopUpdate()
    SaveSettings()
    SendState()
}

CFDesktopReleaseFloat() {
    global CF
    if IsObject(CF.overlayGui) {
        try CF.overlayGui.Destroy()
    }
    CF.overlayGui := 0
    CF.overlayVisible := false
    CF.overlayEditing := false
}

CFDesktopStyleTitlebar(hwnd) {
    ; Garder la barre native sombre sur la fenêtre principale.
    if !hwnd
        return false
    dark := Buffer(4, 0)
    NumPut("Int", 1, dark)
    hr := DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd,
        "UInt", 20, "Ptr", dark, "UInt", 4, "Int")
    if hr != 0
        hr := DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd,
            "UInt", 19, "Ptr", dark, "UInt", 4, "Int")
    caption := Buffer(4, 0)
    NumPut("UInt", 0x00271A12, caption)
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd,
        "UInt", 35, "Ptr", caption, "UInt", 4, "Int")
    foreground := Buffer(4, 0)
    NumPut("UInt", 0x00FFF3E9, foreground)
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd,
        "UInt", 36, "Ptr", foreground, "UInt", 4, "Int")
    return hr = 0
}
