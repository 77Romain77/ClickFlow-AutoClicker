; ClickFlow v1.7 - Windows tray + mini-fenêtre redimensionnable.
; La courbe est un bitmap GDI natif en mémoire, sans WebView2 secondaire.
; Aucun historique de CPS n'est conservé après la fermeture.
CFDesktopInt(value, fallback, minimum, maximum) {
    if String(value) = "-99999"
        return fallback
    return RegExMatch(String(value), "^-?\d{1,7}$")
        ? Max(minimum, Min(maximum, value + 0)) : fallback
}

CFDesktopReadPreferences() {
    global CF
    file := CF.configFile
    CF.closeToTray := IniRead(file, "General", "CloseToTray", "0") = "1"
    CF.minimizeToTray := IniRead(file, "General", "MinimizeToTray", "0") = "1"
    CF.floatShown := IniRead(file, "General", "FloatShown", "0") = "1"
    CF.liveMonitor := IniRead(file, "General", "LiveMonitor", "1") != "0"
    CF.compactChart := IniRead(file, "General", "CompactChart", "1") != "0"
    CF.floatGraph := IniRead(file, "General", "FloatGraph", "1") = "1"
    CF.floatTopMost := IniRead(file, "General", "FloatTopMost", "1") != "0"
    CF.floatOpacity := CFDesktopInt(IniRead(file, "General", "FloatOpacity", "100"),
        100, 70, 100)
    CF.floatWidth := CFDesktopInt(IniRead(file, "General", "FloatWidth", "310"),
        310, 260, 1300)
    CF.floatHeight := CFDesktopInt(IniRead(file, "General", "FloatHeight", "150"),
        150, 110, 950)
    ; Migration : v1.7.1 mémorisait la taille intérieure, la v1.7.2
    ; mémorise exclusivement le rectangle extérieur de la fenêtre.
    CF.floatBoundsOuter := IniRead(file, "General", "FloatBoundsFormat", "") = "outer"
    CF.floatLegacyClient := !CF.floatBoundsOuter
        && IniRead(file, "General", "FloatWidth", "") != ""
    CF.mainExpandedW := CFDesktopInt(IniRead(file, "General", "MainExpandedWidth", "1120"),
        1120, 600, 2400)
    CF.mainExpandedH := CFDesktopInt(IniRead(file, "General", "MainExpandedHeight", "800"),
        800, 500, 1600)
    CF.mainCompactW := CFDesktopInt(IniRead(file, "General", "MainCompactWidth", "465"),
        465, 460, 1200)
    CF.mainCompactH := CFDesktopInt(IniRead(file, "General", "MainCompactHeight", "600"),
        600, 480, 1600)
    CF.floatX := CFDesktopInt(IniRead(file, "General", "FloatX", "-99999"),
        -99999, -30000, 30000)
    CF.floatY := CFDesktopInt(IniRead(file, "General", "FloatY", "-99999"),
        -99999, -30000, 30000)
    CF.floatPoints := []
    CF.floatLastSample := 0
    CF.floatReady := false
    CF.floatBitmap := 0
    CF.floatStopBrush := 0
    CF.floatGraphBrush := 0
    CF.floatGraphOffBrush := 0
    CF.floatChartPaintCount := 0
}

CFDesktopPreferencesJson() {
    global CF
    return '{"closeToTray":' (CF.closeToTray ? "true" : "false")
        . ',"minimizeToTray":' (CF.minimizeToTray ? "true" : "false")
        . ',"floatShown":' (CF.floatShown ? "true" : "false")
        . ',"liveMonitor":' (CF.liveMonitor ? "true" : "false")
        . ',"compactChart":' (CF.compactChart ? "true" : "false")
        . ',"floatGraph":' (CF.floatGraph ? "true" : "false")
        . ',"floatTopMost":' (CF.floatTopMost ? "true" : "false")
        . ',"floatOpacity":' CF.floatOpacity '}'
}

