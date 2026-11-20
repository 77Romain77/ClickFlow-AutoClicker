#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include ..\src\ClickFlow-Backend.ahk

; Integration Windows : vrai callback d'activation, cadenceur 10ms adaptatif,
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

global CF
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
    firstDelay := CF.recent[1] - before
    if firstDelay < 0 || firstDelay > 150
        throw Error("Latence anormale dans le callback de départ : " firstDelay " ms.")
    if CF.nextAt - CF.recent[1] != 200
        throw Error("La prochaine échéance n'est pas calculée depuis le premier clic.")
    ; Même si le timer se déclenche juste après la touche, pas de double clic.
    EngineTick()
    if CF.total != 1
        throw Error("Deux clics ont été déclenchés lors de l'activation.")
    Sleep(55)
    if CF.total != 1
        throw Error("Double clic avant la prochaine échéance de 200ms.")
    Sleep(185)
    if CF.total != 2
        throw Error("La cadence fixe 5 CPS a changé : " CF.total " clics en ~240ms.")

    StopAll("Fin du test.")
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
    StopAll("Deuxième session terminée.")

    ; Lorsque la condition souris est inactive, aucun clic initial.
    CF.pressed := false
    CF.cfg.mouseGate := 1
    CF.cfg.gateButton := "RButton"
    ActivationDown()
    if !CF.armed || CF.total != count + 1
        throw Error("La condition souris n'empêche pas le premier clic.")
    StopAll("Condition souris testée.")
    CF.cfg.mouseGate := 0

    ; Le mode Maintenir doit aussi envoyer son premier clic dès le
    ; callback, avant même la stabilisation de GetKeyState("F6", "P").
    CF.pressed := false
    CF.cfg.hold := 1
    ActivationDown()
    if CF.total != count + 2
        throw Error("Le premier clic en mode Maintenir n'est pas immédiat.")
    ActivationUp()
    if CF.armed || CF.engineTimerActive
        throw Error("Le mode Maintenir ne s'arrête pas au relâchement.")
    CF.cfg.hold := 2

    ; Ne jamais cliquer si la fenêtre principale reprend le focus.
    CF.pressed := false
    CF.hwnd := targetGui.Hwnd
    ActivationDown()
    if CF.armed || CF.engineTimerActive || CF.total != count + 2
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
    if CF.total != count + 2
        throw Error("Le Test CPS a injecté des clics Windows.")
    CFTestStart(5, 105, 1)
    CFTestStop("annulé")
    if CF.engineTimerActive || CF.statsTimerActive
        throw Error("Le timer reste actif après l'annulation du Test CPS.")

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
