; ClickFlow - réception réelle de clics dans une fenêtre native dédiée.
; Uniquement pendant un test explicitement démarré depuis Test CPS.
; Les événements SendInput sont marqués dans MOUSEINPUT.dwExtraInfo et
; comptés à leur réception dans la file de messages Windows de la fenêtre.
; Aucun score ni historique n'est enregistré sur disque.
;
; Les SendInput restent des entrées système : WinActive et la présence du
; curseur dans la zone sont contrôlés juste AVANT chaque injection.
; La mesure n'est pas un accusé de réception d'un jeu externe.

CFRealMarker() {
    return 0x43465254 ; 'CFRT'
}

CFRealFlag(button, isDown) {
    switch button {
        case "Left": return isDown ? 0x2 : 0x4
        case "Right": return isDown ? 0x8 : 0x10
        case "Middle": return isDown ? 0x20 : 0x40
    }
    return 0
}

CFRealMouseMessageId(button, isDown) {
    switch button {
        case "LButton": return isDown ? 0x201 : 0x202
        case "RButton": return isDown ? 0x204 : 0x205
        case "MButton": return isDown ? 0x207 : 0x208
    }
    return 0
}

CFRealInputBuffer(button) {
    down := CFRealFlag(button, true)
    up := CFRealFlag(button, false)
    if !down || !up
        throw Error("Bouton de clic non compatible avec le test natif.")
    ; INPUT type=0 (MOUSEINPUT). Sur x64, MOUSEINPUT commence à 8 et
    ; dwExtraInfo à 32 ; l'INPUT Win32 occupe 40 octets.
    stride := A_PtrSize = 8 ? 40 : 28
    offset := A_PtrSize = 8 ? 8 : 4
    extra := A_PtrSize = 8 ? 32 : 24
    buf := Buffer(stride * 2, 0)
    Loop 2 {
        base := (A_Index - 1) * stride
        NumPut("UInt", 0, buf, base)
        NumPut("UInt", A_Index = 1 ? down : up,
            buf, base + offset + 12)
        NumPut("UPtr", CFRealMarker(), buf, base + extra)
    }
    return {data: buf, stride: stride}
}

CFRealInfoIsTagged(info) {
    return (info & 0xFFFFFFFF) = CFRealMarker()
}

CFRealCanSend(focused, inside, held, running) {
    return focused && inside && held && running
}

CFRealInside() {
    global CF
    test := CF.realTest
    if !IsObject(test.gui) || !IsObject(test.zone)
        return false
    pt := Buffer(8, 0)
    if !DllCall("User32\GetCursorPos", "Ptr", pt.Ptr, "Int")
        return false
    if !DllCall("User32\ScreenToClient", "Ptr", test.gui.Hwnd, "Ptr", pt.Ptr, "Int")
        return false
    x := NumGet(pt, 0, "Int"), y := NumGet(pt, 4, "Int")
    test.zone.GetPos(&zx, &zy, &zw, &zh)
    return x >= zx && x < zx+zw && y >= zy && y < zy+zh
}

CFRealPost(state, more := "") {
    global CF
    test := CF.realTest
    if !CF.shuttingDown && test.run
        CFTestPost('{"type":"cpsReal","state":' JsonQuote(state)
            ',"run":' test.run more '}')
}

CFRealFlush() {
    global CF
    test := CF.realTest
    if !test.active || !test.run
        return
    if !test.pending.Length && test.lastSent = test.sent
        return
    events := CFTestArrayJson(test.pending)
    test.pending := []
    test.lastSent := test.sent
    CFRealPost("ticks", ',"ticks":' events
        ',"sent":' test.sent ',"received":' test.received)
    if IsObject(test.status)
        test.status.Text := "Envoyés : " test.sent
            "   Reçus : " test.received
            "   |   " Round(Max(0, test.endAt-CFNowMs())/1000,1) " s restantes"
}

CFRealEnd(reason := "arrêté", completed := false) {
    global CF
    if !CF.realTest.run
        return
    test := CF.realTest
    test.held := false
    test.active := false
    try SetTimer(CFRealTick, 0)
    if !CF.armed && !CF.test.active
        CFEngineSetTimer(false)
    if completed {
        CFRealPost("finished", ',"duration":' test.duration
            ',"profile":' JsonQuote(test.profile)
            ',"sent":' test.sent
            ',"received":' test.received
            ',"ticks":' CFTestArrayJson(test.clicks) '}')
    } else {
        CFRealPost("stopped", ',"reason":' JsonQuote(reason) '}')
    }
    gui := test.gui
    test.run := 0
    test.gui := 0
    test.zone := 0
    try gui.Destroy()
}

CFRealClose(*) {
    CFRealEnd("Fenêtre de réception fermée.")
}

