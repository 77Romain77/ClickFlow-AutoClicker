#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include ..\src\ClickFlow-Backend.ahk

; Regression Windows : preferences indépendantes, favoris, ordre, panneau
; flottant, menu zone de notification et réglages rapides atomiques.
global CF
CF.web := 0
CF.loading := false
CF.shuttingDown := false
CF.configFile := A_Temp "\clickflow-1.6-workspace-" A_TickCount ".ini"
CF.profilesDir := A_Temp "\clickflow-1.6-workspace-profiles-" A_TickCount
CF.profiles := [{id: 3, name: "Profil A", cfg: DefaultConfig()},
    {id: 7, name: "Profil B", cfg: DefaultConfig()},
    {id: 11, name: "Profil C", cfg: DefaultConfig()}]
CF.selectedId := 3
CF.cfg := CF.profiles[1].cfg
CF.nextId := 12

try {
    CFDesktopReadPreferences()
    if CF.closeToTray || CF.minimizeToTray || CF.floatShown
        throw Error("Les préférences qui masquent la fenêtre doivent être désactivées par défaut.")
    if !CF.liveMonitor
        throw Error("Le moniteur CPS doit être activé par défaut.")

    SaveSettings()
    CFToggleProfileFavorite(7)
    if !CF.profiles[2].favorite
        throw Error("Favori non activé.")
    CFReorderProfile(11, "up")
    CFReorderProfile(11, "up")
    if CF.profiles[1].id != 11 || CF.selectedId != 3
        throw Error("Réorganisation invalide ou sélection perdue.")
    if IniRead(CFProfileFile(7), "ClickFlowProfile", "Favorite", "") != "1"
        throw Error("Favori non enregistré dans le fichier profil.")
    CF.profiles := []
    if !CFLoadSeparatedProfiles()
        throw Error("Chargement des profils impossible.")
    if CF.profiles[1].id != 11 || CF.profiles[2].id != 3
        throw Error("L'ordre des profils n'a pas été conservé.")
    if !CFProfileById(7).favorite
        throw Error("Le favori ne survit pas au redémarrage.")

    ; Tester les edits atomiques sans écraser activation ni garde souris.
    CFProfileById(7).cfg.activation := "F9"
    CFProfileById(7).cfg.mouseGate := 1
    CFApplyQuickSettings("7", "natural", "9", "18", "high")
    saved := CFProfileById(7).cfg
    if saved.min != 9 || saved.max != 18 || saved.mode != 3
        || saved.variation != 3 || saved.activation != "F9" || !saved.mouseGate
        throw Error("Réglages rapides non appliqués ou champs non ciblés altérés.")
    rejected := false
    try CFApplyQuickSettings("7", "natural", "99", "3", "high")
    catch
        rejected := true
    if !rejected || saved.min != 9
        throw Error("Un réglage invalide a modifié le profil.")

    ; La fenêtre flottante est optionnelle et partage le moteur existant.
    g := Gui("+Resize", "ClickFlow-test-workspace")
    g.Show("w540 h700")
    CF.hwnd := g.Hwnd
    CFDesktopInit()
    CFDesktopSetPreference("liveMonitor", "0")
    CFDesktopSetPreference("minimizeToTray", "1")
    CFDesktopSetPreference("closeToTray", "1")
    CFDesktopSetPreference("floatShown", "1")
    if !IsObject(CF.floatGui) || !CF.floatShown
        throw Error("Mini-fenêtre non affichée.")
    CFDesktopUpdate()
    if !CFDesktopStyleTitlebar(g.Hwnd)
        FileAppend("DWM dark caption unavailable on this Windows version. ", "*", "UTF-8")
    if !CF.floatProfile || !CF.floatStop || !CF.floatGraphButton
        throw Error("Contrôles de la mini-fenêtre incomplets.")
    if CF.floatX != -99999
        throw Error("Position de fenêtre par défaut incorrecte.")
    CFDesktopSetPreference("floatGraph", "1")
    CF.floatGui.Show("NA w420 h340")
    WinGetClientPos(, , &clientW, &clientH, "ahk_id " CF.floatGui.Hwnd)
    CFDesktopResizeFloat(CF.floatGui, 0, clientW, clientH)
    if !CF.floatChart.Visible
        throw Error("La courbe ne s'affiche pas lors de l'agrandissement.")
    ; Le bitmap GDI utilise les CPS de l'unique moteur et reste en mémoire.
    CF.floatPoints := [{t: A_TickCount - 600, cps: 10},
        {t: A_TickCount - 400, cps: 12},
        {t: A_TickCount - 200, cps: 8}]
    CFDesktopDrawFloatChart()
    if !CF.floatBitmap
        throw Error("La courbe CPS native n'a pas été dessinée.")
    ; Vérifier que le contrôle expose vraiment SS_BITMAP et affiche le bitmap.
    chartStyle := DllCall("User32\GetWindowLongPtrW",
        "Ptr", CF.floatChart.Hwnd, "Int", -16, "Ptr")
    if (chartStyle & 0xF) != 0xE
        throw Error("La courbe n'a pas le style Windows SS_BITMAP.")
    attached := SendMessage(0x173, 0, 0, ,
        "ahk_id " CF.floatChart.Hwnd)
    if !attached || attached != CF.floatBitmap
        throw Error("Le bitmap dessiné n'est pas réellement affiché dans la mini-fenêtre.")
    if !CF.floatStopBg || !CF.floatGraphBg
        throw Error("Les boutons colorés de la mini-fenêtre sont absents.")
    CFDesktopSetPreference("floatOpacity", "80")
    CFDesktopSetPreference("floatTopMost", "0")
    if CF.floatOpacity != 80 || CF.floatTopMost
        throw Error("Opacité ou toujours-au-premier-plan incorrect.")
    CFDesktopSaveFloatBounds()
    savedW := CF.floatWidth
    savedH := CF.floatHeight
    if savedW < 415 || savedH < 330
        throw Error("Les dimensions redimensionnées ne sont pas mémorisées.")
    CFDesktopSetFloat(false)
    if CF.floatShown
        throw Error("La mini-fenêtre ne peut pas se masquer.")
    if IniRead(CF.configFile, "General", "FloatWidth", "") != savedW
        throw Error("La largeur flottante n'est pas sauvegardée.")
    if IniRead(CF.configFile, "General", "FloatHeight", "") != savedH
        throw Error("La hauteur flottante n'est pas sauvegardée.")
    CFDesktopSetPreference("compactChart", "0")
    CFDesktopSetFloat(true)
    WinGetClientPos(, , &restoredW, &restoredH, "ahk_id " CF.floatGui.Hwnd)
    if Abs(restoredW - savedW) > 5 || Abs(restoredH - savedH) > 5
        throw Error("Les dimensions flottantes ne sont pas restaurées.")
    CFDesktopSetFloat(false)
    if CF.total != 0 || CF.armed
        throw Error("Le panneau de bureau a déclenché le moteur.")
    CF.desktopReady := false
    CFDesktopReleaseFloat()
    g.Destroy()
    CFDesktopReadPreferences()
    if !CF.closeToTray || !CF.minimizeToTray || CF.liveMonitor || CF.floatShown
        || !CF.floatGraph || CF.floatTopMost || CF.floatOpacity != 80
        || CF.compactChart || CF.floatWidth != savedW || CF.floatHeight != savedH
        throw Error("Les préférences et dimensions ne persistent pas.")
    if IniRead(CF.configFile, "General", "FloatShown", "?") != "0"
        throw Error("L'option mini-fenêtre a perdu son état.")

    FileDelete(CF.configFile)
    DirDelete(CF.profilesDir, true)
    FileAppend("Workspace profile order/favorites, atomic quick settings and Windows desktop preferences passed.", "*", "UTF-8")
    ExitApp(0)
} catch as err {
    FileAppend("WORKSPACE TEST FAILED: " err.Message " " err.File ":" err.Line, "*", "UTF-8")
    try FileDelete(CF.configFile)
    try DirDelete(CF.profilesDir, true)
    ExitApp(1)
}
