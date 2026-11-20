; ClickFlow v1.8.0 - Tray Windows et overlay d'état léger.
; Pas de WebView2 secondaire, de courbe GDI, ni d'historique disque.
CFDesktopInt(value, fallback, minimum, maximum) {
    if String(value) = "-99999"
        return fallback
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
    CF.diagnosticsEnabled := IniRead(file, "General", "DiagnosticsEnabled", "0") = "1"
    CF.gateDebugEnabled := IniRead(file, "General", "GateDebugEnabled", "0") = "1"
    ; Stable default remains classic; event and auto now use Raw Input.
    detectionMode := IniRead(file, "General", "MouseDetectionMode", "classic")
    CF.mouseDetectionMode := HasValue(["auto", "event", "classic"], detectionMode)
        ? detectionMode : "classic"
    CF.compactChart := IniRead(file, "General", "CompactChart", "1") != "0"
    CF.overlayAlwaysVisible := IniRead(file, "General", "OverlayAlwaysVisible", "0") = "1"
    CF.overlayOpacity := CFDesktopInt(IniRead(file, "General",
        "OverlayOpacity", "85"), 85, 0, 100)
    CF.overlayMargin := CFDesktopInt(IniRead(file, "General",
        "OverlayMargin", "20"), 20, 0, 100)
    CF.overlayAverageSeconds := CFDesktopInt(IniRead(file, "General",
        "OverlayAverageSeconds", "5"), 5, 1, 60)
    size := IniRead(file, "General", "OverlaySize", "mini")
    CF.overlaySize := HasValue(["mini", "standard", "large"], size)
        ? size : "mini"
    CF.overlayShowProfile := IniRead(file, "General", "OverlayShowProfile", "0") = "1"
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
        . ',"diagnosticsEnabled":' (CF.diagnosticsEnabled ? "true" : "false")
        . ',"gateDebugEnabled":' (CF.gateDebugEnabled ? "true" : "false")
        . ',"mouseDetectionMode":' JsonQuote(CF.mouseDetectionMode)
        . ',"compactChart":' (CF.compactChart ? "true" : "false")
        . ',"overlayAlwaysVisible":' (CF.overlayAlwaysVisible ? "true" : "false")
        . ',"overlayOpacity":' CF.overlayOpacity
        . ',"overlayMargin":' CF.overlayMargin
        . ',"overlayAverageSeconds":' CF.overlayAverageSeconds
        . ',"overlaySize":' JsonQuote(CF.overlaySize)
        . ',"overlayShowProfile":' (CF.overlayShowProfile ? "true" : "false")
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

CFOverlayMetrics(dpi := 0) {
    global CF
    ; Mini inchangée (216x34) pour préserver l'apparence validée en v1.8.2.
    if !dpi
        dpi := A_ScreenDPI
    size := CF.HasOwnProp("overlaySize") ? CF.overlaySize : "mini"
    if size = "large" {
        w := 330, h := 50, fontPx := 11, statusW := 132
    } else if size = "standard" {
        w := 270, h := 42, fontPx := 10, statusW := 112
    } else {
        w := 216, h := 34, fontPx := 8, statusW := 88
    }
    showProfile := CF.HasOwnProp("overlayShowProfile") && CF.overlayShowProfile
    extra := showProfile ? 17 : 0
    y := Max(3, Floor((h - 24) / 2))
    return {
        w: w, h: h + extra, left: 9, top: y,
        statusW: statusW, statusH: 24,
        cpsX: 10 + statusW + 5, cpsTop: y,
        cpsW: w - 20 - statusW - 5, cpsH: 24,
        font: Max(4, Round(fontPx * 96 / dpi)), radius: 12,
        nameY: h - 2, nameW: w - 18,
        nameFont: Max(4, Round(7 * 96 / dpi))
    }
}

CFOverlayPositionCoords() {
    global CF
    size := CFOverlayMetrics()
    width := size.w, height := size.h
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
    ; Pixel-for-pixel, sans mise à l'échelle automatique des contrôles.
    ; Le status et les CPS moyens restent sur UNE ligne très compacte.
    m := CFOverlayMetrics()
    overlay := Gui("-Caption +ToolWindow +AlwaysOnTop +E0x20 -DPIScale",
        "ClickFlow - Overlay")
    overlay.MarginX := 0
    overlay.MarginY := 0
    overlay.BackColor := "121F32"
    overlay.SetFont("s" m.font " bold c9AE4D4", "Segoe UI")
    CF.overlayStatusText := overlay.Add("Text",
        "x" m.left " y" m.top " w" m.statusW " h" m.statusH
        " +0x100 0x200", "ARRÊTÉ")
    overlay.SetFont("s" m.font " bold cEDF6FF", "Segoe UI")
    CF.overlayCpsText := overlay.Add("Text",
        "x" m.cpsX " y" m.cpsTop " w" m.cpsW " h" m.cpsH
        " +0x100 0x200 Right", "0,0 CPS moy.")
    overlay.SetFont("s" m.nameFont " norm cAFC4DD", "Segoe UI")
    CF.overlayNameText := overlay.Add("Text", "x9 y" m.nameY
        " w" m.nameW " h15 +0x100 0x200", "")
    CF.overlayNameText.Visible := CF.overlayShowProfile
    CF.overlayGui := overlay
    overlay.Show("NA Hide w" m.w " h" m.h)
    CFOverlayApplyTransparency()
}

CFOverlayApplyCorners() {
    global CF
    if !IsObject(CF.overlayGui)
        return
    ; Coins très légèrement arrondis : rayon apparent de 6 px.
    m := CFOverlayMetrics()
    try WinSetRegion("0-0 w" m.w " h" m.h " r" m.radius "-"
        m.radius, "ahk_id " CF.overlayGui.Hwnd)
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
    m := CFOverlayMetrics()
    ; Largeur/hauteur en pixels comme les contrôles (-DPIScale).
    ; Une fenêtre overlay peut être encore masquée lors de son placement.
    DetectHiddenWindows(true)
    try WinMove(pt.x, pt.y, m.w, m.h, "ahk_id " CF.overlayGui.Hwnd)
    finally DetectHiddenWindows(false)
}

CFOverlayShow(visible) {
    global CF
    if visible && !IsObject(CF.overlayGui)
        CFOverlayCreate()
    if CF.overlayVisible = !!visible {
        ; Une fenêtre affichée puis masquée par Windows peut désynchroniser
        ; le booléen local. La restaurer sans toucher au mode permanent.
        if visible && IsObject(CF.overlayGui)
            && !DllCall("User32\IsWindowVisible", "Ptr", CF.overlayGui.Hwnd, "Int")
            CF.overlayGui.Show("NA")
        return
    }
    CF.overlayVisible := !!visible
    if visible {
        CFOverlayPlace()
        CF.overlayGui.Show("NA")
        CFOverlayApplyCorners()
        CFOverlayApplyTransparency()
    } else if IsObject(CF.overlayGui)
        CF.overlayGui.Hide()
}

CFOverlayAverage(now) {
    global CF
    ; Ne conserver que les clics du délai choisi (1 à 60 secondes).
    ; Le nettoyage est également immédiat si l'utilisateur réduit le délai.
    windowMs := CF.overlayAverageSeconds * 1000
    while CF.overlayRecent.Length && CF.overlayRecent[1] < now - windowMs
        CF.overlayRecent.RemoveAt(1)
    if !CF.armed || !CF.overlayRecent.Length
        return 0
    elapsed := Max(200, Min(windowMs, now - CF.overlayStart))
    return Round(CF.overlayRecent.Length * 1000 / elapsed, 1)
}

CFDesktopUpdate() {
    global CF
    if !CF.desktopReady
        return
    status := CF.armed ? (CF.cfg.mouseGate
        && !CFGateIsHeld() ? "EN ATTENTE" : "ACTIF")
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
        Format("{:.1f}", CFOverlayAverage(now)), ".", ",") " CPS moy."
    if CF.overlayShowProfile
        CF.overlayNameText.Text := StrLen(name) > 38
            ? SubStr(name, 1, 37) "..." : name
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

CFOverlayRebuild() {
    global CF
    ; Aucune recréation si l'overlay n'est pas visible.
    if IsObject(CF.overlayGui) {
        try CF.overlayGui.Destroy()
        CF.overlayGui := 0
        CF.overlayVisible := false
    }
    CFDesktopUpdate()
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
        case "diagnosticsEnabled":
            CFDiagToggle(enabled)
        case "gateDebugEnabled":
            CFGateDebugToggle(enabled)
        case "mouseDetectionMode":
            if !HasValue(["classic", "auto", "event"], value)
                return
            if value != CF.mouseDetectionMode {
                StopAll("Méthode de détection souris modifiée.")
                CF.mouseDetectionMode := value
                CF.gateMethodLast := "none"
                CF.gateMethodCurrent := "inactive"
            }
        case "compactChart":
            CF.compactChart := enabled
        case "overlayAlwaysVisible":
            CF.overlayAlwaysVisible := enabled
        case "overlayOpacity":
            if !RegExMatch(value, "^(100|[1-9]?\d)$")
                return
            CF.overlayOpacity := value + 0
            CFOverlayApplyTransparency()
        case "overlaySize":
            if !HasValue(["mini", "standard", "large"], value)
                return
            CF.overlaySize := value
            CFOverlayRebuild()
        case "overlayShowProfile":
            CF.overlayShowProfile := enabled
            CFOverlayRebuild()
        case "overlayAverageSeconds":
            if !RegExMatch(value, "^([1-9]|[1-5]\d|60)$")
                return
            CF.overlayAverageSeconds := value + 0
            CFOverlayAverage(A_TickCount)
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
                CF.overlayX, CF.overlayY, CFOverlayMetrics().w,
                CFOverlayMetrics().h)
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
    SendStats()
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
