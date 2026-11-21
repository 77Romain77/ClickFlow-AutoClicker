#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include ..\src\ClickFlow-Backend.ahk

; Fractional millisecond carry must preserve the long-run target of
; fractional CPS settings without altering first-click or physical input.
global CF
CF.web := 0
CF.loading := true
CF.shuttingDown := false
CF.armed := false
CF.test := {active: false}
CF.total := 0
CF.cfg := DefaultConfig()
CF.emergencyKey := "F12"
try {
    cfg := DefaultConfig()
    cfg.mode := 1
    cfg.min := 12.3
    cfg.max := 12.3
    CFNaturalReset(cfg)
    total := 0
    seen := Map()
    Loop 1230 {
        ms := GetNextIntervalMs(cfg, A_Index * 100)
        if ms < 81 || ms > 82
            throw Error("Les périodes de 12.3 CPS ne se répartissent pas entre 81/82 ms.")
        seen[ms] := true
        total += ms
    }
    if seen.Count != 2
        throw Error("Aucune alternance des fractions de millisecondes.")
    ideal := 1230 * (1000.0 / 12.3)
    if Abs(total - ideal) >= 1
        throw Error("La dérive dépasse 1 ms sur 1230 clics : " total " contre " ideal ".")

    ; Une cible voisine doit produire une période moyenne différente.
    cfg.min := 12.4
    cfg.max := 12.4
    CFNaturalReset(cfg)
    other := 0
    Loop 1240
        other += GetNextIntervalMs(cfg, A_Index * 100)
    if Abs(other - 1240 * (1000.0 / 12.4)) >= 1
        throw Error("12.4 CPS conserve une dérive de cadence.")
    if total / 1230 <= other / 1240
        throw Error("Les cibles 12.3 et 12.4 CPS ne sont pas différenciées.")

    ; Une nouvelle session doit repartir de zéro : pas de dette résiduelle.
    cfg.min := 12.3
    cfg.max := 12.3
    CFNaturalReset(cfg)
    first := GetNextIntervalMs(cfg, 100)
    Loop 20
        GetNextIntervalMs(cfg, 100 + A_Index * 100)
    CFNaturalReset(cfg)
    if GetNextIntervalMs(cfg, 100) != first
        throw Error("L'accumulateur survit au redémarrage du moteur.")

    ; Les plafonds 10 ms / 100 CPS sont conservés.
    cfg.min := 100
    cfg.max := 100
    CFNaturalReset(cfg)
    Loop 100
        if GetNextIntervalMs(cfg, A_Index * 100) != 10
            throw Error("Le plafonnement 100 CPS a été modifié.")

    ; Les modes variables utilisent le même arrondi cumulé.
    cfg.mode := 2
    cfg.min := 8.4
    cfg.max := 12.7
    CFNaturalReset(cfg)
    Loop 200 {
        ms := GetNextIntervalMs(cfg, A_Index * 100)
        if ms < 78 || ms > 120
            throw Error("Aléatoire sort de ses limites.")
    }
    cfg.mode := 4
    cfg.rapidTarget := 12.3
    cfg.rapidPreset := 4
    cfg.rapidBetween := 0
    cfg.rapidWithin := 0
    CFNaturalReset(cfg)
    totalRapid := 0
    Loop 1230
        totalRapid += GetNextIntervalMs(cfg, A_Index * 100)
    if Abs(totalRapid - ideal) >= 1
        throw Error("Rapide naturel sans variations perd les fractions.")

    ; La simulation du profil doit conserver cette cible, sans clic
    ; SendInput ni écriture de score.
    cfg.mode := 1
    cfg.min := 12.3
    cfg.max := 12.3
    CF.cfg := cfg
    CF.profiles := [{id:1,name:"Fixe 12.3",cfg:CopyConfig(cfg)}]
    CF.selectedId := 1
    CFTestStart(10, 901, 1)
    CFEngineSetTimer(false)
    CFStatsSetTimer(false)
    started := CF.test.started
    Loop 10001
        CFTestTick(started + A_Index - 1)
    if CF.test.active
        throw Error("La simulation du profil ne s'arrête pas.")
    if CF.test.clicks.Length < 121 || CF.test.clicks.Length > 125
        throw Error("La simulation 12.3 CPS sur 10s n'a pas le nombre de clics attendu : " CF.test.clicks.Length)
    if CF.total != 0
        throw Error("La simulation a produit de vrais clics Windows.")

    FileAppend("Fractional CPS drift, reset, random/rapid compatibility and CPS simulation passed.", "*", "UTF-8")
    ExitApp(0)
} catch as err {
    try CFEngineSetTimer(false)
    try CFStatsSetTimer(false)
    FileAppend("FRACTIONAL CPS FAILED: " err.Message " " err.File ":" err.Line, "*", "UTF-8")
    ExitApp(1)
}
