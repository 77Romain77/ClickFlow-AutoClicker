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
    g.Show("w900 h800")
    CF.hwnd := g.Hwnd
    ApplyWindowMode()
    WinGetPos(, , &w, &h, "ahk_id " g.Hwnd)
    if Abs(w - 540) > 6 || Abs(h - 700) > 6
        throw Error("La taille compacte n'est pas respectee: " w "x" h)
    CF.compactMode := false
    ApplyWindowMode()
    WinGetPos(, , &w, &h, "ahk_id " g.Hwnd)
    ; Sur les machines CI 1024x768, Windows limite la taille demandee
    ; a l'espace du bureau. La fenetre doit toutefois etre bien plus
    ; grande que le mode compact.
    if w < 900 || h < 730
        throw Error("La taille etendue n'est pas respectee: " w "x" h)
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
