#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include ..\src\ClickFlow-Backend.ahk

 ; Quatre essais courts sur le vrai cadenceur Windows : 10, 50, 75, 100 CPS.
; Aucun clic n'est injecte dans une autre application.
CFPrecisionStop() {
    CFTestStop("fin du banc court")
}

CFPrecisionJoin(items) {
    result := ""
    for idx, item in items
        result .= (idx = 1 ? "" : "; ") item
    return result
}

global CF
CF.web := 0
CF.loading := true
CF.shuttingDown := false
CF.armed := false
CF.engineTimerActive := false
CF.engineLoopRunning := false
CF.precisionRequested := false
CF.statsTimerActive := false
CF.test := {active: false}
CF.cfg := DefaultConfig()
CF.profiles := []
for rate in [10, 50, 75, 100] {
    cfg := DefaultConfig()
    cfg.mode := 1
    cfg.min := rate
    cfg.max := rate
    CF.profiles.Push({id: CF.profiles.Length + 1, name: "Fixe " rate, cfg: cfg})
}

try {
    metrics := []
    for index, rate in [10, 50, 75, 100] {
        CFTestStart(2, index, index)
        if !CF.engineTimerActive || (!CF.precisionHandle && !CF.precisionRequested)
            throw Error("Aucun timer haute resolution disponible.")
        if index = 1 {
            probes := []
            Loop 8 {
                probeBefore := CFNowMs()
                CFPrecisionSleep(3)
                probes.Push(Round(CFNowMs() - probeBefore, 2))
            }
            FileAppend("Timer probe: " CFPrecisionJoin(probes) " ms (highres=" (CF.precisionHandle ? "yes" : "no") "). ", "*", "UTF-8")
        }
        SetTimer(CFPrecisionStop, -650)
        Sleep(760)
        if CF.test.active || CF.engineTimerActive || CF.precisionRequested || CF.precisionHandle
            throw Error("La cadence n'a pas relache ses timers.")
        stamps := CF.test.clicks
        count := stamps.Length
        expected := rate * 0.65
        ; L'ancien seuil à 14 % pouvait accepter ~88 CPS à 100.
        ; Exiger maintenant au moins ~95 % à partir de 75 CPS.
        countTolerance := rate >= 75 ? Max(2, expected * 0.05)
            : Max(2, expected * 0.14)
        if Abs(count - expected) > countTolerance
            throw Error(rate " CPS : " count " clics contre ~" expected " attendus. Offsets: " CFPrecisionJoin(stamps))
        if count < 2
            throw Error("Historique CPS trop court.")
        interval := (stamps[count] - stamps[1]) / (count - 1)
        ideal := 1000 / rate
        intervalTolerance := rate >= 75 ? Max(0.75, ideal * 0.06)
            : Max(3, ideal * 0.2)
        if Abs(interval - ideal) > intervalTolerance
            throw Error(rate " CPS : intervalle observe " Round(interval, 2) " ms (cible " ideal ").")
        metrics.Push(rate "CPS=" count " en 650ms, intervalle=" Round(interval, 1) "ms")
    }
    FileAppend("Precision Windows 10/50/75/100 CPS passed: " CFPrecisionJoin(metrics), "*", "UTF-8")
    ExitApp(0)
} catch as err {
    try CFEngineSetTimer(false)
    FileAppend("PRECISION CPS FAILED: " err.Message " " err.File ":" err.Line, "*", "UTF-8")
    ExitApp(1)
}
