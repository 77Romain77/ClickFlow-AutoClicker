#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include ..\src\ClickFlow-Backend.ahk

; Tests sans clics : persistance des reglages globaux et mode de fenetre.
global CF
CF.loading := false
CF.configFile := A_Temp "\clickflow-1.2.0-test-" A_TickCount ".ini"
CF.profilesDir := A_Temp "\clickflow-1.2.0-profiles-" A_TickCount
CF.emergencyKey := "F10"
CF.compactMode := true
CF.profiles := [{id: 1, name: "Principal", cfg: DefaultConfig()}]
CF.selectedId := 1
CF.nextId := 2
CF.cfg := CF.profiles[1].cfg

try {
    if !SameKey("F10", "vk79")
        throw Error("La comparaison des touches F10/vk79 est incorrecte.")
    if SameKey("F10", "F12")
        throw Error("Deux touches differentes ont ete confondues.")

    SaveSettings()
    if IniRead(CF.configFile, "General", "EmergencyKey", "") != "F10"
        throw Error("La touche d'urgence n'est pas sauvegardee.")
    if IniRead(CF.configFile, "General", "CompactMode", "") != "1"
        throw Error("Le mode compact n'est pas sauvegarde.")

    ; Une touche d'activation identique a l'arret d'urgence est refusee au chargement.
    IniWrite("F10", CFProfileFile(1), "Settings", "activation")
    parsed := ReadConfig(CFProfileFile(1), "Settings", DefaultConfig())
    if SameKey(parsed.activation, CF.emergencyKey)
        throw Error("Un raccourci d'activation bloque l'arret d'urgence.")

    g := Gui("+Resize +MinSize460x480", "ClickFlow-test-view")
    g.Show("w900 h760")
    CF.hwnd := g.Hwnd
    CF.shuttingDown := false

    ; Les deux modes possèdent désormais des tailles indépendantes.
    CF.mainCompactW := 480
    CF.mainCompactH := 580
    CF.mainExpandedW := 900
    CF.mainExpandedH := 760
    CF.compactMode := false
    CFDesktopRestoreMainBounds()
    WinGetPos(, , &wideW, &wideH, "ahk_id " g.Hwnd)
    ; Windows CI peut limiter la hauteur d'une fenêtre à la surface de
    ; l'écran ; comparer ensuite au rectangle réellement obtenu.
    CFDesktopMonitorArea(MonitorGetPrimary(), &left, &top, &right, &bottom)
    expectedW := Min(900, Max(460, right - left - 36))
    expectedH := Min(760, Max(420, bottom - top - 36))
    if Abs(wideW - expectedW) > 6 || Abs(wideH - expectedH) > 6
        throw Error("La taille étendue doit respecter l'espace visible : "
            wideW "x" wideH " attendu " expectedW "x" expectedH)

    ; Simuler un passage étendu -> compact, puis le retour étendu.
    CFDesktopCaptureMainBounds(false)
    CF.compactMode := true
    ApplyWindowMode()
    WinGetPos(, , &w, &h, "ahk_id " g.Hwnd)
    if Abs(w - 480) > 6 || Abs(h - 580) > 6
        throw Error("La taille du mode compact est incorrecte : " w "x" h)

    CFDesktopCaptureMainBounds(true)
    CF.compactMode := false
    ApplyWindowMode()
    WinGetPos(, , &w, &h, "ahk_id " g.Hwnd)
    if Abs(w - wideW) > 6 || Abs(h - wideH) > 6
        throw Error("La taille du mode étendu n'est pas restaurée : " w "x" h)

    ; Redimensionner manuellement chaque mode et vérifier la persistance.
    WinMove(, , 940, 730, "ahk_id " g.Hwnd)
    CFDesktopCaptureMainBounds(false)
    CF.compactMode := true
    ApplyWindowMode()
    WinMove(, , 480, 520, "ahk_id " g.Hwnd)
    CFDesktopCaptureMainBounds(true)
    CF.compactMode := false
    ApplyWindowMode()
    WinGetPos(, , &w, &h, "ahk_id " g.Hwnd)
    expectedW := Min(CF.mainExpandedW, Max(460, right - left - 36))
    expectedH := Min(CF.mainExpandedH, Max(420, bottom - top - 36))
    if Abs(w - expectedW) > 6 || Abs(h - expectedH) > 6
        throw Error("Les dimensions étendues ne sont pas adaptées à l'écran.")
    if Abs(CF.mainCompactW - 480) > 6 || Abs(CF.mainCompactH - 520) > 6
        throw Error("Les dimensions personnalisées du mode compact sont perdues.")

    SaveSettings()
    if IniRead(CF.configFile, "General", "MainExpandedWidth", "") != CF.mainExpandedW
        throw Error("La taille étendue n'est pas sauvegardée.")
    if IniRead(CF.configFile, "General", "MainCompactWidth", "") != CF.mainCompactW
        throw Error("La taille compacte n'est pas sauvegardée.")
    g.Destroy()
    FileDelete(CF.configFile)
    DirDelete(CF.profilesDir, true)
    FileAppend("Global settings and view switching passed.", "*", "UTF-8")
    ExitApp(0)
} catch as err {
    FileAppend("REGRESSION FAILURE: " err.Message, "*", "UTF-8")
    try FileDelete(CF.configFile)
    try DirDelete(CF.profilesDir, true)
    ExitApp(1)
}
