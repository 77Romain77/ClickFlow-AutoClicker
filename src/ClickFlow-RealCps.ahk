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
        case "LButton", "Left": return isDown ? 0x201 : 0x202
        case "RButton", "Right": return isDown ? 0x204 : 0x205
        case "MButton", "Middle": return isDown ? 0x207 : 0x208
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

CFRealPointInside(x, y) {
    global CF
    test := CF.realTest
    if !test.run || !IsObject(test.zone)
        return false
    bounds := Buffer(16, 0)
    if !DllCall("User32\GetWindowRect", "Ptr", test.zone.Hwnd,
        "Ptr", bounds.Ptr, "Int")
        return false
    return x >= NumGet(bounds, 0, "Int")
        && y >= NumGet(bounds, 4, "Int")
        && x < NumGet(bounds, 8, "Int")
        && y < NumGet(bounds, 12, "Int")
}

CFRealInside() {
    point := Buffer(8, 0)
    if !DllCall("User32\GetCursorPos", "Ptr", point.Ptr, "Int")
        return false
    return CFRealPointInside(NumGet(point, 0, "Int"),
        NumGet(point, 4, "Int"))
}

; Le contrôle Text de la fenêtre ne transmet pas systématiquement
; WM_*BUTTONDOWN à notre OnMessage. Un hook souris bas niveau, limité à
; la durée du test, détecte les vrais appuis et ignore les clics injectés.
; Le callback ne fait aucune injection : il signale l'état et programme
; une intervention courte dans le thread AHK normal.
CFRealHookCallback(nCode, wParam, lParam) {
    global CF
    if nCode >= 0 && CF.realTest.run && lParam {
        msg := wParam & 0xFFFF
        test := CF.realTest
        if msg = CFRealMouseMessageId(test.trigger, true)
            || msg = CFRealMouseMessageId(test.trigger, false) {
            flags := NumGet(lParam, 12, "UInt")
            extra := NumGet(lParam, A_PtrSize = 8 ? 24 : 20, "UPtr")
            if !(flags & 0x1) && !CFRealInfoIsTagged(extra) {
                x := NumGet(lParam, 0, "Int")
                y := NumGet(lParam, 4, "Int")
                CFRealPhysicalMessage(msg, flags, extra, x, y)
            }
        }
    }
    return DllCall("User32\CallNextHookEx", "Ptr", 0, "Int", nCode,
        "UPtr", wParam, "Ptr", lParam, "Ptr")
}

CFRealPhysicalMessage(msg, flags, extra, x, y) {
    global CF
    test := CF.realTest
    if !test.run || (flags & 0x1) || CFRealInfoIsTagged(extra)
        return false
    down := CFRealMouseMessageId(test.trigger, true)
    up := CFRealMouseMessageId(test.trigger, false)
    if msg = down {
        if !CFRealPointInside(x, y) || test.held
            return false
        test.held := true
        test.pendingStart := true
        test.physical += 1
        test.pendingAttempts := 0
        SetTimer(CFRealBeginPending, -1)
        SetTimer(CFRealUpdateStatus, -1)
        return true
    }
    if msg = up && test.held {
        ; Même si le clic automatique utilise le même bouton, seul
        ; ce véritable UP (LLMHF_INJECTED absent) termine le maintien.
        test.held := false
        test.pendingStart := false
        SetTimer(CFRealReleasePending, -1)
        return true
    }
    return false
}

CFRealBeginPending(*) {
    global CF
    test := CF.realTest
    if !test.run || !test.held || !test.pendingStart
        return
    if !CFRealInside() {
        CFRealEnd("Curseur sorti de la zone de test.")
        return
    }
    if WinExist("A") != test.gui.Hwnd {
        ; Le tout premier clic peut activer la fenêtre APRÈS le passage
        ; du hook. Quelques réessais courts suffisent, sans voler le focus.
        if ++test.pendingAttempts <= 8 {
            SetTimer(CFRealBeginPending, -15)
        } else {
            test.pendingStart := false
            test.held := false
            CFRealUpdateStatus()
        }
        return
    }
    test.pendingStart := false
    now := CFNowMs()
    if !test.active {
        test.started := now
        test.endAt := now + test.duration * 1000
        test.active := true
        test.lastFlush := now
        CFNaturalReset(test.cfg)
        CFRealPost("started", ',"duration":' test.duration
            ',"profile":' JsonQuote(test.profile)
            ',"trigger":' JsonQuote(test.trigger))
        SetTimer(CFRealTick, 50)
    }
    test.nextAt := now
    if test.cfg.mode = 4
        CFRapidBurstReset(test.cfg)
    CFRealUpdateStatus()
    ; Démarrer le moteur hors du hook et préserver le premier clic.
    CFRealTick()
    if test.run && test.active && test.held
        CFEngineSetTimer(true)
}

