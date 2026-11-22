#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include ..\src\ClickFlow-Backend.ahk

; Simule les ~0,9 ms de retard observés sur la machine utilisateur
; (30 s à 12,3 CPS : ancienne simulation environ 365 clics contre 369
; théoriques), sans injection Windows ni dépendance aux timers réels.
global CF
CF.web := 0
CF.loading := true
CF.shuttingDown := false
CF.armed := false
CF.total := 0
CF.test := {active:false}
CF.cfg := DefaultConfig()
CF.emergencyKey := "F12"
try {
    if Abs(CFNextDeadline(1000, 1000.9, 81) - 1081) > 0.001
        throw Error("Un retard de 0,9 ms décale la phase.")
    if CFNextDeadline(1000, 1400, 81) != 1481
        throw Error("Un retard important ne remet pas à zéro la phase.")
    if CFNextDeadline(1000, 1050, 81) != 1131
        throw Error("Une échéance trop rapprochée génère un rattrapage.")
    if Abs(CFNextDeadline(1000, 1000.9, 10) - 1010) > 0.001
        throw Error("La phase à 100 CPS ne doit pas dériver à chaque clic.")
    if Abs(CFNextDeadline(1000, 1001.5, 10) - 1010) > 0.001
        throw Error("Le bruit de timer à 100 CPS accumule un retard.")
    if CFNextDeadline(1000, 1009, 10) < 1019
        throw Error("Le cadenceur rattrape une échéance trop proche.")
    if CFNextDeadline(1000, 1400, 10) != 1410
        throw Error("Une longue pause produit des clics de rattrapage.")

    cfg := DefaultConfig()
    cfg.mode := 1
    cfg.min := 12.3
    cfg.max := 12.3
    CF.profiles := [{id:1,name:"Fixe 12,3",cfg:cfg}]
    CF.selectedId := 1
    CFTestStart(30, 771, 1)
    CFEngineSetTimer(false)
    CFStatsSetTimer(false)
    started := CF.test.started
    count := 0
    Loop 420 {
        if !CF.test.active
            break
        due := CF.test.nextAt
        tickAt := due + (count=0 ? 0 : 0.9)
        if tickAt >= started + 30000
            break
        CFTestTick(tickAt)
        count += 1
    }
    ; Un arrondi flottant peut placer le tick à une fraction de
    ; microseconde avant l'échéance exacte. Tester juste après 30 s
    ; sans ajouter de clic au résultat final.
    CFTestTick(started+30001)
    if CF.test.active
        throw Error("La simulation ne s'arrête pas après 30 s.")
    if CF.test.clicks.Length != 369
        throw Error("30 s, 12,3 CPS et 0,9 ms de retard donnent "
            CF.test.clicks.Length " clics au lieu de 369.")
    if CF.total != 0
        throw Error("Le Test CPS a envoyé des clics Windows.")
    ; Les moyennes récentes doivent converger vers 81,3 ms (et non 82,2).
    ticks := CF.test.clicks
    recentAverage := (ticks[ticks.Length]-ticks[ticks.Length-60])/60
    if Abs(recentAverage - 1000/12.3) > 0.04
        throw Error("La phase n'est pas compensée : " recentAverage " ms.")

    ; Simulation déterministe : 30 s à 100 CPS avec 1,3 ms de
    ; surcharge entre réveil et émission, sans aucune rafale artificielle.
    high := DefaultConfig()
    high.mode := 1
    high.min := 100
    high.max := 100
    CF.profiles := [{id:2,name:"Fixe 100",cfg:high}]
    CFTestStart(30, 773, 2)
    CFEngineSetTimer(false)
    CFStatsSetTimer(false)
    started := CF.test.started
    count := 0
    Loop 3200 {
        if !CF.test.active
            break
        due := CF.test.nextAt
        tickAt := due + (count = 0 ? 0 : 1.3)
        if tickAt >= started + 30000
            break
        CFTestTick(tickAt)
        count += 1
    }
    CFTestTick(started + 30001)
    if CF.test.clicks.Length != 3000
        throw Error("La phase à 100 CPS dérive : "
            CF.test.clicks.Length " clics / 3000 attendus.")
    highTicks := CF.test.clicks
    if Abs((highTicks[3000] - highTicks[2940]) / 60 - 10) > 0.001
        throw Error("La moyenne à 100 CPS n'est pas de 10 ms.")
    ; Restaurer le profil 12,3 CPS pour le test d'interruption.
    CF.profiles := [{id:1,name:"Fixe 12,3",cfg:cfg}]

    ; Si le système reste bloqué 2 secondes, on doit produire un seul
    ; déclenchement au retour puis repartir normalement, pas 25 clics.
    CFTestStart(5, 772, 1)
    CFEngineSetTimer(false)
    CFStatsSetTimer(false)
    start := CF.test.started
    CFTestTick(start)
    CFTestTick(start+2000)
    if CF.test.clicks.Length != 2
        throw Error("Des clics de rattrapage ont été générés après pause.")
    nextDue := CF.test.nextAt
    if nextDue < start+2080
        throw Error("La phase n'est pas remise à zéro après pause.")
    CFTestTick(start+2001)
    if CF.test.clicks.Length != 2
        throw Error("Un second clic immédiat apparaît après la pause.")
    CFTestStop("pause terminée.")

    FileAppend("Phase-anchored 12.3 CPS 30s drift, stall reset and no catch-up passed.", "*", "UTF-8")
    ExitApp(0)
} catch as err {
    try CFEngineSetTimer(false)
    try CFStatsSetTimer(false)
    FileAppend("PHASE ANCHOR TEST FAILED: " err.Message
        " " err.File ":" err.Line, "*", "UTF-8")
    ExitApp(1)
}
