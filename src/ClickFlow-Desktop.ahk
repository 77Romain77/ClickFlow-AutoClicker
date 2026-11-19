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
    CF.floatX := CFDesktopInt(IniRead(file, "General", "FloatX", "-99999"),
        -99999, -30000, 30000)
    CF.floatY := CFDesktopInt(IniRead(file, "General", "FloatY", "-99999"),
        -99999, -30000, 30000)
    CF.floatPoints := []
    CF.floatLastSample := 0
    CF.floatReady := false
    CF.floatBitmap := 0
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
    CF.floatProfile := mini.Add("Text", "x10 y9 w193 h27 +0x100", "Principal")
    ; Double-clic sur le nom : restaurer l'interface complète.
    CF.floatProfile.OnEvent("DoubleClick", CFDesktopOpen)
    mini.SetFont("s8 norm c9DBDE0", "Segoe UI")
    CF.floatStatus := mini.Add("Text", "x10 y37 w282 h16", "Prêt")
    mini.SetFont("s9 bold cEDF5FF", "Segoe UI")
    CF.floatCps := mini.Add("Text", "x10 y56 w282 h20", "0 CPS - 0 clics")

    ; Deux actions discrètes, dessinées aux couleurs de ClickFlow.
    ; Des libellés SS_NOTIFY transparents recouvrent les fonds colorés.
    mini.SetFont("s8 norm cE3EEFF", "Segoe UI")
    CF.floatGraphBg := mini.Add("Progress",
        "x207 y8 w41 h23 -Theme Smooth c355982 Background1D2B43", 100)
    CF.floatGraphButton := mini.Add("Text",
        "x207 y8 w41 h23 +0x100 Center 0x200 BackgroundTrans", "CPS")
    CF.floatGraphButton.OnEvent("Click", CFDesktopToggleGraph)
    mini.SetFont("s8 bold cFFFFFF", "Segoe UI")
    CF.floatStopBg := mini.Add("Progress",
        "x255 y8 w47 h23 -Theme Smooth c7D3A55 Background2C2132", 100)
    CF.floatStop := mini.Add("Text",
        "x255 y8 w47 h23 +0x100 Center 0x200 BackgroundTrans", "STOP")
    CF.floatStop.OnEvent("Click", CFDesktopStop)

    ; SS_BITMAP (0xE) est indispensable à STM_SETIMAGE (0x172).
    ; Sans ce style, l'ancien contrôle recevait un bitmap mais restait vide.
    CF.floatChart := mini.Add("Picture", "x10 y82 w290 h60 +0xE")
    mini.OnEvent("Close", CFDesktopCloseFloat)
    mini.OnEvent("Size", CFDesktopResizeFloat)
    CF.floatGui := mini
}

CFDesktopResizeFloat(guiObj, state, width, height) {
    global CF
    if state = -1 || !CF.floatReady
        return
    width := Max(245, width)
    height := Max(96, height)
    margin := 10
    inner := width - 2 * margin
    ; Petits boutons fixes, police compacte et nom autorisé sur deux lignes.
    graphX := width - 102
    stopX := width - 56
    CF.floatProfile.Move(margin, 7, Max(105, inner - 107), 29)
    CF.floatGraphBg.Move(graphX, 8, 40, 23)
    CF.floatGraphButton.Move(graphX, 8, 40, 23)
    CF.floatStopBg.Move(stopX, 8, 46, 23)
    CF.floatStop.Move(stopX, 8, 46, 23)
    CF.floatStatus.Move(margin, 37, inner, 16)
    CF.floatCps.Move(margin, 55, inner, 20)

    chartHeight := Max(0, height - 87)
    showChart := CF.floatGraph && chartHeight >= 22
    CF.floatChart.Visible := showChart
    if showChart {
        CF.floatChart.Move(margin, 80, inner, chartHeight)
        CFDesktopDrawFloatChart()
    }
}

