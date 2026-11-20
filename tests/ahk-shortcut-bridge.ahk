#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include ..\src\ClickFlow-Backend.ahk

class BridgeArgs {
    __New(raw) {
        this.raw := raw
    }
    TryGetWebMessageAsString() {
        return this.raw
    }
}
PostShortcutCommand(args*) {
    global CFBridgeLastRaw
    raw := ""
    for item in args
        raw .= (raw = "" ? "" : Chr(9)) item
    CFBridgeLastRaw := raw
    if StrSplit(raw, Chr(9)).Length < 3
        throw Error("Le test ne produit pas une commande tabulée : " StrReplace(raw, Chr(9), "|"))
    BackendMessage("", BridgeArgs(raw))
}

global CF
CF.web := 0
CF.desktopReady := false
CF.loading := false
CF.shuttingDown := false
CF.configFile := A_Temp "\clickflow-bridge-hotkeys-" A_TickCount ".ini"
CF.profilesDir := A_Temp "\clickflow-bridge-hotkeys-profiles-" A_TickCount
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
    RegisterActivation()
    ; Tester les commandes réellement envoyées par l'interface WebView2.
    PostShortcutCommand("globalHotkey", "begin", "next")
    if !CF.capture || CF.captureKind != "global:next"
        throw Error("La commande begin n'est pas reçue. CF.capture=" CF.capture " notice=" CF.notice " kind=" CF.captureKind " payload=" StrReplace(CFBridgeLastRaw, Chr(9), "|") " cmd=" StrSplit(CFBridgeLastRaw, Chr(9))[1])
    PostShortcutCommand("globalHotkey", "set", "next", "vk78")
    if CF.capture || GetKeyVK(CF.globalKeys["next"]) != GetKeyVK("F9")
        throw Error("La touche F9 envoyée par WebView2 n'est pas configurée.")
    if IniRead(CF.configFile, "General", "GlobalNextKey", "") != "vk78"
        throw Error("La touche globale WebView2 n'est pas sauvegardée.")
    PostShortcutCommand("globalHotkey", "begin", "previous")
    PostShortcutCommand("globalHotkey", "set", "previous", "vk78")
    if CF.globalKeys["previous"] != "" || CF.capture
        throw Error("Le conflit de touche WebView2 n'a pas été refusé.")
    PostShortcutCommand("globalHotkey", "begin", "previous")
    PostShortcutCommand("globalHotkey", "cancel")
    if CF.capture || CF.globalKeys["previous"] != ""
        throw Error("Échap n'annule pas proprement une capture.")
    PostShortcutCommand("globalHotkey", "begin", "emergency")
    PostShortcutCommand("globalHotkey", "set", "emergency", "vk7B")
    if CF.emergencyKey != "vk7B" || CF.capture
        throw Error("La réaffectation d'urgence depuis WebView2 a échoué.")
    PostShortcutCommand("globalHotkey", "clear", "emergency")
    if CF.emergencyKey != ""
        throw Error("Le bouton Aucun de l'urgence ne désactive pas la touche.")
    if IniRead(CF.configFile, "General", "EmergencyKey", "MISSING") != ""
        throw Error("Le bouton Aucun n'est pas persisté.")
    PostShortcutCommand("globalHotkey", "clear", "next")
    if CF.globalKeys["next"] != ""
        throw Error("Le bouton Aucun des autres actions ne fonctionne pas.")
    ; Vérifier le cas clic sur Aucun pendant une capture active.
    PostShortcutCommand("globalHotkey", "begin", "emergency")
    PostShortcutCommand("globalHotkey", "clear", "emergency")
    if CF.capture || CF.emergencyKey != ""
        throw Error("Aucun ne réinitialise pas une capture active.")
    CFGlobalUnregister()
    UnregisterActivation()
    UnregisterEmergency()
    FileDelete(CF.configFile)
    DirDelete(CF.profilesDir, true)
    FileAppend("WebView2 bridge begin/set/cancel/clear, conflicts and persisted Aucun passed.", "*", "UTF-8")
    ExitApp(0)
} catch as err {
    try CFGlobalUnregister()
    try UnregisterActivation()
    try UnregisterEmergency()
    FileAppend("SHORTCUT BRIDGE TEST FAILED: " err.Message " " err.File ":" err.Line, "*", "UTF-8")
    try FileDelete(CF.configFile)
    try DirDelete(CF.profilesDir, true)
    ExitApp(1)
}