CFDesktopInit() {
    global CF
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Ouvrir l'interface", CFDesktopOpen)
    A_TrayMenu.Default := "Ouvrir l'interface"
    A_TrayMenu.Add("Arrêter les clics", CFDesktopStop)
    A_TrayMenu.Add("Afficher la mini-fenêtre", CFDesktopToggleFloat)
    A_TrayMenu.Add()
    CF.trayProfiles := Menu()
    A_TrayMenu.Add("Choisir un profil", CF.trayProfiles)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Quitter ClickFlow", CFDesktopQuit)
    CF.desktopReady := true
    CFDesktopRebuildProfiles()
    OnMessage(0x232, CFDesktopExitSizeMove)
    OnMessage(0xF, CFDesktopChartPaint)
    OnMessage(0x138, CFDesktopColorControls)
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
    for profile in CF.profiles {
        ; Escape & car Windows l'interprète comme raccourci de menu.
        label := StrReplace(profile.name, "&", "&&")
        CF.trayProfiles.Add(label, CFDesktopSelectProfile.Bind(profile.id))
        if profile.id = CF.selectedId
            CF.trayProfiles.Check(label)
    }
}

CFDesktopFloatPositionValid(x, y, width, height) {
    if x = -99999 || y = -99999
        return false
    Loop MonitorGetCount() {
        MonitorGetWorkArea(A_Index, &left, &top, &right, &bottom)
        if x + width >= left + 80 && x <= right - 80
            && y + height >= top + 65 && y <= bottom - 65
            return true
    }
    return false
}

