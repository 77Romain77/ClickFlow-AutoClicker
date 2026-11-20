#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include ..\src\ClickFlow-Backend.ahk

; Integration Windows : vrai callback d'activation, cadenceur precis adaptatif,
; premier clic dans le callback (pas 10ms plus tard), timer CPU idle.
; Le clic réel vise uniquement la fenêtre de test AHK, sans autre programme.

CFPerfProcessCpuMs() {
    created := Buffer(8, 0), exited := Buffer(8, 0)
    kernel := Buffer(8, 0), user := Buffer(8, 0)
    process := DllCall("Kernel32\GetCurrentProcess", "Ptr")
    if !DllCall("Kernel32\GetProcessTimes", "Ptr", process,
        "Ptr", created.Ptr, "Ptr", exited.Ptr, "Ptr", kernel.Ptr,
        "Ptr", user.Ptr, "Int")
        throw Error("Impossible de mesurer le temps CPU Windows.")
    return (NumGet(kernel, 0, "Int64") + NumGet(user, 0, "Int64")) / 10000
}

CFPerfCaptureEarly() {
    global CF, CFPerfEarlyTotal
    CFPerfEarlyTotal := CF.total
}
CFPerfStopSample() {
    StopAll("Fin du test.")
}

global CF, CFPerfEarlyTotal := -1
CF.web := 0
CF.desktopReady := false
CF.shuttingDown := false
CF.loading := true
CF.hwnd := 0
CF.armed := false
CF.pressed := false
CF.engineTimerActive := false
CF.statsTimerActive := false
CF.test := {active: false}
CF.cfg := DefaultConfig()
CF.diagnosticsEnabled := true  ; Mesure volontaire dans les tests.
CF.cfg.mode := 1
CF.cfg.min := 5
CF.cfg.max := 5
CF.cfg.hold := 2  ; Basculer : le test n'a pas à simuler une touche physique.
CF.cfg.mouseGate := 0
CF.cfg.focusStop := 1
CF.profiles := [{id: 1, name: "Mesure", cfg: CF.cfg}]
CF.selectedId := 1
CF.total := 0
CF.recent := []
CF.overlayRecent := []
CF.floatShown := false
targetGui := 0
try {
    if CF.engineTimerActive
        throw Error("Le timer moteur doit être arrêté au repos.")
    targetGui := Gui("+AlwaysOnTop", "ClickFlow performance target")
    targetGui.Show("w350 h160")
    WinActivate("ahk_id " targetGui.Hwnd)
    if !WinWaitActive("ahk_id " targetGui.Hwnd, , 2)
        throw Error("La cible Windows du test ne prend pas le focus.")

    before := A_TickCount
    ActivationDown()
    if !CF.armed || !CF.engineTimerActive || !CF.statsTimerActive
        throw Error("Les timers actifs ne démarrent pas avec l'activation.")
    if CF.total != 1 || CF.recent.Length != 1
        throw Error("Le premier clic ne part pas immédiatement pendant ActivationDown.")
    if CF.firstDispatchMs = "" || CF.firstDispatchKind != "activation"
        throw Error("Le diagnostic immédiat ne mesure pas le premier clic.")
    firstDelay := CF.recent[1] - before
    if firstDelay < 0 || firstDelay > 150
        throw Error("Latence anormale dans le callback de départ : " firstDelay " ms.")
    if CF.nextAt - CF.recent[1] != 200
        throw Error("La prochaine échéance n'est pas calculée depuis le premier clic.")
    ; Même si le timer se déclenche juste après la touche, pas de double clic.
    EngineTick()
    if CF.total != 1
        throw Error("Deux clics ont été déclenchés lors de l'activation.")
    ; La boucle precise est cooperative : arretons-la via un callback
    ; planifie avant de reprendre le fil principal du test.
    SetTimer(CFPerfCaptureEarly, -55)
    SetTimer(CFPerfStopSample, -260)
    Sleep(330)
    if CFPerfEarlyTotal != 1
        throw Error("Double clic avant la prochaine échéance de 200ms.")
    if CF.total != 2
        throw Error("La cadence fixe 5 CPS a changé : " CF.total " clics en ~260ms.")
    if CF.armed || CF.engineTimerActive || CF.statsTimerActive
        throw Error("Les timers ne repassent pas au repos après l'arrêt.")
    count := CF.total
    Sleep(65)
    if CF.total != count
        throw Error("Un clic a été émis après l'arrêt du moteur.")

    ; Réactivation immédiate : pas de clic fantôme de l'ancienne session.
    CF.pressed := false
    ActivationDown()
    if CF.total != count + 1
        throw Error("La réactivation n'envoie pas exactement un premier clic.")
    if CF.nextAt - CF.recent[CF.recent.Length] != 200
        throw Error("L'intervalle de la nouvelle session n'est pas respecté.")
    ; Simuler un Up AHK manqué : l'état physique du raccourci est déjà
    ; relâché, le moteur doit réarmer Basculer avant le deuxième appui.
    CFActivationRefreshPressed()
    if CF.pressed
        throw Error("La touche reste bloquée après son relâchement physique.")
    ActivationDown()
    if CF.armed || CF.engineTimerActive
        throw Error("Le deuxième appui ne stoppe pas le mode Basculer.")
    StopAll("Deuxième session terminée.")

    ; Lorsque la condition souris est inactive, aucun clic initial.
    CF.pressed := false
    CF.cfg.mouseGate := 1
    CF.cfg.gateButton := "RButton"
    ActivationDown()
    if !CF.armed || CF.total != count + 1
        throw Error("La condition souris n'empêche pas le premier clic.")
    if CF.firstDispatchMs != "" || CF.firstDispatchKind != ""
        throw Error("Une mesure a ete creee sans aucun premier clic.")
    ; Aucun hook souris global installe et pas de faux horodatage.
    if CF.mouseDetectionMode != "classic" || CF.gateHook || CF.gateHookCallback
        throw Error("Un hook événementiel est encore actif.")
    if CF.gateMethodCurrent != "classic" || !CF.gateWaiting
        throw Error("La condition ne passe pas en attente classique.")
    if CF.gateProbeQpc || CF.gateEventUptime
        throw Error("Un horodatage événementiel périmé est conservé.")
    EngineTick()
    if CF.total != count + 1
        throw Error("Le moteur clique alors que la condition est absente.")
    ; Test sans appui physique : neutraliser provisoirement la condition.
    CF.cfg.mouseGate := 0
    EngineTick()
    if CF.total != count + 2 || CF.firstDispatchMs = ""
        throw Error("Le moteur de clics n'a pas émis son premier clic.")
    if CF.gateDetectionMs != "" || CF.gateEventDelayMs != ""
        || CF.gateProbeStatus = "measured"
        throw Error("Une fausse latence callback est affichée en Classique.")
    StopAll("Condition souris testée.")
    if CF.gateHook || CF.gateHookCallback
        throw Error("Un hook souris reste après l'arrêt.")

    CFDiagToggle(false)
    CF.pressed := false
    CF.cfg.mouseGate := 1
    ActivationDown()
    if !CF.armed || CF.firstDispatchMs != "" || CF.gateHook
        throw Error("Le mode Classique dépend des diagnostics.")
    EngineTick()
    if CF.total != count + 2 || CF.gateMethodCurrent != "classic"
        throw Error("Des clics partent sans appui conditionnel.")
    StopAll("Fin du test sans diagnostics.")
    CF.diagnosticsEnabled := true
    CF.cfg.mouseGate := 0

    ; Le mode Maintenir doit aussi envoyer son premier clic dès le
    ; callback, avant même la stabilisation de GetKeyState("F6", "P").
    CF.pressed := false
    CF.cfg.hold := 1
    ActivationDown()
    if CF.total != count + 3
        throw Error("Le premier clic en mode Maintenir n'est pas immédiat.")
    ActivationUp()
    if CF.armed || CF.engineTimerActive
        throw Error("Le mode Maintenir ne s'arrête pas au relâchement.")
    CF.cfg.hold := 2

    ; Ne jamais cliquer si la fenêtre principale reprend le focus.
    CF.pressed := false
    CF.hwnd := targetGui.Hwnd
    ActivationDown()
    if CF.armed || CF.engineTimerActive || CF.total != count + 3
        throw Error("La sécurité de focus a été contournée.")
    CF.hwnd := 0
    CF.pressed := false

    ; Le Test CPS partage le moteur sans envoyer de clic OS et coupe son
    ; timer lorsqu'il est terminé ou annulé.
    CFTestStart(2, 104, 1)
    if !CF.test.active || !CF.engineTimerActive || !CF.statsTimerActive
        throw Error("Le timer du Test CPS n'a pas démarré.")
    CFTestTick(CF.test.started + 2000)
    if CF.test.active || CF.engineTimerActive || CF.statsTimerActive
        throw Error("Le timer reste actif après la fin du Test CPS.")
    if CF.total != count + 3
        throw Error("Le Test CPS a injecté des clics Windows.")
    CFTestStart(5, 105, 1)
    CFTestStop("annulé")
    if CF.engineTimerActive || CF.statsTimerActive
        throw Error("Le timer reste actif après l'annulation du Test CPS.")

    CFDiagToggle(false)
    if CF.diagnosticsEnabled || CF.gateHook || CF.gateHookCallback
        throw Error("Les diagnostics restent actifs après désactivation.")

    ; Classique : aucun hook, même quand le bouton est attendu.
    CF.mouseDetectionMode := "classic"
    CF.cfg.hold := 2
    CF.cfg.mouseGate := 1
    CF.pressed := false
    ActivationDown()
    if !CF.armed || CF.gateHook || CF.gateHookCallback
        || CF.gateMethodCurrent != "classic"
        throw Error("Le mode classique doit attendre sans hook.")
    StopAll("Test classique terminé.")

    ; Les compteurs ne sont actifs que pendant le diagnostic détaillé.
    CFGateDebugToggle(true)
    if !CF.gateDebugEnabled
        throw Error("Le suivi détaillé de la souris ne s'active pas.")

    ; Enregistrer réellement un périphérique Raw Input avec un HWND AHK
    ; secondaire, sans injecter de clic physique ni allonger les benchmarks.
    rawWindow := Gui("+ToolWindow", "ClickFlow test Raw Input")
    CF.hwnd := rawWindow.Hwnd
    CF.armed := true
    CF.cfg.mouseGate := 1
    CF.diagnosticsEnabled := true
    CF.mouseDetectionMode := "event"
    CF.gateRawFailed := false
    CFGateProbeStart()
    if !CF.gateRawRegistered || !CF.gateRawListener
        throw Error("RegisterRawInputDevices a échoué sur la fenêtre de test.")
    if !CF.gateRawHwnd || !CF.gateRawWindow || CF.gateRawHwnd = CF.hwnd
        throw Error("Raw Input n'utilise pas son HWND dédié.")
    if CF.gateHook || CF.gateHookCallback
        throw Error("Un hook bloquant WH_MOUSE_LL a été réinstallé.")
    ; Les 5 boutons reconnus doivent capturer DOWN puis UP.
    for test in [
        ["LButton", 0x1, 0x2],
        ["RButton", 0x4, 0x8],
        ["MButton", 0x10, 0x20],
        ["XButton1", 0x40, 0x80],
        ["XButton2", 0x100, 0x200]
    ] {
        CF.cfg.gateButton := test[1]
        CF.gateEventKnown := false
        CF.gateWakeSignal := false
        CFGateRawButtonFlags(0x800)  ; Flag sans rapport avec le bouton
        if CF.gateEventKnown || CF.gateWakeSignal
            throw Error("Un autre bouton a déclenché la condition.")
        CFGateRawButtonFlags(test[2])
        if !CF.gateEventKnown || !CF.gateWakeSignal
            throw Error("L'appui Raw Input n'est pas reconnu : " test[1])
        CFGateRawButtonFlags(test[3])
        if !CF.gateEventKnown || CF.gateWakeSignal || CFGateIsHeld()
            throw Error("Le relâchement Raw Input reste actif : " test[1])
        CFGateRawButtonFlags(test[2] | test[3])
        if CF.gateWakeSignal
            throw Error("Un relâchement simultané doit annuler l'appui.")
    }
    if CF.gateRawDowns != 5 || CF.gateRawUps != 10
        throw Error("Les compteurs d'appui/relâchement Raw Input sont faux.")
    CFGateDebugToggle(false)
    if CF.gateDebugEnabled || CF.gateRawDowns || CF.gateRawUps
        throw Error("Les compteurs Raw Input restent actifs après désactivation.")
    ; Les tests de maintien ci-dessous se déroulent sans suivi détaillé.
    ; État AHK bloqué sur DOWN + état Raw Input sur UP + état asynchrone UP :
    ; déclenchement de la sécurité après confirmation, pas sur un seul UP.
    if !CFGateSafetyDisagree(true, true, false, true, false)
        throw Error("Une divergence physique persistante doit être vérifiée.")
    if CFGateSafetyDisagree(true, true, false, true, true)
        throw Error("La sécurité s'active alors que Windows confirme le maintien.")
    if CFGateSafetyDisagree(true, true, true, true, false)
        throw Error("La sécurité s'active sur un événement DOWN Raw.")
    if CFGateSafetyDisagree(false, true, false, true, false)
        throw Error("La sécurité ne doit pas affecter le mode Classique.")
    if CFGateSafetyTimeoutMs() < 20 || CFGateSafetyTimeoutMs() > 80
        throw Error("Tolérance de sécurité trop grande ou trop petite.")

    ; Régression v1.9.13 sur vrai PC : Raw UP est parfois reçu pendant
    ; que GetKeyState indique Maintenu. Le moteur ne doit PAS s'arrêter.
    if !CFGateHeldDecision("event", true, true, false, true, false)
        throw Error("Raw UP discordant coupe un appui physique maintenu.")
    if !CFGateHeldDecision("auto", true, true, false, true, false)
        throw Error("Auto Raw UP discordant coupe un maintien physique.")
    if CFGateHeldDecision("event", true, true, false, false, false)
        throw Error("Un relâchement physique confirmé laisse des clics.")
    if CFGateHeldDecision("event", true, true, true, false, false)
        throw Error("Raw DOWN bloqué force encore des clics après relâchement.")
    if !CFGateHeldDecision("event", true, true, true, false, true)
        throw Error("La courte tolérance de réception ne fonctionne pas.")
    if CFGateHeldDecision("event", true, false, false, true, false)
        throw Error("Événementielle accepte un appui sans Raw DOWN.")
    if !CFGateHeldDecision("auto", false, false, false, true, false)
        throw Error("Le secours Classique en Auto ne fonctionne plus.")
    if CFGateHeldDecision("event", false, false, false, true, false)
        throw Error("Le mode Événementielle ne doit pas cliquer sans Raw Input.")

    ; Reproduire RAW DOWN -> RAW UP discordant ; le verrou d'appui
    ; conserve l'autorisation jusqu'à une vraie remontée physique.
    CF.cfg.gateButton := "RButton"
    CF.gateRawArmed := false
    CFGateRawButtonFlags(0x4)
    CFGateRawButtonFlags(0x8)
    if !CF.gateRawArmed || CF.gateWakeSignal
        throw Error("Un RAW UP efface prématurément l'autorisation initiale.")

    ; Régression matérielle v1.9.12 : après un premier clic valide,
    ; le moteur ne doit pas revenir en attente pendant que Raw Input
    ; indique DOWN, même si GetKeyState physique est faux.
    CF.cfg.gateButton := "RButton"
    CF.gateEventKnown := false
    CF.gateWakeSignal := false
    CFGateRawButtonFlags(0x4)
    if !CFGateIsHeld()
        throw Error("Raw Input DOWN doit maintenir la condition en Événementielle.")
    CF.mouseDetectionMode := "auto"
    if !CFGateIsHeld()
        throw Error("Raw Input DOWN doit maintenir la condition en Automatique.")
    CF.mouseDetectionMode := "event"
    CF.cfg.mode := 1
    CF.cfg.min := 50
    CF.cfg.max := 50
    CF.target := WinExist("A")
    CF.gateWaiting := true
    ; Le runner ne maintient aucun bouton PHYSIQUE. Réémettre un DOWN
    ; simulé juste avant le tick permet de vérifier le premier clic sans
    ; transformer artificiellement GetKeyState en état maintenu.
    CFGateRawButtonFlags(0x4)
    CF.gateRawPhysicalUpSince := 0
    CF.nextAt := CFNowMs() - 1
    beforeRepeated := CF.total
    EngineTick()
    if CF.total != beforeRepeated + 1 || CF.gateWaiting
        throw Error("Le premier clic Raw Input ne démarre pas la cadence.")
    ; Les ticks suivants dépendent d'un maintien physique, absent du runner.
    ; La décision de maintenir malgré RAW UP a été vérifiée plus haut avec
    ; l'état physique explicitement fourni à CFGateHeldDecision().
    if !CFGateHeldDecision("event", true, true, false, true, false)
        throw Error("La répétition doit rester autorisée pendant le maintien.")
    CFGateRawButtonFlags(0x8)
    CF.nextAt := CFNowMs() - 1
    EngineTick()
    if CF.total != beforeRepeated + 1 || !CF.gateWaiting || CFGateIsHeld()
        throw Error("La cadence n'est pas interrompue après Raw Input UP.")

    ; Retablir le bouton X2 du test d'horodatage suivant.
    CF.cfg.gateButton := "XButton2"
    ; Un nouveau premier clic ne doit pas utiliser un horodatage de
    ; l'ancien appui relâché (régression du faux délai 174805 ms).
    CF.gateProbePending := true
    CF.gateProbeQpc := CFPerfCounter()
    CFGateRawButtonFlags(0x200) ; UP du bouton XButton2
    if CF.gateProbeQpc || CF.gateWakeSignal
        throw Error("L'horodatage reste actif après relâchement.")
    ; Aucune notification Raw Input ne doit réactiver le moteur après Stop.
    StopAll("Raw Input terminé.")
    if CF.gateRawRegistered || CF.gateRawListener || CF.gateWakeSignal
        || CF.gateRawHwnd || CF.gateRawWindow || CF.gateHook || CF.gateHookCallback
        throw Error("Raw Input reste enregistré après l'arrêt.")
    CF.cfg.gateButton := "RButton"
    CF.cfg.mouseGate := 0
    CF.mouseDetectionMode := "classic"
    CF.hwnd := 0
    rawWindow.Destroy()

    ; Mesure indicative du CPU consommé au repos par le processus AutoHotkey.
    ; La limite est volontairement large pour ne pas dépendre du runner CI.
    cpuBefore := CFPerfProcessCpuMs()
    Sleep(850)
    idleCpu := Round(CFPerfProcessCpuMs() - cpuBefore, 1)
    if idleCpu > 340
        throw Error("Activité CPU au repos anormalement élevée : " idleCpu "ms/850ms.")

    targetGui.Destroy()
    FileAppend("Adaptive engine timers, immediate first click, no duplicate, CPS cadence, stop/focus/mouse safety, CPS test lifecycle and idle CPU passed. FirstClick=" firstDelay "ms IdleCPU=" idleCpu "ms/850ms", "*", "UTF-8")
    ExitApp(0)
} catch as err {
    try CFEngineSetTimer(false)
    try CFStatsSetTimer(false)
    if IsObject(targetGui)
        try targetGui.Destroy()
    FileAppend("ADAPTIVE ENGINE TEST FAILED: " err.Message " " err.File ":" err.Line, "*", "UTF-8")
    ExitApp(1)
}