CFRealReleasePending(*) {
    global CF
    test := CF.realTest
    if !test.run
        return
    if !test.held && !CF.armed && !CF.test.active
        CFEngineSetTimer(false)
    CFRealFlush()
    CFRealUpdateStatus()
}

CFRealUpdateStatus(*) {
    global CF
    test := CF.realTest
    if !test.run || !IsObject(test.status)
        return
    label := !test.active
        ? (test.held ? "APPUI PHYSIQUE DÉTECTÉ" : "PRÊT - En attente du premier appui")
        : (test.held ? "TEST EN COURS - Maintien détecté"
            : "PAUSE - Appui relâché, maintiens pour reprendre")
    test.status.Text := label
    if IsObject(test.counters)
        test.counters.Text := Format(
            "Appuis physiques : {}     Envoyés : {}     Reçus : {}     Restant : {} s",
            test.physical, test.sent, test.received,
            test.active ? Round(Max(0, test.endAt-CFNowMs())/1000, 1) : test.duration)
    if IsObject(test.zoneHint)
        test.zoneHint.Text := test.held
            ? "MAINTIEN DÉTECTÉ - CLICS EN COURS"
            : "MAINTIENS TON BOUTON ICI POUR DÉMARRER"
}

CFRealWindowTheme(windowGui, closeButton) {
    ; Windows 11 : titre natif foncé assorti à ClickFlow. Repli
    ; automatique sur la barre Windows standard si DWM ne le permet pas.
    dark := Buffer(4, 0)
    NumPut("Int", 1, dark, 0)
    try DllCall("Dwmapi\DwmSetWindowAttribute", "Ptr", windowGui.Hwnd,
        "UInt", 20, "Ptr", dark.Ptr, "UInt", 4, "Int")
    caption := Buffer(4, 0)
    NumPut("UInt", 0x241B12, caption, 0)
    try DllCall("Dwmapi\DwmSetWindowAttribute", "Ptr", windowGui.Hwnd,
        "UInt", 35, "Ptr", caption.Ptr, "UInt", 4, "Int")
    textColor := Buffer(4, 0)
    NumPut("UInt", 0xF7F7F7, textColor, 0)
    try DllCall("Dwmapi\DwmSetWindowAttribute", "Ptr", windowGui.Hwnd,
        "UInt", 36, "Ptr", textColor.Ptr, "UInt", 4, "Int")
    try DllCall("UxTheme\SetWindowTheme", "Ptr", closeButton.Hwnd,
        "WStr", "DarkMode_Explorer", "Ptr", 0, "Int")
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
    CFRealUpdateStatus()
}

CFRealEnd(reason := "arrêté", completed := false) {
    global CF
    if !CF.realTest.run
        return
    test := CF.realTest
    test.held := false
    test.active := false
    test.pendingStart := false
    try SetTimer(CFRealTick, 0)
    try SetTimer(CFRealBeginPending, 0)
    try SetTimer(CFRealReleasePending, 0)
    try SetTimer(CFRealUpdateStatus, 0)
    if test.hook
        DllCall("User32\UnhookWindowsHookEx", "Ptr", test.hook, "Int")
    if test.callback
        CallbackFree(test.callback)
    test.hook := 0
    test.callback := 0
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
    windowGui := test.gui
    test.run := 0
    test.gui := 0
    test.zone := 0
    for message in [0x201,0x202,0x204,0x205,0x207,0x208]
        try OnMessage(message, CFRealMouse, 0)
    try windowGui.Destroy()
}

CFRealClose(*) {
    CFRealEnd("Fenêtre de réception fermée.")
}