CFDesktopCaptureMainBounds(compact := "") {
    global CF
    if !CF.hwnd || CF.loading || CF.shuttingDown
        return
    hwnd := CF.hwnd
    try {
        ; Ne pas écraser la taille enregistrée par l'état maximisé/minimisé.
        if WinGetMinMax("ahk_id " hwnd) != 0
            return
        WinGetPos(, , &w, &h, "ahk_id " hwnd)
        if w < 460 || h < 470
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

CFDesktopRestoreMainBounds() {
    global CF
    if !CF.hwnd
        return
    w := CF.compactMode ? CF.mainCompactW : CF.mainExpandedW
    h := CF.compactMode ? CF.mainCompactH : CF.mainExpandedH
    WinMove(, , w, h, "ahk_id " CF.hwnd)
}

CFDesktopCreateFloat() {
    global CF
    if IsObject(CF.floatGui)
        return
    mini := Gui("+Resize +MinSize260x110 +ToolWindow +AlwaysOnTop",
        "ClickFlow - Mini")
    mini.MarginX := 0
    mini.MarginY := 0
    mini.BackColor := "142136"

    mini.SetFont("s8 cF1F6FF", "Segoe UI")
    CF.floatProfile := mini.Add("Text", "x10 y8 w152 h29 +0x100", "Principal")
    CF.floatProfile.OnEvent("DoubleClick", CFDesktopOpen)
    mini.SetFont("s8 norm c9DBDE0", "Segoe UI")
    CF.floatStatus := mini.Add("Text", "x10 y36 w245 h17", "Prêt")
    mini.SetFont("s9 bold cEDF5FF", "Segoe UI")
    CF.floatCps := mini.Add("Text", "x10 y54 w245 h22", "0 CPS - 0 clics")

    ; Des textes cliquables natifs et opaques remplacent les Progress
    ; superposées qui créaient des bandes et des décalages au resize.
    mini.SetFont("s8 bold cECF6FF", "Segoe UI")
    CF.floatGraphButton := mini.Add("Text",
        "x175 y8 w61 h25 +0x100 Center 0x200", "Courbe")
    CF.floatGraphButton.OnEvent("Click", CFDesktopToggleGraph)
    mini.SetFont("s8 bold cFFECF1", "Segoe UI")
    CF.floatStop := mini.Add("Text",
        "x241 y8 w52 h25 +0x100 Center 0x200", "STOP")
    CF.floatStop.OnEvent("Click", CFDesktopStop)
    CF.floatGraphBrush := DllCall("gdi32\CreateSolidBrush",
        "UInt", 0x0086532C, "Ptr")
    CF.floatGraphOffBrush := DllCall("gdi32\CreateSolidBrush",
        "UInt", 0x00382A1E, "Ptr")
    CF.floatStopBrush := DllCall("gdi32\CreateSolidBrush",
        "UInt", 0x00452E70, "Ptr")

    ; WM_PAINT dessine directement la courbe sur toute la zone du contrôle.
    ; Pas de SS_BITMAP : Windows réduisait automatiquement la taille de
    ; l'image sur certaines configurations DPI/redimensionnements.
    CF.floatChart := mini.Add("Text", "x10 y80 w290 h60", "")
    mini.OnEvent("Close", CFDesktopCloseFloat)
    mini.OnEvent("Size", CFDesktopResizeFloat)
    CF.floatGui := mini
}

CFDesktopColorControls(wParam, lParam, msg, hwnd) {
    global CF
    if !CF.floatReady || !IsObject(CF.floatGui)
        return
    brush := 0
    if IsObject(CF.floatStop) && lParam = CF.floatStop.Hwnd
        brush := CF.floatStopBrush
    else if IsObject(CF.floatGraphButton) && lParam = CF.floatGraphButton.Hwnd
        brush := CF.floatGraph ? CF.floatGraphBrush : CF.floatGraphOffBrush
    if !brush
        return
    background := lParam = CF.floatStop.Hwnd ? 0x00452E70
        : CF.floatGraph ? 0x0086532C : 0x00382A1E
    DllCall("gdi32\SetBkMode", "Ptr", wParam, "Int", 2)
    DllCall("gdi32\SetBkColor", "Ptr", wParam, "UInt", background)
    DllCall("gdi32\SetTextColor", "Ptr", wParam, "UInt", 0x00FFF6EC)
    return brush
}

CFDesktopResizeFloat(guiObj, state, width, height) {
    global CF
    if state = -1 || !CF.floatReady
        return
    width := Max(245, width)
    height := Max(98, height)
    margin := 10
    inner := width - 2 * margin
    ; Les actions restent fixes en haut, sans chevauchement même
    ; à la taille minimale. La courbe occupe tout l'espace disponible.
    graphW := 61
    stopW := 52
    graphX := width - margin - graphW - stopW - 6
    stopX := width - margin - stopW
    CF.floatProfile.Move(margin, 7, Max(105, graphX - margin - 7), 30)
    CF.floatGraphButton.Move(graphX, 8, graphW, 25)
    CF.floatStop.Move(stopX, 8, stopW, 25)
    CF.floatStatus.Move(margin, 37, inner, 16)
    CF.floatCps.Move(margin, 54, inner, 22)
    chartHeight := Max(0, height - 84)
    showChart := CF.floatGraph && chartHeight >= 18
    CF.floatChart.Visible := showChart
    if showChart {
        CF.floatChart.Move(margin, 79, inner, chartHeight)
        CFDesktopDrawFloatChart()
    }
}

CFDesktopSaveFloatBounds(*) {
    global CF
    if !CF.floatReady || !IsObject(CF.floatGui)
        return
    try {
        ; Mesure unique en coordonnées de fenêtre extérieure :
        ; Show() + WinMove() utilisent désormais toujours la même unité.
        WinGetPos(&x, &y, &w, &h, "ahk_id " CF.floatGui.Hwnd)
        if w < 250 || h < 100
            return
        CF.floatX := x
        CF.floatY := y
        CF.floatWidth := w
        CF.floatHeight := h
        CF.floatBoundsOuter := true
        CF.floatLegacyClient := false
        SaveSettings()
    }
}

CFDesktopExitSizeMove(wParam, lParam, msg, hwnd) {
    global CF
    if !CF.floatReady || !IsObject(CF.floatGui) || hwnd != CF.floatGui.Hwnd
        return
    CFDesktopSaveFloatBounds()
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
            CF.floatReady := false
            ; Ne jamais donner de largeur/hauteur à Gui.Show() pour une
            ; fenêtre déjà créée : cela réintroduisait un décalage client/cadre.
            CF.floatGui.Show("NA")
            CFDesktopStyleTitlebar(CF.floatGui.Hwnd)
            if !CF.floatBoundsOuter {
                ; Convertir une seule fois les dimensions CLIENT des anciennes
                ; versions, en mesurant les bordures réelles sur cet ordinateur.
                WinGetPos(, , &frameW, &frameH,
                    "ahk_id " CF.floatGui.Hwnd)
                WinGetClientPos(, , &clientW, &clientH,
                    "ahk_id " CF.floatGui.Hwnd)
                if CF.floatLegacyClient {
                    CF.floatWidth += Max(0, frameW - clientW)
                    CF.floatHeight += Max(0, frameH - clientH)
                }
                CF.floatBoundsOuter := true
                CF.floatLegacyClient := false
            }
            ; Restaurer exactement le rectangle extérieur : aucun cumul
            ; possible, même après de nombreuses fermetures/réouvertures.
            targetX := CF.floatX
            targetY := CF.floatY
            valid := CFDesktopFloatPositionValid(targetX, targetY,
                CF.floatWidth, CF.floatHeight)
            if valid
                WinMove(targetX, targetY, CF.floatWidth, CF.floatHeight,
                    "ahk_id " CF.floatGui.Hwnd)
            else
                WinMove(, , CF.floatWidth, CF.floatHeight,
                    "ahk_id " CF.floatGui.Hwnd)
            CF.floatReady := true
            WinGetClientPos(, , &clientWidth, &clientHeight,
                "ahk_id " CF.floatGui.Hwnd)
            CFDesktopResizeFloat(CF.floatGui, 0, clientWidth, clientHeight)
            CFDesktopApplyWindowAppearance()
            CFDesktopUpdate()
        } else if IsObject(CF.floatGui) {
            CFDesktopSaveFloatBounds()
            CF.floatReady := false
            CF.floatGui.Hide()
        }
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

CFDesktopToggleGraph(*) {
    global CF
    CF.floatGraph := !CF.floatGraph
    if CF.floatShown && IsObject(CF.floatGui) {
        WinGetClientPos(, , &w, &h, "ahk_id " CF.floatGui.Hwnd)
        CFDesktopResizeFloat(CF.floatGui, 0, w, h)
        DllCall("User32\InvalidateRect", "Ptr", CF.floatGraphButton.Hwnd,
            "Ptr", 0, "Int", 1)
    }
    ; L'option Courbe n'agrandit ni ne déplace plus la mini-fenêtre.
    SaveSettings()
    SendState()
}

CFDesktopStyleTitlebar(hwnd) {
    ; Barre de titre Windows native : thème sombre et couleurs ClickFlow.
    ; Les attributs DWM sont ignorés sans erreur par les anciens Windows.
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
    NumPut("UInt", 0x00271A12, caption) ; COLORREF (#121A27)
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd,
        "UInt", 35, "Ptr", caption, "UInt", 4, "Int")
    foreground := Buffer(4, 0)
    NumPut("UInt", 0x00FFF3E9, foreground)
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd,
        "UInt", 36, "Ptr", foreground, "UInt", 4, "Int")
    return hr = 0
}

CFDesktopApplyWindowAppearance() {
    global CF
    if !IsObject(CF.floatGui)
        return
    CF.floatGui.Opt(CF.floatTopMost ? "+AlwaysOnTop" : "-AlwaysOnTop")
    try WinSetTransparent(Round(255 * CF.floatOpacity / 100),
        "ahk_id " CF.floatGui.Hwnd)
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
        case "floatGraph":
            CF.floatGraph := enabled
            if CF.floatShown && IsObject(CF.floatGui) {
                WinGetClientPos(, , &w, &h, "ahk_id " CF.floatGui.Hwnd)
                CFDesktopResizeFloat(CF.floatGui, 0, w, h)
            }
        case "floatTopMost":
            CF.floatTopMost := enabled
            CFDesktopApplyWindowAppearance()
        case "floatOpacity":
            if !RegExMatch(value, "^(70|80|90|100)$")
                return
            CF.floatOpacity := value + 0
            CFDesktopApplyWindowAppearance()
        default:
            return
    }
    SaveSettings()
    SendState()
}

