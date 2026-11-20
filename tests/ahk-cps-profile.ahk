#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include ..\src\ClickFlow-Backend.ahk

; Vérifie que le banc de test utilise le même cadenceur que les profils,
; sans envoyer de clics Windows et sans écrire de résultats sur le disque.
global CF
CF.web := 0
CF.loading := true
CF.shuttingDown := false
CF.armed := false
CF.total := 0
CF.test := {active: false}
CF.cfg := DefaultConfig()
CF.cfg.mode := 1
CF.cfg.min := 5
CF.cfg.max := 5
fast := DefaultConfig()
fast.mode := 1
fast.min := 20
fast.max := 20
slow := DefaultConfig()
slow.mode := 1
slow.min := 10
slow.max := 10
CF.profiles := [{id: 1, name: "Rapide", cfg: fast},
    {id: 2, name: "Lent", cfg: slow}]
CF.selectedId := 1

try {
    rejected := false
    try CFTestStart(3, 1, 1)
    catch
        rejected := true
    if !rejected
        throw Error("Une durée CPS invalide a été acceptée.")
    rejected := false
    try CFTestStart(2, 1, 99)
    catch
        rejected := true
    if !rejected
        throw Error("Un profil inconnu a été accepté.")

    CFTestStart(2, 11, 1)
    if !CF.test.active || CF.test.cfg.min != 20 || !CF.engineTimerActive
        throw Error("Le moteur n'a pas chargé le profil à tester.")
    CFEngineSetTimer(false)
    CFStatsSetTimer(false)
    start := CF.test.started
    Loop 201 {
        offset := (A_Index - 1) * 10
        CFTestTick(start + offset)
    }
    if CF.test.active
        throw Error("Le test ne s'est pas arrêté après 2 secondes.")
    if CF.test.clicks.Length != 40
        throw Error("Profil 20 CPS : nombre de déclenchements inattendu : " CF.test.clicks.Length)
    if CF.total != 0 || CF.armed
        throw Error("Le banc de test a modifié le moteur de clic Windows.")

    CFTestStart(2, 12, 2)
    CFEngineSetTimer(false)
    CFStatsSetTimer(false)
    start := CF.test.started
    Loop 201
        CFTestTick(start + (A_Index - 1) * 10)
    if CF.test.clicks.Length != 20
        throw Error("Profil 10 CPS : mauvais nombre de déclenchements : " CF.test.clicks.Length)
    if CF.total != 0
        throw Error("Le test a comptabilisé des clics Windows.")

    CFTestStart(5, 13, 1)
    StopAll("Arrêt d'urgence simulé.")
    if CF.test.active
        throw Error("L'arrêt d'urgence n'a pas interrompu le test.")

    CFTestStart(30, 14, 1)
    CFTestStop("annulé")
    if CF.test.active
        throw Error("L'annulation du test n'a pas fonctionné.")

    FileAppend("Profile CPS engine scheduler, time limits and emergency stop passed.", "*", "UTF-8")
    ExitApp(0)
} catch as err {
    FileAppend("PROFILE CPS TEST FAILED: " err.Message, "*", "UTF-8")
    ExitApp(1)
}