CFRealMouse(wParam, lParam, msg, hwnd) {
    global CF
    test := CF.realTest
    if !test.run || !IsObject(test.gui) || !IsObject(test.zone)
        return
    test.anyMouse += 1
    test.lastMsg := msg
    test.lastHwnd := hwnd
    extra := DllCall("User32\GetMessageExtraInfo", "Ptr")
    test.lastExtra := extra
    if hwnd != test.zone.Hwnd && hwnd != test.gui.Hwnd
        return
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
    ; L'appui physique est reçu par WH_MOUSE_LL, pas par le contrôle
    ; statique. WM_* ne sert plus qu'à mesurer les clics injectés.

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
    ; Fenêtre à barre de titre Windows native, contenu sombre ClickFlow.
    windowGui := Gui("+MinSize620x505", "ClickFlow - Réception réelle")
    windowGui.BackColor := "101D32"
    windowGui.SetFont("s16 w700 cF0F6FF", "Segoe UI")
    windowGui.AddText("x30 y22 w560 h34", "Réception réelle")
    windowGui.SetFont("s10 cB4C9E8", "Segoe UI")
    windowGui.AddText("x30 y65 w560 h32",
        "Profil : " profile.name "  |  " trigger " maintenu  |  "
        duration " s")
    windowGui.SetFont("s10 w600 c75B6FF", "Segoe UI")
    status := windowGui.AddText("x30 y112 w560 h40 +0x100 Center Background1B3454",
        "PRÊT - En attente du premier appui")
    windowGui.SetFont("s9 cC1D5EF", "Segoe UI")
    counters := windowGui.AddText("x30 y158 w560 h43 Center Background142943",
        "Appuis physiques : 0     Envoyés : 0     Reçus : 0")
    windowGui.SetFont("s11 w700 cEAF2FF", "Segoe UI")
    ; Le contrôle est volontairement statique : le hook reçoit les vrais
    ; boutons même lorsque Windows ne lui adresse pas WM_LBUTTONDOWN.
    zone := windowGui.AddText("x30 y217 w560 h184 Center Border 0x100 Background223E64",
        "ZONE DE RÉCEPTION" "`n`n"
        "Place le curseur ici et maintiens ton bouton.")
    windowGui.SetFont("s10 c8EE8D1", "Segoe UI")
    zoneHint := windowGui.AddText("x30 y412 w560 h25 Center",
        "MAINTIENS TON BOUTON ICI POUR DÉMARRER")
    windowGui.SetFont("s10 cEAF2FF", "Segoe UI")
    close := windowGui.AddButton("x399 y451 w191 h37", "Fermer / arrêter")
    close.OnEvent("Click", CFRealClose)
    windowGui.OnEvent("Close", CFRealClose)
    windowGui.OnEvent("Escape", CFRealClose)
    CF.realTest := {run: runId+0, active:false, held:false,
        pendingStart:false, pendingAttempts:0, physical:0,
        hook:0, callback:0,
        gui:windowGui, zone:zone, status:status, counters:counters,
        zoneHint:zoneHint, cfg:cfg, profile:profile.name,
        trigger:trigger, outButton:cfg.clickButton, duration:duration+0,
        started:0, endAt:0, nextAt:0,
        sent:0, received:0, lastSent:0, clicks:[],pending:[],lastFlush:0,
        anyMouse:0, lastMsg:0, lastHwnd:0, lastExtra:0}
    ; Seuls les clics injectés identifiés sont comptabilisés.
    for message in [0x201,0x202,0x204,0x205,0x207,0x208]
        OnMessage(message, CFRealMouse)
    windowGui.Show("w620 h505")
    CFRealWindowTheme(windowGui, close)
    test := CF.realTest
    test.callback := CallbackCreate(CFRealHookCallback, "Fast", 3)
    module := DllCall("Kernel32\GetModuleHandleW", "Ptr", 0, "Ptr")
    test.hook := DllCall("User32\SetWindowsHookExW",
        "Int", 14, "Ptr", test.callback, "Ptr", module,
        "UInt", 0, "Ptr")
    if !test.hook {
        CFRealEnd("Impossible d'installer la détection physique.")
        throw Error("Impossible d'installer le hook souris physique Windows.")
    }
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
        CFRealUpdateStatus()
        return
    }
    ; Le WM_*BUTTONUP physique non marqué est la référence.
    ; GetKeyState peut être temporairement faussé si l'on injecte
    ; le même bouton que celui qui est maintenu : ne pas l'utiliser
    ; comme motif d'arrêt pendant ce test.
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