CFDesktopChartPen(dc, color, thickness := 1) {
    pen := DllCall("gdi32\CreatePen", "Int", 0, "Int", thickness,
        "UInt", color, "Ptr")
    old := DllCall("gdi32\SelectObject", "Ptr", dc, "Ptr", pen, "Ptr")
    return {pen: pen, old: old}
}

CFDesktopDrawFloatChart() {
    global CF
    if !CF.floatShown || !CF.floatGraph || !CF.floatReady
        || !IsObject(CF.floatChart) || !CF.floatChart.Visible
        return
    ; Windows redessine le contrôle à chaque WM_PAINT avec SES dimensions
    ; courantes, et non avec la taille fixe d'un bitmap SS_BITMAP.
    hwnd := CF.floatChart.Hwnd
    DllCall("User32\InvalidateRect", "Ptr", hwnd, "Ptr", 0, "Int", 0)
    DllCall("User32\UpdateWindow", "Ptr", hwnd)
}

CFDesktopChartPaint(wParam, lParam, msg, hwnd) {
    global CF
    if !IsObject(CF.floatChart) || hwnd != CF.floatChart.Hwnd
        return
    paint := Buffer(128, 0)
    dc := DllCall("User32\BeginPaint", "Ptr", hwnd, "Ptr", paint, "Ptr")
    if dc {
        try CFDesktopPaintChartDC(dc, hwnd)
        DllCall("User32\EndPaint", "Ptr", hwnd, "Ptr", paint)
    }
    return 0
}