CFDesktopSaveFloatBounds(*) {
    global CF
    if !CF.floatReady || !IsObject(CF.floatGui)
        return
    try {
        WinGetPos(&x, &y, , , "ahk_id " CF.floatGui.Hwnd)
        ; Gui.Show w/h utilise la taille CLIENT, pas le cadre extérieur.
        ; Stocker cette même unité évite de grossir la fenêtre à chaque ouverture.
        WinGetClientPos(, , &w, &h, "ahk_id " CF.floatGui.Hwnd)
        if w < 240 || h < 90
            return
        CF.floatX := x
        CF.floatY := y
        CF.floatWidth := w
        CF.floatHeight := h
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
            options := "NA w" CF.floatWidth " h" CF.floatHeight
            if CFDesktopFloatPositionValid(CF.floatX, CF.floatY,
                CF.floatWidth, CF.floatHeight)
                options .= " x" CF.floatX " y" CF.floatY
            CF.floatGui.Show(options)
            CFDesktopStyleTitlebar(CF.floatGui.Hwnd)
            CF.floatReady := true
            WinGetClientPos(, , &clientWidth, &clientHeight,
                "ahk_id " CF.floatGui.Hwnd)
            CFDesktopResizeFloat(CF.floatGui, 0, clientWidth, clientHeight)
            CFDesktopApplyWindowAppearance()
            CFDesktopUpdate()
        } else if IsObject(CF.floatGui) {
            CFDesktopSaveFloatBounds()
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
    if CF.floatGraph && IsObject(CF.floatGui) {
        WinGetClientPos(, , , &h, "ahk_id " CF.floatGui.Hwnd)
        if h < 130
            CF.floatGui.Show("NA h144")
    }
    if CF.floatShown && IsObject(CF.floatGui) {
        WinGetClientPos(, , &w, &h, "ahk_id " CF.floatGui.Hwnd)
        CFDesktopResizeFloat(CF.floatGui, 0, w, h)
    }
    CFDesktopSaveFloatBounds()
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
    CF.floatChart.GetPos(, , &width, &height)
    width := Round(width), height := Round(height)
    if width < 40 || height < 40
        return
    hwnd := CF.floatChart.Hwnd
    screenDC := DllCall("User32\GetDC", "Ptr", hwnd, "Ptr")
    if !screenDC
        return
    memDC := DllCall("gdi32\CreateCompatibleDC", "Ptr", screenDC, "Ptr")
    bitmap := DllCall("gdi32\CreateCompatibleBitmap", "Ptr", screenDC,
        "Int", width, "Int", height, "Ptr")
    if !memDC || !bitmap {
        if bitmap
            DllCall("gdi32\DeleteObject", "Ptr", bitmap)
        if memDC
            DllCall("gdi32\DeleteDC", "Ptr", memDC)
        DllCall("User32\ReleaseDC", "Ptr", hwnd, "Ptr", screenDC)
        return
    }
    original := DllCall("gdi32\SelectObject", "Ptr", memDC, "Ptr", bitmap, "Ptr")
    brush := DllCall("gdi32\CreateSolidBrush", "UInt", 0x0023190D, "Ptr")
    rect := Buffer(16, 0)
    NumPut("Int", 0, "Int", 0, "Int", width, "Int", height, rect)
    DllCall("User32\FillRect", "Ptr", memDC, "Ptr", rect, "Ptr", brush)
    DllCall("gdi32\DeleteObject", "Ptr", brush)
    grid := CFDesktopChartPen(memDC, 0x00433527)
    Loop 3 {
        y := Round(height * A_Index / 4)
        DllCall("gdi32\MoveToEx", "Ptr", memDC, "Int", 0, "Int", y, "Ptr", 0)
        DllCall("gdi32\LineTo", "Ptr", memDC, "Int", width, "Int", y)
    }
    DllCall("gdi32\SelectObject", "Ptr", memDC, "Ptr", grid.old)
    DllCall("gdi32\DeleteObject", "Ptr", grid.pen)
    samples := CF.floatPoints
    if samples.Length {
        lastTick := A_TickCount
        peak := 5
        for sample in samples
            peak := Max(peak, sample.cps)
        pen := CFDesktopChartPen(memDC, 0x00FFB775, 2)
        first := true
        for sample in samples {
            x := Round(3 + (width - 6) * (1 - (lastTick - sample.t) / 30000))
            x := Max(2, Min(width - 3, x))
            y := Round(height - 4 - (height - 8) * sample.cps / (peak + 2))
            if first {
                DllCall("gdi32\MoveToEx", "Ptr", memDC,
                    "Int", x, "Int", y, "Ptr", 0)
                first := false
            } else
                DllCall("gdi32\LineTo", "Ptr", memDC, "Int", x, "Int", y)
        }
        DllCall("gdi32\SelectObject", "Ptr", memDC, "Ptr", pen.old)
        DllCall("gdi32\DeleteObject", "Ptr", pen.pen)
    }
    DllCall("gdi32\SelectObject", "Ptr", memDC, "Ptr", original)
    DllCall("gdi32\DeleteDC", "Ptr", memDC)
    DllCall("User32\ReleaseDC", "Ptr", hwnd, "Ptr", screenDC)
    try {
        previous := SendMessage(0x172, 0, bitmap, , "ahk_id " hwnd)
        if previous && previous != bitmap
            DllCall("gdi32\DeleteObject", "Ptr", previous)
        CF.floatBitmap := bitmap
    } catch {
        DllCall("gdi32\DeleteObject", "Ptr", bitmap)
    }
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
    if CF.floatBitmap {
        try {
            old := SendMessage(0x172, 0, 0, ,
                "ahk_id " CF.floatChart.Hwnd)
            if old
                DllCall("gdi32\DeleteObject", "Ptr", old)
        }
        CF.floatBitmap := 0
    }
    try CF.floatGui.Destroy()
    CF.floatReady := false
}
