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
    CFDesktopSetFloat(false)
    if CF.floatShown
        throw Error("La mini-fenêtre ne peut pas se masquer.")
    if CF.total != 0 || CF.armed
        throw Error("Le panneau de bureau a déclenché le moteur.")
    CF.desktopReady := false
    CF.floatGui.Destroy()
    g.Destroy()
    CFDesktopReadPreferences()
    if !CF.closeToTray || !CF.minimizeToTray || CF.liveMonitor || CF.floatShown
        throw Error("Les préférences générales ne persistent pas.")
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