CFDesktopPaintChartDC(destination, hwnd) {
    global CF
    bounds := Buffer(16, 0)
    if !DllCall("User32\GetClientRect", "Ptr", hwnd, "Ptr", bounds)
        return
    width := NumGet(bounds, 8, "Int")
    height := NumGet(bounds, 12, "Int")
    if width < 10 || height < 10
        return
    memDC := DllCall("gdi32\CreateCompatibleDC", "Ptr", destination, "Ptr")
    if !memDC
        return
    bitmap := DllCall("gdi32\CreateCompatibleBitmap", "Ptr", destination,
        "Int", width, "Int", height, "Ptr")
    if !bitmap {
        DllCall("gdi32\DeleteDC", "Ptr", memDC)
        return
    }
    original := DllCall("gdi32\SelectObject", "Ptr", memDC, "Ptr", bitmap, "Ptr")
    brush := DllCall("gdi32\CreateSolidBrush", "UInt", 0x0023190D, "Ptr")
    DllCall("User32\FillRect", "Ptr", memDC, "Ptr", bounds, "Ptr", brush)
    DllCall("gdi32\DeleteObject", "Ptr", brush)

    grid := CFDesktopChartPen(memDC, 0x00433527)
    Loop 3 {
        y := Round(height * A_Index / 4)
        DllCall("gdi32\MoveToEx", "Ptr", memDC, "Int", 0, "Int", y, "Ptr", 0)
        DllCall("gdi32\LineTo", "Ptr", memDC, "Int", width, "Int", y)
    }
    DllCall("gdi32\SelectObject", "Ptr", memDC, "Ptr", grid.old)
    DllCall("gdi32\DeleteObject", "Ptr", grid.pen)

    now := A_TickCount
    peak := 5
    for sample in CF.floatPoints
        if sample.t >= now - 30000
            peak := Max(peak, sample.cps)
    pen := CFDesktopChartPen(memDC, 0x00FFB775, 2)
    ; Toujours dessiner une ligne de base sur toute la largeur, même
    ; à zéro CPS : le graphique n'a jamais l'air vide.
    bottomY := height - 5
    DllCall("gdi32\MoveToEx", "Ptr", memDC,
        "Int", 3, "Int", bottomY, "Ptr", 0)
    first := true
    for sample in CF.floatPoints {
        if sample.t < now - 30000
            continue
        x := Max(2, Min(width - 3, Round(3 + (width - 6)
            * (1 - (now - sample.t) / 30000))))
        y := Max(3, Min(height - 4, Round(height - 4
            - (height - 8) * sample.cps / (peak + 2))))
        if first {
            DllCall("gdi32\LineTo", "Ptr", memDC, "Int", x, "Int", y)
            first := false
        } else {
            DllCall("gdi32\LineTo", "Ptr", memDC, "Int", x, "Int", y)
        }
    }
    DllCall("gdi32\LineTo", "Ptr", memDC, "Int", width - 3, "Int",
        first ? bottomY : y)
    DllCall("gdi32\SelectObject", "Ptr", memDC, "Ptr", pen.old)
    DllCall("gdi32\DeleteObject", "Ptr", pen.pen)
    DllCall("gdi32\BitBlt", "Ptr", destination,
        "Int", 0, "Int", 0, "Int", width, "Int", height,
        "Ptr", memDC, "Int", 0, "Int", 0, "UInt", 0x00CC0020)
    DllCall("gdi32\SelectObject", "Ptr", memDC, "Ptr", original)
    DllCall("gdi32\DeleteObject", "Ptr", bitmap)
    DllCall("gdi32\DeleteDC", "Ptr", memDC)
    CF.floatChartPaintCount := CF.floatChartPaintCount + 1
}

