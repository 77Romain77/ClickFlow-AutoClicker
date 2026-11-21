#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include ..\src\ClickFlow-Backend.ahk

; Vérifie les dixièmes de CPS sur les trois modes historiques et les profils.
; Aucun clic Windows réel n'est envoyé.
global CF
CF.web := 0
CF.loading := true
CF.shuttingDown := false
CF.armed := false
CF.test := {active: false}
CF.total := 0
CF.cfg := DefaultConfig()
CF.emergencyKey := "F12"

tempDir := A_Temp "\ClickFlow-Decimal-Tests-" A_TickCount
try {
    DirCreate(tempDir)
    CF.configFile := tempDir "\settings.ini"
    CF.profilesDir := tempDir "\profiles"
    cfg := DefaultConfig()
    cfg.mode := 1
    cfg.min := 12.5
    cfg.max := 12.5
    CFNaturalReset(cfg)
    if GetNextCps(cfg, 1000) != 12.5 || GetNextIntervalMs(cfg, 1000) != 80
        throw Error("Fixe 12.5 CPS ne donne pas un intervalle de 80 ms.")

    cfg.mode := 2
    cfg.min := 8.4
    cfg.max := 11.7
    seen := Map()
    Loop 150 {
        n := GetNextCps(cfg, 1000 + A_Index)
        if n < 8.4 || n > 11.7
            throw Error("Aléatoire dépasse ses limites décimales.")
        seen[Round(n, 2)] := true
    }
    if seen.Count < 8
        throw Error("Aléatoire ne varie pas avec des limites décimales.")

    cfg.mode := 3
    cfg.min := 12.5
    cfg.max := 12.5
    CFNaturalReset(cfg)
    Loop 30
        if GetNextCps(cfg, 10000 + A_Index * 100) != 12.5
            throw Error("Naturel min=max décimal ne respecte pas sa cible.")

    cfg.mode := 2
    cfg.min := 8.4
    cfg.max := 11.7
    CFWriteProfile({id: 1, name: "Décimal", cfg: cfg})
    loaded := ReadConfig(CFProfileFile(1), "Settings", DefaultConfig())
    if loaded.min != 8.4 || loaded.max != 11.7 || loaded.mode != 2
        throw Error("La sauvegarde/relecture INI a perdu les décimales.")
    if CopyConfig(loaded).min != 8.4
        throw Error("La duplication du profil a perdu les décimales.")

    ; Les anciennes sauvegardes avec des entiers restent compatibles.
    IniWrite("9", CFProfileFile(1), "Settings", "min")
    IniWrite("14", CFProfileFile(1), "Settings", "max")
    old := ReadConfig(CFProfileFile(1), "Settings", DefaultConfig())
    if old.min != 9 || old.max != 14
        throw Error("Les anciens profils entiers ne se rechargent pas.")

    ; La modification atomique depuis Test CPS accepte des décimales
    ; mais pas 12.34, ni min > max, ni des valeurs hors limites.
    CF.profiles := [{id: 1, name: "Décimal", cfg: loaded}]
    CF.selectedId := 1
    CF.cfg := loaded
    CFApplyQuickSettings("1", "natural", "10.3", "16.8", "medium")
    if CF.cfg.min != 10.3 || CF.cfg.max != 16.8 || CF.cfg.mode != 3
        throw Error("Le réglage rapide perd les dixièmes de CPS.")
    bad := false
    try CFApplyQuickSettings("1", "fixed", "10.33", "12", "low")
    catch
        bad := true
    if !bad
        throw Error("Le réglage rapide accepte deux décimales.")
    bad := false
    try CFApplyQuickSettings("1", "random", "15.5", "14.2", "medium")
    catch
        bad := true
    if !bad
        throw Error("Le réglage rapide accepte min > max.")

    try DirDelete(tempDir, true)
    FileAppend("Decimal CPS fixed, random, natural, INI migration and quick settings passed.", "*", "UTF-8")
    ExitApp(0)
} catch as err {
    try DirDelete(tempDir, true)
    FileAppend("DECIMAL CPS TEST FAILED: " err.Message " " err.File ":" err.Line, "*", "UTF-8")
    ExitApp(1)
}
