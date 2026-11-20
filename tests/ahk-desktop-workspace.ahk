#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include ..\src\ClickFlow-Backend.ahk

; Régression v1.8 - profils, placement, transparence, overlay et Windows.
global CF
CF.web := 0
CF.loading := false
CF.shuttingDown := false
CF.configFile := A_Temp "\clickflow-overlay-" A_TickCount ".ini"
CF.profilesDir := A_Temp "\clickflow-overlay-profiles-" A_TickCount
CF.profiles := [{id: 3, name: "Profil A", cfg: DefaultConfig()},
    {id: 7, name: "Profil B", cfg: DefaultConfig()},
    {id: 11, name: "Profil C", cfg: DefaultConfig()}]
CF.selectedId := 3
CF.cfg := CF.profiles[1].cfg
CF.nextId := 12

try {
    CFDesktopReadPreferences()
    if CF.floatShown || CF.closeToTray || CF.minimizeToTray
        throw Error("Les fenêtres auxiliaires doivent être désactivées par défaut.")
    if CF.overlayOpacity != 85 || CF.overlayPosition != "tm"
        throw Error("Mauvais réglages initiaux de l'overlay.")
    if CF.overlayAverageSeconds != 5
        throw Error("La moyenne CPS doit commencer sur 5 secondes.")
    if CF.overlayAlwaysVisible
        throw Error("L'overlay ne doit pas rester affiché par défaut.")
    if CF.diagnosticsEnabled
        throw Error("Les diagnostics doivent être inactifs par défaut.")
    if CF.mouseDetectionMode != "auto"
        throw Error("La méthode doit être Automatique par défaut.")

    SaveSettings()
    CFToggleProfileFavorite(7)
    CFReorderProfile(11, "up")
    CFReorderProfile(11, "up")
    if CF.profiles[1].id != 11 || !CFProfileById(7).favorite
        throw Error("Favoris ou ordre incorrects.")
    if !CFLoadSeparatedProfiles()
        throw Error("Les profils ne se rechargent plus.")
    if CF.profiles[1].id != 11 || !CFProfileById(7).favorite
        throw Error("Ordre ou favoris perdus après rechargement.")

    CFProfileById(7).cfg.activation := "F9"
    CFApplyQuickSettings("7", "natural", "9", "18", "high")
    p := CFProfileById(7).cfg
    if p.min != 9 || p.max != 18 || p.variation != 3
        || p.activation != "F9"
        throw Error("Réglages rapides des profils cassés.")

    g := Gui("+Resize", "ClickFlow-test-overlay")
    g.Show("w540 h700")
    CF.hwnd := g.Hwnd
    CFDesktopInit()
    CFDesktopSetPreference("diagnosticsEnabled", "1")
    if !CF.diagnosticsEnabled
        throw Error("Les diagnostics ne s'activent pas.")
    CFDesktopSetPreference("diagnosticsEnabled", "0")
    if CF.diagnosticsEnabled || CF.gateHook
        throw Error("Les diagnostics restent actifs après désactivation.")
    if IniRead(CF.configFile, "General", "DiagnosticsEnabled", "") != "0"
        throw Error("Le diagnostic ne se sauvegarde pas.")
    CFDesktopSetPreference("mouseDetectionMode", "classic")
    if CF.mouseDetectionMode != "classic"
        || IniRead(CF.configFile, "General", "MouseDetectionMode", "") != "classic"
        throw Error("Le choix Classique n'est pas conservé.")
    CFDesktopSetPreference("mouseDetectionMode", "event")
    if CF.mouseDetectionMode != "event"
        throw Error("Le mode Événementiel ne s'active pas.")
    CFDesktopSetPreference("mouseDetectionMode", "invalid")
    if CF.mouseDetectionMode != "event"
        throw Error("Une méthode de détection invalide a été acceptée.")
    CFDesktopSetPreference("mouseDetectionMode", "auto")
    if CF.mouseDetectionMode != "auto"
        throw Error("Le mode Automatique ne se rétablit pas.")
    CFDesktopSetPreference("floatShown", "1")
    if CF.overlayVisible
        throw Error("L'overlay devrait rester masqué au repos.")
    ; Vérifier l'affichage automatique pendant une vraie activation,
    ; avant de passer au mode permanent dans le reste du banc.
    target := Gui("+AlwaysOnTop", "ClickFlow target overlay test")
    target.Show("w240 h100")
    WinActivate("ahk_id " target.Hwnd)
    if !WinWaitActive("ahk_id " target.Hwnd, , 2)
        throw Error("Fenêtre cible de l'overlay inactive.")
    CF.cfg.hold := 2
    CF.pressed := false
    ActivationDown()
    if !CF.armed || !CF.overlayVisible || CF.overlayAlwaysVisible
        throw Error("L'overlay ne s'affiche pas pendant une activation normale.")
    ActivationUp()
    ActivationDown()
    if CF.armed || CF.engineTimerActive
        throw Error("Le profil Basculer ne s'arrête pas au deuxième appui.")
    target.Destroy()
    WinActivate("ahk_id " g.Hwnd)
    CF.overlayUntil := 0
    CFDesktopUpdate()
    if CF.overlayVisible
        throw Error("L'overlay reste visible après la fin de la session.")
    CFDesktopSetPreference("overlayAlwaysVisible", "1")
    if !CF.overlayVisible || !IsObject(CF.overlayGui)
        throw Error("L'overlay ne s'affiche pas en mode permanent.")
    hwnd := CF.overlayGui.Hwnd
    if !(WinGetExStyle("ahk_id " hwnd) & 0x20)
        throw Error("L'overlay n'est pas transparent aux clics.")

    ; Régression 1.8.0 : sous DPI élevé, les contrôles débordaient.
    ; Nouvelle exigence : overlay minuscule, une SEULE ligne et coins doux.
    m := CFOverlayMetrics()
    WinGetClientPos(, , &clientW, &clientH, "ahk_id " hwnd)
    if clientW != m.w || clientH != m.h
        throw Error("La taille réelle diffère du layout compact : "
            clientW "x" clientH " vs " m.w "x" m.h)
    if m.w > 225 || m.h > 36
        throw Error("L'overlay est trop grand pour un affichage discret.")
    CF.overlayStatusText.GetPos(&sx, &sy, &sw, &sh)
    CF.overlayCpsText.GetPos(&cx, &cy, &cw, &ch)
    if sx < 0 || cx <= sx + sw || cx + cw >= clientW
        || sy != cy || sy + sh > clientH || cy + ch > clientH
        throw Error("Les informations ne tiennent pas sur une seule ligne.")
    if !InStr(CF.overlayStatusText.Text, "ARR")
        || !InStr(CF.overlayCpsText.Text, "CPS")
        throw Error("Le statut ou les CPS ne s'affichent pas.")
    for dpi in [96, 120, 144, 192] {
        dims := CFOverlayMetrics(dpi)
        if dims.w != m.w || dims.h != m.h
            throw Error("Le DPI a agrandi l'overlay à " dpi ".")
        if dims.font < 4 || dims.font > 8
            throw Error("Police non adaptée au DPI " dpi ".")
        if dims.left + dims.statusW >= dims.cpsX
            || dims.cpsX + dims.cpsW >= dims.w
            || dims.top + dims.statusH >= dims.h
            || dims.top != dims.cpsTop
            throw Error("Chevauchement des deux textes à " dpi " DPI.")
    }
    ; Les coins doivent être légèrement arrondis, sans découper les textes.
    region := DllCall("gdi32\CreateRectRgn",
        "Int", 0, "Int", 0, "Int", 0, "Int", 0, "Ptr")
    statusRegion := DllCall("User32\GetWindowRgn",
        "Ptr", hwnd, "Ptr", region, "Int")
    if statusRegion = 0 || statusRegion = -1
        throw Error("La forme arrondie de l'overlay n'est pas appliquée.")
    if DllCall("gdi32\PtInRegion", "Ptr", region,
        "Int", 0, "Int", 0, "Int")
        throw Error("Le coin supérieur gauche n'est pas arrondi.")
    if !DllCall("gdi32\PtInRegion", "Ptr", region,
        "Int", 15, "Int", 15, "Int")
        throw Error("La forme arrondie masque le texte.")
    DllCall("gdi32\DeleteObject", "Ptr", region)
    if !CFDesktopStyleTitlebar(g.Hwnd)
        FileAppend("DWM titlebar unavailable; ", "*", "UTF-8")

    ; Positionnement prédéfini : six positions dans la zone de travail.
    for position in ["tl", "tm", "tr", "bl", "bm", "br"] {
        CFDesktopSetPreference("overlayPosition", position)
        expected := CFOverlayPositionCoords()
        WinGetPos(&actualX, &actualY, &w, &h, "ahk_id " hwnd)
        if Abs(actualX - expected.x) > 3 || Abs(actualY - expected.y) > 3
            throw Error("Mauvaise position " position)
        if Abs(w - m.w) > 3 || Abs(h - m.h) > 3
            throw Error("L'overlay ne doit pas changer de taille : " w "x" h)
    }

    ; Transparence libre : les valeurs intermédiaires ne sont pas des presets.
    ; Tailles et nom du profil facultatifs, mini préservé par défaut.
    if CF.overlaySize != "mini" || CF.overlayShowProfile
        throw Error("La taille mini et le nom masqué doivent rester par défaut.")
    for size in ["standard", "large", "mini"] {
        CFDesktopSetPreference("overlaySize", size)
        if CF.overlaySize != size
            throw Error("Taille overlay non appliquée : " size)
        metrics := CFOverlayMetrics()
        WinGetClientPos(, , &wClient, &hClient,
            "ahk_id " CF.overlayGui.Hwnd)
        if Abs(wClient - metrics.w) > 3 || Abs(hClient - metrics.h) > 3
            throw Error("Taille overlay incohérente : " size)
    }
    CFDesktopSetPreference("overlayShowProfile", "1")
    if !CF.overlayShowProfile || !CF.overlayNameText.Visible
        throw Error("Nom de profil non affiché en option.")
    CFDesktopSetPreference("overlayShowProfile", "0")
    if CF.overlayShowProfile || CF.overlayNameText.Visible
        throw Error("Le nom de profil n'est pas masqué.")
    CFDesktopSetPreference("overlayOpacity", "37")
    if CF.overlayOpacity != 37
        throw Error("Transparence personnalisée 37% refusée.")
    CFDesktopSetPreference("overlayOpacity", "0")
    if CF.overlayOpacity != 0
        throw Error("Transparence 0% refusée.")
    CFDesktopSetPreference("overlayOpacity", "100")
    CFDesktopSetPreference("overlayOpacity", "101")
    if CF.overlayOpacity != 100
        throw Error("Valeur 101% acceptée à tort.")
    CFDesktopSetPreference("overlayMargin", "27")
    if CF.overlayMargin != 27
        throw Error("Marge 27px refusée.")
    CFDesktopSetPreference("overlayMargin", "101")
    if CF.overlayMargin != 27
        throw Error("Marge 101px acceptée à tort.")

    if MonitorGetCount() > 1 {
        CFDesktopSetPreference("overlayMonitor", "2")
        if CF.overlayMonitor != 2
            throw Error("La sélection d'un second écran est impossible.")
    }
    ; Les changements de taille reconstruisent l'overlay. Les anciens HWND
    ; ne sont plus valides : reprendre le contrôle Windows courant.
    hwnd := CF.overlayGui.Hwnd
    m := CFOverlayMetrics()
    ; Déplacement manuel : clics traversants suspendus uniquement en édition.
    CFOverlaySetEdit(true)
    if !CF.overlayEditing || (WinGetExStyle("ahk_id " hwnd) & 0x20)
        throw Error("Le déplacement libre n'active pas les clics souris.")
    CFDesktopMonitorArea(CF.overlayMonitor, &left, &top, &right, &bottom)
    WinMove(left + 65, top + 65, m.w, m.h, "ahk_id " hwnd)
    CFOverlaySetEdit(false)
    if CF.overlayEditing || !(WinGetExStyle("ahk_id " hwnd) & 0x20)
        throw Error("L'overlay reste interactif après placement.")
    if CF.overlayPosition != "custom" || Abs(CF.overlayX - left - 65) > 4
        throw Error("La position libre n'est pas sauvegardée.")
    if IniRead(CF.configFile, "General", "OverlayPosition", "") != "custom"
        throw Error("La position libre est absente du INI.")

    ; Moyenne glissante sur 5s : ne pas confondre avec les CPS sur 1s.
    CF.armed := true
    CF.overlayStart := A_TickCount - 5000
    CF.overlayRecent := [A_TickCount - 4200, A_TickCount - 2100,
        A_TickCount - 800, A_TickCount - 200]
    if Abs(CFOverlayAverage(A_TickCount) - 0.8) > 0.01
        throw Error("CPS moyens 5s incorrects.")

    ; Tester plusieurs fenêtres glissantes et la validation stricte 1-60 s.
    ; Reconstituer des clics plus anciens pour chaque durée comme le
    ; ferait le moteur pendant une session prolongée.
    CFDesktopSetPreference("overlayAverageSeconds", "10")
    if CF.overlayAverageSeconds != 10
        throw Error("La période CPS de 10 s n'est pas appliquée.")
    CF.overlayStart := A_TickCount - 10000
    CF.overlayRecent := [A_TickCount - 9100, A_TickCount - 4200,
        A_TickCount - 1100, A_TickCount - 200]
    if Abs(CFOverlayAverage(A_TickCount) - 0.4) > 0.01
        throw Error("CPS moyens sur 10 s incorrects.")
    CFDesktopSetPreference("overlayAverageSeconds", "1")
    if Abs(CFOverlayAverage(A_TickCount) - 1.0) > 0.01
        throw Error("La période 1 s ne filtre pas les clics trop anciens.")
    CFDesktopSetPreference("overlayAverageSeconds", "60")
    CF.overlayStart := A_TickCount - 60000
    CF.overlayRecent := [A_TickCount - 59000, A_TickCount - 22000,
        A_TickCount - 9500, A_TickCount - 800]
    if CF.overlayAverageSeconds != 60
        || Abs(CFOverlayAverage(A_TickCount) - 0.1) > 0.01
        throw Error("La période CPS de 60 s est incorrecte.")
    for invalid in ["0", "61", "1.5", "abc", "-1"] {
        CFDesktopSetPreference("overlayAverageSeconds", invalid)
        if CF.overlayAverageSeconds != 60
            throw Error("Période invalide acceptée : " invalid)
    }
    CFDesktopSetPreference("overlayAverageSeconds", "5")
    CF.overlayStart := A_TickCount - 5000
    CF.overlayRecent := [A_TickCount - 4200, A_TickCount - 2100,
        A_TickCount - 800, A_TickCount - 200]
    if Abs(CFOverlayAverage(A_TickCount) - 0.8) > 0.01
        throw Error("La moyenne de 5 secondes n'est pas restaurée.")
    CFDesktopUpdate()
    if !CF.overlayVisible
        throw Error("Overlay absent pendant les clics.")
    if !InStr(CF.overlayStatusText.Text, "ACTIF")
        || !InStr(CF.overlayCpsText.Text, "0,8 CPS moy.")
        throw Error("Les statistiques réelles ne s'affichent pas dans l'overlay.")
    CF.armed := false
    CF.overlayAlwaysVisible := false
    CF.overlayUntil := 0
    CFDesktopUpdate()
    if CF.overlayVisible
        throw Error("Overlay automatique encore visible au repos.")

    ; Restaurer les options, réouvrir et vérifier la persistance.
    CFDesktopSetPreference("overlayAlwaysVisible", "1")
    CFDesktopSetPreference("overlayOpacity", "37")
    CFDesktopSetPreference("overlayAverageSeconds", "17")
    CFDesktopSetPreference("overlayMonitor", "1")
    CFDesktopReleaseFloat()
    g.Destroy()
    CFDesktopReadPreferences()
    if CF.overlayOpacity != 37 || !CF.floatShown
        || !CF.overlayAlwaysVisible || CF.overlayMargin != 27
        || CF.overlayAverageSeconds != 17
        throw Error("Les préférences overlay ne persistent pas.")
    if IniRead(CF.configFile, "General", "OverlayAverageSeconds", "") != "17"
        throw Error("La période de calcul CPS ne figure pas dans settings.ini.")

    FileDelete(CF.configFile)
    DirDelete(CF.profilesDir, true)
    FileAppend("Overlay free opacity, 6 positions, multi-monitor, drag, click-through, CPS avg and profiles passed.", "*", "UTF-8")
    ExitApp(0)
} catch as err {
    FileAppend("OVERLAY TEST FAILED: " err.Message " " err.File ":" err.Line, "*", "UTF-8")
    try CFDesktopReleaseFloat()
    try FileDelete(CF.configFile)
    try DirDelete(CF.profilesDir, true)
    ExitApp(1)
}
