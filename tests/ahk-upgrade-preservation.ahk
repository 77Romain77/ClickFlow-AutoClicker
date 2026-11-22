#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include ..\src\ClickFlow-Backend.ahk

; Rechargement de donnees personnelles au format de la serie v1.9.33.
; Utilise seulement des repertoires temporaires, jamais APPDATA reel.
global CF
folder := A_Temp "\ClickFlow-Upgrade-1.10.0-" A_TickCount
CF.configFile := folder "\settings.ini"
CF.profilesDir := folder "\profiles"
CF.web := 0
CF.hwnd := 0
CF.loading := true
CF.shuttingDown := false
CF.emergencyKey := "F12"
CF.shortcutRecoveryWarnings := []
CF.globalKeys := Map()
CF.mainExpandedW := 1120
CF.mainExpandedH := 800
CF.mainCompactW := 480
CF.mainCompactH := 600

try {
    DirCreate(CF.profilesDir)
    firstCfg := DefaultConfig()
    firstCfg.min := 12.3
    firstCfg.max := 12.3
    first := {id:1, name:"Principal", favorite:true,
        sortOrder:1, cfg:firstCfg}
    secondCfg := DefaultConfig()
    secondCfg.mode := 2
    secondCfg.variation := 2
    secondCfg.min := 8
    secondCfg.max := 10
    secondCfg.activation := "F7"
    secondCfg.mouseGate := 1
    secondCfg.gateButton := "RButton"
    second := {id:7, name:"Naturel conserve", favorite:false,
        sortOrder:2, cfg:secondCfg}
    CFWriteProfile(first)
    CFWriteProfile(second)
    originalOne := FileRead(CFProfileFile(1), "UTF-8")
    originalSeven := FileRead(CFProfileFile(7), "UTF-8")

    ; Parametres enregistres au format v1.9.33 (StorageVersion 2).
    IniWrite("2", CF.configFile, "Profiles", "StorageVersion")
    IniWrite("1,7", CF.configFile, "Profiles", "Ids")
    IniWrite("7", CF.configFile, "Profiles", "Selected")
    IniWrite("9", CF.configFile, "Profiles", "NextId")
    IniWrite("", CF.configFile, "General", "EmergencyKey")
    IniWrite("F9", CF.configFile, "General", CFGlobalIniKey("overlay"))
    IniWrite("F10", CF.configFile, "General", CFGlobalIniKey("next"))
    IniWrite("1", CF.configFile, "General", "CompactMode")
    IniWrite("1", CF.configFile, "General", "CloseToTray")
    IniWrite("event", CF.configFile, "General", "MouseDetectionMode")
    IniWrite("standard", CF.configFile, "General", "OverlaySize")
    IniWrite("77", CF.configFile, "General", "OverlayOpacity")
    IniWrite("1", CF.configFile, "General", "OverlayShowProfile")

    ; Suivre le meme ordre que BackendInit lors d'un vrai demarrage.
    CF.compactMode := IniRead(CF.configFile, "General", "CompactMode", "0") = "1"
    CFLoadEmergencyShortcut()
    LoadSettings()
    CFDesktopReadPreferences()
    CFGlobalReadKeys()
    if CF.profiles.Length != 2 || CF.selectedId != 7 || CF.nextId != 9
        throw Error("Les profils ou leur ordre de selection ont change.")
    if CF.cfg.mode != 2 || CF.cfg.min != 8 || CF.cfg.max != 10
        || CF.cfg.variation != 2 || CF.cfg.activation != "F7"
        || !CF.cfg.mouseGate || CF.cfg.gateButton != "RButton"
        throw Error("Le profil Naturel a perdu des parametres.")
    if !CFProfileById(1).favorite || CFProfileById(1).cfg.min != 12.3
        throw Error("Le profil Principal a perdu des parametres.")
    if CF.emergencyKey != "" || CF.globalKeys["overlay"] != "F9"
        || CF.globalKeys["next"] != "F10"
        throw Error("Les raccourcis ou le choix Aucun ont change.")
    if !CF.compactMode || !CF.closeToTray
        || CF.mouseDetectionMode != "event"
        || CF.overlayOpacity != 77 || CF.overlaySize != "standard"
        || !CF.overlayShowProfile
        throw Error("Les preferences de fenetre ont change.")
    if CF.profileRecoveryWarnings.Length
        || CF.shortcutRecoveryWarnings.Length
        throw Error("Des parametres valides ont ete rejetes.")
    if FileRead(CFProfileFile(1), "UTF-8") != originalOne
        || FileRead(CFProfileFile(7), "UTF-8") != originalSeven
        throw Error("Le simple chargement a reecrit les profils existants.")

    CF.loading := false
    SaveSettings()
    if IniRead(CF.configFile, "Profiles", "Selected", "") != "7"
        || IniRead(CF.configFile, "Profiles", "NextId", "") != "9"
        || IniRead(CF.configFile, "General", "EmergencyKey", "MISSING") != ""
        || IniRead(CF.configFile, "General", CFGlobalIniKey("overlay"), "") != "F9"
        throw Error("La sauvegarde apres mise a jour n'est pas persistante.")
    savedMin := IniRead(CFProfileFile(7), "Settings", "min", "")
    savedActivation := IniRead(CFProfileFile(7), "Settings", "activation", "")
    if savedMin = "" || Abs((savedMin + 0) - 8) > 0.001
        || savedActivation != "F7"
        throw Error("La sauvegarde a altere le profil Naturel : min="
            savedMin ", activation=" savedActivation)

    ; Simuler le redemarrage de la nouvelle version sur les memes fichiers.
    CF.loading := true
    CF.emergencyKey := "F12"
    CF.compactMode := false
    CF.shortcutRecoveryWarnings := []
    CF.globalKeys := Map()
    CF.profiles := []
    CF.selectedId := 0
    ; Suivre le meme ordre que BackendInit lors d'un vrai demarrage.
    CF.compactMode := IniRead(CF.configFile, "General", "CompactMode", "0") = "1"
    CFLoadEmergencyShortcut()
    LoadSettings()
    CFDesktopReadPreferences()
    CFGlobalReadKeys()
    if CF.profiles.Length != 2 || CF.selectedId != 7
        || CF.cfg.activation != "F7"
        || CFProfileById(1).name != "Principal"
        || CF.globalKeys["overlay"] != "F9" || CF.emergencyKey != ""
        || CF.mouseDetectionMode != "event"
        throw Error("Les donnees ne survivent pas au redemarrage.")
    DirDelete(folder, true)
    FileAppend("Upgrade v1.9.33 to v1.10.0: profiles, CPS settings, shortcuts, overlay and restart passed.", "*", "UTF-8")
    ExitApp(0)
} catch as err {
    FileAppend("UPGRADE REGRESSION FAILED: " err.Message " ("
        err.File ":" err.Line ")", "*", "UTF-8")
    try DirDelete(folder, true)
    ExitApp(1)
}
