#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include ..\src\ClickFlow-Backend.ahk

; Emergency key is optional, but the user-facing and tray STOP paths remain.
global CF
CF.web := 0
CF.desktopReady := false
CF.loading := false
CF.shuttingDown := false
CF.configFile := A_Temp "\clickflow-optional-stop-" A_TickCount ".ini"
CF.profilesDir := A_Temp "\clickflow-optional-stop-profiles-" A_TickCount
CF.emergencyKey := "F12"
CF.profiles := [{id: 1, name: "Principal", cfg: DefaultConfig()},
    {id: 2, name: "Secondaire", cfg: DefaultConfig()}]
CF.profiles[2].cfg.activation := "F7"
CF.selectedId := 1
CF.cfg := CF.profiles[1].cfg
CF.nextId := 3
CF.globalKeys := Map()
try {
    CFGlobalReadKeys()
    RegisterEmergency()
    CFSetEmergencyKey("")
    if CF.emergencyKey != ""
        throw Error("Aucun ne vide pas la touche d'arrêt d'urgence.")
    if IniRead(CF.configFile, "General", "EmergencyKey", "MISSING") != ""
        throw Error("La valeur Aucun n'est pas sauvegardée dans settings.ini.")
    ; Sans touche d'urgence, F12 redevient attribuable à une autre action.
    CFGlobalSet("overlay", "F12")
    if CF.globalKeys["overlay"] != "F12"
        throw Error("F12 reste bloquée malgré le choix Aucun.")
    rejected := false
    try CFSetEmergencyKey("F12")
    catch
        rejected := true
    if !rejected || CF.emergencyKey != ""
        throw Error("Un conflit avec un raccourci global a été accepté.")
    CFGlobalSet("overlay", "")
    for collision in ["F6", "F7"] {
        rejected := false
        try CFSetEmergencyKey(collision)
        catch
            rejected := true
        if !rejected
            throw Error("Un conflit de profil a été accepté : " collision)
    }
    CFSetEmergencyKey("F11")
    if CF.emergencyKey != "F11"
        throw Error("Une nouvelle touche d'urgence ne fonctionne pas.")
    CFSetEmergencyKey("")
    ; Redémarrage simulé : le champ vide reste vide et ne revient pas à F12.
    value := IniRead(CF.configFile, "General", "EmergencyKey", "F12")
    if value != ""
        throw Error("Le redémarrage réactive F12 au lieu de conserver Aucun.")
    ; Un arrêt sans touche reste accessible depuis les commandes principales.
    CF.armed := false
    EmergencyStop()
    CFDesktopStop()
    if CF.armed
        throw Error("Le bouton/menu STOP a cessé de fonctionner.")
    CFGlobalUnregister()
    UnregisterActivation()
    UnregisterEmergency()
    FileDelete(CF.configFile)
    DirDelete(CF.profilesDir, true)
    FileAppend("Optional emergency key: Aucun, save/reload, conflict checks, reassign and UI/tray stop passed.", "*", "UTF-8")
    ExitApp(0)
} catch as err {
    try CFGlobalUnregister()
    try UnregisterActivation()
    try UnregisterEmergency()
    FileAppend("OPTIONAL STOP TEST FAILED: " err.Message
        " " err.File ":" err.Line, "*", "UTF-8")
    try FileDelete(CF.configFile)
    try DirDelete(CF.profilesDir, true)
    ExitApp(1)
}
