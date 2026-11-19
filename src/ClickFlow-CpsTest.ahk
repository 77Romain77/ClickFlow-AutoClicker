; ClickFlow - banc de test CPS pour les profils.
; Réutilise GetNextCps() et le cadenceur du moteur sans injecter de clic
; dans Windows. Les horodatages mesurent les déclenchements du moteur,
; et non les événements d'une autre application.
; Aucun score n'est écrit sur le disque.

CFTestPost(json) {
    global CF
    if CF.web
        try CF.web.PostWebMessageAsString(json)
}

CFTestValidDuration(duration) {
    return InStr("|2|5|10|30|60|", "|" duration "|") != 0
}

CFTestStart(duration, runId, profileId) {
    global CF
    if !CFTestValidDuration(duration)
        throw Error("Durée de test invalide.")
    if !RegExMatch(String(runId), "^[1-9]\d{0,8}$")
        throw Error("Identifiant de test invalide.")
    if !RegExMatch(String(profileId), "^[1-9]\d{0,8}$")
        throw Error("Identifiant de profil invalide.")
    profile := CFProfileById(profileId + 0)
    if !profile
        throw Error("Profil inconnu.")

    ; Le test est exclusif au fonctionnement normal du moteur.
    StopAll("Test CPS du profil " profile.name " : démarrage.")
    now := A_TickCount
    duration += 0
    CFNaturalReset(profile.cfg)
    CF.test := {active: true, run: runId + 0, duration: duration,
        started: now, nextAt: now, lastFlush: now, pending: [],
        clicks: [], profile: profile.name, cfg: CopyConfig(profile.cfg)}
    CFTestPost('{"type":"cpsTest","state":"started","run":' CF.test.run
        ',"duration":' duration ',"profile":' JsonQuote(profile.name) '}')
}

CFTestStop(reason := "stopped") {
    global CF
    if !CF.test.active
        return
    runId := CF.test.run
    CF.test.active := false
    CF.test.pending := []
    CFTestPost('{"type":"cpsTest","state":"stopped","run":' runId
        ',"reason":' JsonQuote(reason) '}')
}

CFTestArrayJson(array) {
    result := "["
    for index, num in array
        result .= (index = 1 ? "" : ",") num
    return result "]"
}

CFTestFlush() {
    global CF
    test := CF.test
    if !test.active || test.pending.Length = 0
        return
    ticks := CFTestArrayJson(test.pending)
    test.pending := []
    test.lastFlush := A_TickCount
    CFTestPost('{"type":"cpsTest","state":"ticks","run":' test.run
        ',"ticks":' ticks '}')
}

CFTestFinish() {
    global CF
    test := CF.test
    if !test.active
        return
    CFTestFlush()
    test.active := false
    ; Toute la chronologie est renvoyée pour garantir une courbe exacte
    ; même si WebView2 a regroupé ou retardé des messages en cours de test.
    CFTestPost('{"type":"cpsTest","state":"finished","run":' test.run
        ',"duration":' test.duration ',"profile":' JsonQuote(test.profile)
        ',"ticks":' CFTestArrayJson(test.clicks) '}')
}

CFTestTick(now := "") {
    global CF
    test := CF.test
    if !test.active || CF.shuttingDown
        return
    if now = ""
        now := A_TickCount
    if now - test.started >= test.duration * 1000 {
        CFTestFinish()
        return
    }
    if now < test.nextAt
        return
    intervalMs := GetNextIntervalMs(test.cfg, now)
    elapsed := Max(0, now - test.started)
    test.clicks.Push(elapsed)
    test.pending.Push(elapsed)
    test.nextAt := now + intervalMs
    if now - test.lastFlush >= 55 || test.pending.Length >= 12
        CFTestFlush()
}
