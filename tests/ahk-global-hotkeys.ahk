#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include ..\src\ClickFlow-Backend.ahk

global CF
CF.web := 0
CF.desktopReady := false
CF.loading := false
CF.shuttingDown := false
CF.configFile := A_Temp "\clickflow-global-keys-" A_TickCount ".ini"
CF.profilesDir := A_Temp "\clickflow-global-keys-profiles-" A_TickCount
CF.emergencyKey := "F12"
CF.profiles := [{id: 1, name: "Principal", cfg: DefaultConfig()},
    {id: 2, name: "Autre", cfg: DefaultConfig()}]
CF.profiles[2].cfg.activation := "F7"
CF.selectedId := 1
CF.cfg := CF.profiles[1].cfg
CF.globalKeys := Map()
CF.nextId := 3
try {
    CFGlobalReadKeys()
    for action in CFGlobalKeys()
        if CF.globalKeys[action] != ""
            throw Error("Raccourci " action " ne doit PAS être attribué par défaut.")
    if !InStr(CFGlobalJson(), '"next":""')
        throw Error("La valeur Aucun n'est pas sérialisée.")
    CFGlobalSet("next", "F8")
    CFGlobalSet("previous", "F9")
    CFGlobalSet("overlay", "F10")
    CFGlobalSet("open", "F11")
    for conflict in ["F8", "F12", "F6", "F7"] {
        failed := false
        try CFGlobalSet("test", conflict)
        catch
            failed := true
        if !failed
            throw Error("Un conflit de raccourci a été accepté : " conflict)
    }
    CFGlobalTrigger("next")
    if CF.selectedId != 2
        throw Error("Raccourci Profil suivant n'a pas changé le profil.")
    CFGlobalTrigger("previous")
    if CF.selectedId != 1
        throw Error("Raccourci Profil précédent n'a pas changé le profil.")
    CFGlobalSet("next", "")
    if CF.globalKeys["next"] != ""
        throw Error("La commande Aucun ne désactive pas le raccourci.")
    if IniRead(CF.configFile, "General", "GlobalNextKey", "?") != ""
        throw Error("La désactivation n'est pas persistée.")
    CFGlobalUnregister()
    CF.globalKeys := Map()
    CFGlobalReadKeys()
    if CF.globalKeys["next"] != "" || CF.globalKeys["previous"] != "F9"
        throw Error("Les affectations optionnelles ne survivent pas au redémarrage.")
    ; Anciens fichiers INI : raccourcis non reconnus, modificateurs
    ; injectés ou valeurs réservées ne doivent pas bloquer le démarrage.
    IniWrite("UnknownDefinitelyInvalid", CF.configFile, "General", "GlobalTestKey")
    IniWrite("^F6", CF.configFile, "General", "GlobalOverlayKey")
    CFGlobalReadKeys()
    if CF.globalKeys["test"] != "" || CF.globalKeys["overlay"] != ""
        throw Error("Des raccourcis globaux invalides ont été chargés.")
    if CF.globalKeys["previous"] != "F9"
        throw Error("Un raccourci valide a été effacé par la récupération.")
    if !CF.HasOwnProp("shortcutRecoveryWarnings")
        || CF.shortcutRecoveryWarnings.Length < 2
        throw Error("Les raccourcis corrigés ne sont pas signalés.")
    CFGlobalRegister()
    CFGlobalUnregister()
    try UnregisterActivation()
    try UnregisterEmergency()
    FileDelete(CF.configFile)
    DirDelete(CF.profilesDir, true)
    FileAppend("Optional global keys, no default assignments, clear, persistence, actions and conflicts passed.", "*", "UTF-8")
    ExitApp(0)
} catch as err {
    try CFGlobalUnregister()
    try UnregisterActivation()
    try UnregisterEmergency()
    FileAppend("GLOBAL HOTKEY TEST FAILED: " err.Message
        " " err.File ":" err.Line, "*", "UTF-8")
    try FileDelete(CF.configFile)
    try DirDelete(CF.profilesDir, true)
    ExitApp(1)
}