CFRealMouse(wParam, lParam, msg, hwnd) {
    global CF
    test := CF.realTest
    if !test.run || !IsObject(test.gui) || !IsObject(test.zone)
        return
    if hwnd != test.zone.Hwnd && hwnd != test.gui.Hwnd
        return
    extra := DllCall("User32\GetMessageExtraInfo", "Ptr")
    if CFRealInfoIsTagged(extra) {
        if test.active && msg = CFRealMouseMessageId(test.outButton, true) {
            ; Seuls les clics générés par CE test comptent.
            offset := Max(0, CFNowMs()-test.started)
            if offset < test.duration*1000 {
                test.clicks.Push(offset)
                test.pending.Push(offset)
                test.received += 1
                if CFNowMs()-test.lastFlush >= 55 || test.pending.Length >= 12 {
                    test.lastFlush := CFNowMs()
                    CFRealFlush()
                }
            }
        }
        return
    }
    if msg = CFRealMouseMessageId(test.trigger, true) {
        if !CFRealInside() || WinExist("A") != test.gui.Hwnd
            return
        if !test.active {
            test.started := CFNowMs()
            test.endAt := test.started + test.duration*1000
            test.active := true
            test.lastFlush := test.started
            CFNaturalReset(test.cfg)
            CFRealPost("started", ',"duration":' test.duration
                ',"profile":' JsonQuote(test.profile)
                ',"trigger":' JsonQuote(test.trigger))
            SetTimer(CFRealTick, 50)
        }
        if !test.held {
            test.held := true
            test.nextAt := CFNowMs()
            if test.cfg.mode = 4
                CFRapidBurstReset(test.cfg)
            CFRealTick()
            if test.active && test.held
                CFEngineSetTimer(true)
        }
    } else if msg = CFRealMouseMessageId(test.trigger, false) {
        test.held := false
        if !CF.armed && !CF.test.active
            CFEngineSetTimer(false)
        CFRealFlush()
    }
}

CFRealOpen(duration, runId, profileId) {
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
    ; Le test exclusif suspend le moteur normal et toute autre simulation.
    StopAll("Test de réception native : moteur général arrêté.")
    cfg := CopyConfig(profile.cfg)
    if !HasValue(["Left","Right","Middle"], cfg.clickButton)
        throw Error("Le test natif ne prend en charge que les clics gauche, droit et milieu.")
    trigger := cfg.mouseGate
        && HasValue(["LButton","RButton","MButton"], cfg.gateButton)
        ? cfg.gateButton : "LButton"
    ; Au lieu du raccourci global du profil, l'appui est limité à la zone.
    gui := Gui("+MinSize540x415", "ClickFlow - Réception réelle des clics")
    gui.BackColor := "162640"
    gui.SetFont("s11 cF3F7FF", "Segoe UI")
    gui.AddText("x22 y15 w495 h32 Center", "Test réel : " profile.name)
    gui.SetFont("s9 cB8D1F0")
    gui.AddText("x22 y47 w495 h48 Center",
        "Appuie et maintiens " (trigger = "LButton" ? "le clic gauche"
            : trigger = "RButton" ? "le clic droit" : "le clic milieu")
        " dans la zone. Seuls les clics du profil reçus ici sont comptés.")
    zone := gui.AddText("x24 y112 w492 h185 Border Center 0x100 Background213B60",
        "ZONE DE RÉCEPTION WINDOWS" "`n"
        "Garde le curseur dans ce rectangle pendant le maintien.")
    status := gui.AddText("x22 y311 w495 h45 Center", "Prêt : attends ton premier appui physique.")
    close := gui.AddButton("x195 y365 w150 h33", "Fermer / arrêter")
    close.OnEvent("Click", CFRealClose)
    gui.OnEvent("Close", CFRealClose)
    gui.OnEvent("Escape", CFRealClose)
    CF.realTest := {run: runId+0, active:false, held:false,
        gui:gui, zone:zone, status:status, cfg:cfg, profile:profile.name,
        trigger:trigger, outButton:cfg.clickButton, duration:duration+0,
        started:0, endAt:0, nextAt:0,
        sent:0, received:0, lastSent:0, clicks:[],pending:[],lastFlush:0}
    ; Les handlers sont filtrés par hwnd : pas d'effet hors de la fenêtre.
    for message in [0x201,0x202,0x204,0x205,0x207,0x208]
        OnMessage(message, CFRealMouse)
    gui.Show("w540 h415")
    CFRealPost("opened", ',"profile":' JsonQuote(profile.name)
        ',"trigger":' JsonQuote(trigger)
        ',"button":' JsonQuote(cfg.clickButton))
}

CFRealTick(now := "") {
    global CF
    test := CF.realTest
    if !test.run || !test.active || CF.shuttingDown
        return
    if now = ""
        now := CFNowMs()
    if now >= test.endAt {
        CFRealFlush()
        CFRealEnd("Test terminé.", true)
        return
    }
    focused := IsObject(test.gui) && WinExist("A") = test.gui.Hwnd
    inside := focused && CFRealInside()
    if !focused || (test.held && !inside) {
        CFRealEnd(!focused ? "Fenêtre de test non active."
            : "Curseur sorti de la zone de test.")
        return
    }
    if !test.held {
        if test.pending.Length || test.lastSent != test.sent
            CFRealFlush()
        return
    }
    ; Le véritable UP natif reste prioritaire, même si le clic simulé
    ; sur le même bouton a modifié l'état logique du bouton dans Windows.
    ; Si aucun vrai UP n'est arrivé, la lecture physique sert de filet.
    if !GetKeyState(test.trigger, "P") {
        test.held := false
        if !CF.armed && !CF.test.active
            CFEngineSetTimer(false)
        return
    }
    if now < test.nextAt
        return
    ; Contrôle de destination juste avant SendInput. Si la fenêtre ou la
    ; zone a changé, arrêter sans injecter dans la nouvelle destination.
    if !CFRealCanSend(focused, inside, test.held, test.active)
        return
    period := GetNextIntervalMs(test.cfg, now)
    input := CFRealInputBuffer(test.outButton)
    sent := DllCall("User32\SendInput", "UInt",2,
        "Ptr",input.data.Ptr, "Int",input.stride, "UInt")
    if sent != 2 {
        CFRealEnd("SendInput n'a pas pu envoyer les deux événements.")
        return
    }
    test.sent += 1
    test.nextAt := CFNextDeadline(test.nextAt, now, period)
    if now-test.lastFlush >= 100 {
        test.lastFlush := now
        CFRealFlush()
    }
}
