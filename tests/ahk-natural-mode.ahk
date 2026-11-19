#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include ..\src\ClickFlow-Backend.ahk

; Test de distribution : vérifier que les 3 niveaux sont nettement distincts
; et que les imperfections ne produisent jamais un clic plus rapide que le
; CPS maximum. Aucun SendInput n'est déclenché dans ce test.
global CF
CF.web := 0
CF.shuttingDown := false
CF.armed := false
CF.test := {active: false}
CF.total := 0

CFSampleNatural(cfg, level, totalClicks := 5000) {
    cfg.variation := level
    CFNaturalReset(cfg)
    now := A_TickCount + 10000
    shortest := Max(10, Ceil(1000 / cfg.max))
    longest := Max(shortest, Ceil(1000 / cfg.min))
    previous := 0
    change := 0
    pauses := 0
    different := Map()
    Loop totalClicks {
        interval := GetNextIntervalMs(cfg, now)
        if interval < shortest
            throw Error("Intervalle trop court pour le CPS maximum, niveau " level)
        if interval > longest
            pauses += 1
        different[interval] := true
        if previous != 0
            change += Abs(interval - previous)
        previous := interval
        now += interval
    }
    return {delta: change / (totalClicks - 1),
        pauses: pauses, unique: different.Count}
}

try {
    cfg := DefaultConfig()
    cfg.min := 8
    cfg.max := 14
    cfg.mode := 3
    low := CFSampleNatural(cfg, 1)
    medium := CFSampleNatural(cfg, 2)
    high := CFSampleNatural(cfg, 3)
    if low.unique < 12
        throw Error("Le niveau faible manque de micro-variations.")
    if medium.delta < low.delta * 1.16
        throw Error("La variation moyenne n'est pas suffisamment renforcée.")
    if high.delta < medium.delta * 1.16
        throw Error("La variation élevée n'est pas suffisamment renforcée.")
    if medium.pauses <= low.pauses || high.pauses <= medium.pauses
        throw Error("Les hésitations ne suivent pas la gradation des intensités.")

    ; Une plage réduite de CPS reste respectée, même au niveau élevé.
    cfg.min := 12
    cfg.max := 12
    equal := CFSampleNatural(cfg, 3, 1500)
    if equal.pauses = 0
        throw Error("Les hésitations doivent exister même quand min=max.")

    ; Les modes Fixe et Aléatoire ne reçoivent pas de nouvelles irrégularités.
    cfg.mode := 1
    cfg.min := 10
    cfg.max := 10
    Loop 100
        if GetNextIntervalMs(cfg, A_TickCount + A_Index * 100) != 100
            throw Error("Le mode fixe a changé de comportement.")
    cfg.mode := 2
    cfg.min := 8
    cfg.max := 14
    Loop 200 {
        ms := GetNextIntervalMs(cfg, A_TickCount + A_Index * 100)
        if ms < 71 || ms > 125
            throw Error("La plage du mode aléatoire a changé.")
    }

    ; La mesure dans l'onglet Test CPS utilise le même calcul.
    cfg.mode := 3
    cfg.variation := 3
    CF.profiles := [{id: 1, name: "Naturel", cfg: CopyConfig(cfg)}]
    CF.selectedId := 1
    CFTestStart(2, 991, 1)
    started := CF.test.started
    Loop 201
        CFTestTick(started + (A_Index - 1) * 10)
    if CF.test.active
        throw Error("Le test de profil naturel ne s'arrête pas.")
    if CF.test.clicks.Length < 7 || CF.test.clicks.Length > 28
        throw Error("Nombre de clics inattendu pour le test naturel.")
    if CF.total != 0
        throw Error("Le banc de test a envoyé des clics Windows.")

    FileAppend("Natural variation tiers, micro-jitter, hesitations, CPS bounds and profile tester passed."
        " LowDelta=" Round(low.delta,1) " MidDelta=" Round(medium.delta,1)
        " HighDelta=" Round(high.delta,1)
        " Pauses=" low.pauses "/" medium.pauses "/" high.pauses, "*", "UTF-8")
    ExitApp(0)
} catch as err {
    FileAppend("NATURAL MODE TEST FAILED: " err.Message, "*", "UTF-8")
    ExitApp(1)
}
