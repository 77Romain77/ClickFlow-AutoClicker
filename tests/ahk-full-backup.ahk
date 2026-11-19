#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include ..\src\ClickFlow-Backend.ahk

global CF
CF.web := 0
CF.desktopReady := false
CF.loading := false
CF.shuttingDown := false
CF.configFile := A_Temp "\clickflow-full-backup-" A_TickCount ".ini"
CF.profilesDir := A_Temp "\clickflow-full-backup-profiles-" A_TickCount
CF.emergencyKey := "F12"
CF.profiles := [{id: 1, name: "Principal", favorite: true,
    sortOrder: 1, cfg: DefaultConfig()},
    {id: 2, name: "Autre", favorite: false,
    sortOrder: 2, cfg: DefaultConfig()}]
CF.selectedId := 1
CF.cfg := CF.profiles[1].cfg
CF.nextId := 3
CF.globalKeys := Map()
work := A_Temp "\clickflow-backup-regression-" A_TickCount
archive := work "\full.zip"
badArchive := work "\invalid.zip"
try {
    DirCreate(work)
    CFGlobalReadKeys()
    CF.globalKeys["overlay"] := "F9"
    CF.overlaySize := "standard"
    CF.overlayShowProfile := true
    CF.overlayOpacity := 73
    ; La sauvegarde doit restaurer une touche d'urgence explicitement vide.
    CF.emergencyKey := ""
    CF.profiles[1].cfg.min := 17
    SaveSettings()
    if !CFBackupExport(archive) || !FileExist(archive)
        throw Error("L'export ZIP complet a échoué.")
    if FileGetSize(archive) < 300
        throw Error("L'archive est suspectement petite.")
    ; Changer toutes les données ensuite : une restauration doit revenir
    ; au réglage du ZIP, sans conserver les modifications de session.
    CF.profiles[1].cfg.min := 5
    CF.overlaySize := "mini"
    CF.overlayOpacity := 40
    CF.emergencyKey := "F12"
    CF.globalKeys["overlay"] := ""
    CF.profiles[1].favorite := false
    SaveSettings()
    if !CFBackupRestore(archive, false)
        throw Error("Import ZIP complet non effectué.")
    if CF.profiles.Length != 2 || CF.profiles[1].cfg.min != 17
        throw Error("Les profils du ZIP ne sont pas restaurés.")
    if CF.overlaySize != "standard" || !CF.overlayShowProfile
        || CF.overlayOpacity != 73
        throw Error("Les options générales du ZIP ne sont pas restaurées.")
    if CF.globalKeys["overlay"] != "F9" || !CF.profiles[1].favorite
        throw Error("Les favoris ou raccourcis globaux ne sont pas restaurés.")
    if CF.emergencyKey != ""
        throw Error("La restauration a réactivé F12 alors que la sauvegarde contenait Aucun.")
    if IniRead(CF.configFile, "General", "EmergencyKey", "MISSING") != ""
        throw Error("La préférence Aucun n'a pas survécu à la restauration ZIP.")
    if IniRead(CF.configFile, "General", "GlobalOverlayKey", "") != "F9"
        throw Error("La restauration n'est pas persistée.")
    ; Un fichier arbitraire ne doit jamais remplacer la configuration.
    FileAppend("not a ZIP archive", badArchive, "UTF-8")
    failed := false
    try CFBackupRestore(badArchive, false)
    catch
        failed := true
    if !failed
        throw Error("Une archive non valide a été acceptée.")
    if CF.profiles[1].cfg.min != 17 || CF.overlayOpacity != 73
        throw Error("L'archive invalide a modifié les données actuelles.")
    CFGlobalUnregister()
    try UnregisterActivation()
    try UnregisterEmergency()
    FileDelete(CF.configFile)
    DirDelete(CF.profilesDir, true)
    DirDelete(work, true)
    FileAppend("Full ZIP backup and restore, profile settings, global keys, overlay and invalid archive rejection passed.", "*", "UTF-8")
    ExitApp(0)
} catch as err {
    try CFGlobalUnregister()
    try UnregisterActivation()
    try UnregisterEmergency()
    FileAppend("BACKUP TEST FAILED: " err.Message
        " " err.File ":" err.Line, "*", "UTF-8")
    try FileDelete(CF.configFile)
    try DirDelete(CF.profilesDir, true)
    try DirDelete(work, true)
    ExitApp(1)
}