CFDesktopUpdate() {
    global CF
    if !CF.desktopReady
        return
    status := CF.test.active ? "Test CPS en cours"
        : CF.armed ? (CF.cfg.mouseGate
            && !GetKeyState(CF.cfg.gateButton, "P") ? "En attente" : "Clics actifs")
        : "Prêt"
    profile := CFProfileById(CF.selectedId)
    name := IsObject(profile) ? profile.name : "Principal"
    try A_IconTip := "ClickFlow - " status " - " name
    now := A_TickCount
    if CF.floatLastSample = 0 || now - CF.floatLastSample >= 180 {
        CF.floatLastSample := now
        CF.floatPoints.Push({t: now, cps: CF.recent.Length})
        while CF.floatPoints.Length
            && CF.floatPoints[1].t < now - 30000
            CF.floatPoints.RemoveAt(1)
        if CF.floatPoints.Length > 160
            CF.floatPoints.RemoveAt(1)
    }
    if CF.floatShown && IsObject(CF.floatGui) {
        CF.floatProfile.Text := name
        CF.floatStatus.Text := status
        CF.floatCps.Text := CF.recent.Length " CPS - " CF.total " clics"
        CF.floatGraphButton.Text := CF.floatGraph ? "CPS" : "OFF"
        CFDesktopDrawFloatChart()
    }
}

CFDesktopReleaseFloat() {
    global CF
    if !IsObject(CF.floatGui)
        return
    CFDesktopSaveFloatBounds()
    CF.floatReady := false
    for name in ["floatStopBrush", "floatGraphBrush", "floatGraphOffBrush"] {
        if CF.%name% {
            DllCall("gdi32\DeleteObject", "Ptr", CF.%name%)
            CF.%name% := 0
        }
    }
    try CF.floatGui.Destroy()
    CF.floatGui := 0
}
