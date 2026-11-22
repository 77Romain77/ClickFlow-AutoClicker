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

; Le système peut remplacer un deuxième WM_*BUTTONDOWN rapproché
; par WM_*BUTTONDBLCLK. Pour mesurer les clics réellement reçus,
; les deux messages représentent un nouvel appui.
CFRealMouseDoubleMessageId(button) {
    switch button {
        case "LButton", "Left": return 0x203
        case "RButton", "Right": return 0x206
        case "MButton", "Middle": return 0x209
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

; Les messages WM_* n'arrivent pas toujours sur le contrôle Text.
; La capture utilise désormais Raw Input pour les vrais appuis physiques.
; Contrairement à WH_MOUSE_LL, Raw Input ne demande pas une réponse
; synchrone du thread qui appelle SendInput (évite les blocages ~300 ms).
CFRealRawButtonInfo(button) {
    if button = "LButton"
        return {down:0x0001, up:0x0002, wmDown:0x201, wmUp:0x202}
    if button = "RButton"
        return {down:0x0004, up:0x0008, wmDown:0x204, wmUp:0x205}
    if button = "MButton"
        return {down:0x0010, up:0x0020, wmDown:0x207, wmUp:0x208}
    throw Error("Bouton physique non compatible avec Raw Input.")
}

CFRealRawPhysicalButtons(buttonFlags, x, y) {
    global CF
    test := CF.realTest
    if !test.run
        return
    button := CFRealRawButtonInfo(test.trigger)
    ; Un paquet peut contenir DOWN et UP. Respecter leur ordre logique.
    if buttonFlags & button.down
        CFRealPhysicalMessage(button.wmDown, 0, 0, x, y)
    if buttonFlags & button.up
        CFRealPhysicalMessage(button.wmUp, 0, 0, x, y)
}

CFRealRawInput(wParam, lParam, msg, hwnd) {
    global CF
    test := CF.realTest
    if !test.run || !test.rawRegistered || !IsObject(test.gui)
        || hwnd != test.gui.Hwnd || !lParam
        return
    headerSize := A_PtrSize = 8 ? 24 : 16
    bytes := 0
    rc := DllCall("User32\GetRawInputData", "Ptr", lParam, "UInt", 0x10000003,
        "Ptr", 0, "UInt*", &bytes, "UInt", headerSize, "UInt")
    if rc = 0xFFFFFFFF || bytes < headerSize+6 || bytes > 65536
        return
    data := Buffer(bytes, 0)
    size := bytes
    result := DllCall("User32\GetRawInputData", "Ptr", lParam,
        "UInt", 0x10000003, "Ptr", data.Ptr,
        "UInt*", &size, "UInt", headerSize, "UInt")
    if result = 0xFFFFFFFF || size < headerSize+6
        || NumGet(data, 0, "UInt") != 0
        return
    buttons := NumGet(data, headerSize+4, "UShort")
    if !(buttons & 0x003F)
        return
    deviceId := NumGet(data, 8, "Ptr")
    ; Win32 peut créer des WM_INPUT pour les clics SendInput avec
    ; hDevice=NULL (vérifié dans la CI Windows). Ne JAMAIS les traiter
    ; comme des événements matériels de maintien. Les vrais périphériques
    ; HID disposent d'un handle hDevice non nul.
    if !deviceId {
        test.rawNullIgnored += 1
        return
    }
    test.rawButtonPackets += 1
    test.rawLastButtons := buttons
    test.rawLastDevice := deviceId
    pt := Buffer(8, 0)
    if !DllCall("User32\GetCursorPos", "Ptr", pt.Ptr, "Int")
        return
    CFRealRawPhysicalButtons(buttons,
        NumGet(pt, 0, "Int"), NumGet(pt, 4, "Int"))
}

CFRealRegisterRawInput() {
    global CF
    test := CF.realTest
    if !test.run || !IsObject(test.gui)
        return false
    device := Buffer(8+A_PtrSize, 0)
    NumPut("UShort", 1, device, 0) ; HID Generic Desktop
    NumPut("UShort", 2, device, 2) ; Mouse
    NumPut("UInt", 0x100, device, 4) ; RIDEV_INPUTSINK
    NumPut("Ptr", test.gui.Hwnd, device, 8)
    OnMessage(0x00FF, CFRealRawInput)
    if DllCall("User32\RegisterRawInputDevices",
        "Ptr", device.Ptr, "UInt", 1, "UInt", device.Size, "Int") {
        test.rawRegistered := true
        return true
    }
    test.rawError := DllCall("Kernel32\GetLastError", "UInt")
    OnMessage(0x00FF, CFRealRawInput, 0)
    return false
}

CFRealUnregisterRawInput() {
    global CF
    test := CF.realTest
    if test.rawRegistered {
        device := Buffer(8+A_PtrSize, 0)
        NumPut("UShort", 1, device, 0)
        NumPut("UShort", 2, device, 2)
        NumPut("UInt", 1, device, 4) ; RIDEV_REMOVE, HWND = NULL
        NumPut("Ptr", 0, device, 8)
        DllCall("User32\RegisterRawInputDevices",
            "Ptr", device.Ptr, "UInt", 1, "UInt", device.Size, "Int")
        test.rawRegistered := false
    }
    OnMessage(0x00FF, CFRealRawInput, 0)
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
        SetTimer(CFRealWatchdog, 250)
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

CFRealWatchdog(*) {
    global CF
    test := CF.realTest
    if !test.run || !test.active
        return
    ; Ce timer ne produit JAMAIS de clic. Il garde uniquement le
    ; compte à rebours actif si le bouton physique a été relâché.
    if CFNowMs() >= test.endAt {
        if !test.dispatching
            CFRealTick()
        return
    }
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
    if !test.pending.Length && !test.pendingSent.Length && test.lastSent = test.sent
        return
    events := CFTestArrayJson(test.pending)
    sentEvents := CFTestArrayJson(test.pendingSent)
    test.pending := []
    test.pendingSent := []
    test.lastSent := test.sent
    postStarted := CFNowMs()
    CFRealPost("ticks", ',"ticks":' events
        ',"sentTicks":' sentEvents
        ',"sent":' test.sent ',"received":' test.received)
    postDuration := Max(0, CFNowMs()-postStarted)
    test.maxPostMs := Max(test.maxPostMs, postDuration)
    if postDuration >= 50
        test.slowPost += 1
    ; Les contrôles de la GUI ne sont rafraîchis que par le watchdog.
    ; Cela évite de modifier des contrôles Windows pendant un clic reçu.
}

; Une confirmation finale peut être renvoyée à WebView2 à sa demande.
; Le dernier résultat est conservé en mémoire, sans fichier sur disque.
CFRealStatus(runId) {
    global CF
    if !RegExMatch(String(runId), "^[1-9]\d{0,8}$")
        return
    runId += 0
    if CF.realResult.run = runId {
        CFTestPost(CF.realResult.json)
        return
    }
    test := CF.realTest
    if test.run != runId
        return
    if test.active && CFNowMs() >= test.endAt
        CFRealTick()
    else
        CFRealFlush()
}

CFRealEnd(reason := "arrêté", completed := false) {
    global CF
    if !CF.realTest.run
        return
    test := CF.realTest
    test.held := false
    test.active := false
    test.pendingStart := false
    try SetTimer(CFRealWatchdog, 0)
    try SetTimer(CFRealBeginPending, 0)
    try SetTimer(CFRealReleasePending, 0)
    try SetTimer(CFRealUpdateStatus, 0)
    CFRealUnregisterRawInput()
    if !CF.armed && !CF.test.active
        CFEngineSetTimer(false)
    if completed {
        ; Mémoriser le message AVANT la fermeture de la GUI native.
        ; Si WebView2 perd cette notification, la commande status la renvoie.
        resultJson := ('{"type":"cpsReal","state":"finished","run":' test.run
            ',"duration":' test.duration
            ',"profile":' JsonQuote(test.profile)
            ',"sent":' test.sent
            ',"received":' test.received
            ',"ticks":' CFTestArrayJson(test.clicks)
            ',"sentTicks":' CFTestArrayJson(test.sentTicks)
            ',"maxSendInputMs":' Round(test.maxSendInputMs, 3)
            ',"slowSendInput":' test.slowSendInput
            ',"maxSchedulerDelayMs":' Round(test.maxSchedulerDelayMs, 3)
            ',"slowScheduler":' test.slowScheduler
            ',"blockedDispatch":' test.blockedDispatch
            ',"maxPostMs":' Round(test.maxPostMs, 3)
            ',"slowPost":' test.slowPost
            ',"rawButtonPackets":' test.rawButtonPackets
            ',"rawNullIgnored":' test.rawNullIgnored '}')
        CF.realResult := {run: test.run, json: resultJson}
        if !CF.shuttingDown
            CFTestPost(resultJson)
    } else {
        CFRealPost("stopped", ',"reason":' JsonQuote(reason) '}')
    }
    windowGui := test.gui
    test.run := 0
    test.gui := 0
    test.zone := 0
    for message in [0x201,0x202,0x203,0x204,0x205,0x206,0x207,0x208,0x209]
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
        if test.active && (msg = CFRealMouseMessageId(test.outButton, true)
            || msg = CFRealMouseDoubleMessageId(test.outButton)) {
            ; Seuls les clics générés par CE test comptent.
            offset := Max(0, CFNowMs()-test.started)
            if offset < test.duration*1000 {
                test.clicks.Push(offset)
                test.pending.Push(offset)
                test.received += 1
                ; Réduire les échanges WebView2 : le récepteur natif
                ; reste léger même pendant les tests continus à 100 CPS.
                if CFNowMs()-test.lastFlush >= 330 || test.pending.Length >= 32 {
                    test.lastFlush := CFNowMs()
                    CFRealFlush()
                }
            }
        }
        return
    }
    ; L'appui physique est reçu par Raw Input, pas par ce contrôle.
    ; WM_* sert uniquement à compter les clics injectés.

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
    ; Le contrôle est volontairement statique : Raw Input distingue
    ; les appuis matériels des clics injectés par SendInput.
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
        rawRegistered:false, rawButtonPackets:0, rawError:0,
        rawNullIgnored:0, rawLastButtons:0, rawLastDevice:0,
        gui:windowGui, zone:zone, status:status, counters:counters,
        zoneHint:zoneHint, cfg:cfg, profile:profile.name,
        trigger:trigger, outButton:cfg.clickButton, duration:duration+0,
        started:0, endAt:0, nextAt:0,
        sent:0, received:0, lastSent:0, clicks:[],pending:[],
        sentTicks:[], pendingSent:[], lastFlush:0,
        dispatching:false, blockedDispatch:0,
        maxSendInputMs:0, slowSendInput:0,
        maxSchedulerDelayMs:0, slowScheduler:0,
        maxPostMs:0, slowPost:0,
        anyMouse:0, lastMsg:0, lastHwnd:0, lastExtra:0}
    ; Seuls les clics injectés identifiés sont comptabilisés.
    for message in [0x201,0x202,0x203,0x204,0x205,0x206,0x207,0x208,0x209]
        OnMessage(message, CFRealMouse)
    windowGui.Show("w620 h505")
    CFRealWindowTheme(windowGui, close)
    test := CF.realTest
    if !CFRealRegisterRawInput() {
        errorCode := test.rawError
        CFRealEnd("Détection physique Raw Input indisponible.")
        throw Error("Impossible d'activer Raw Input pour le test réel (Win32 "
            errorCode ").")
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
    ; Le watchdog et le cadenceur de haute précision ne doivent jamais
    ; pouvoir envoyer deux clics à partir de la même échéance.
    if test.dispatching {
        test.blockedDispatch += 1
        return
    }
    test.dispatching := true
    try {
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
            if test.pending.Length || test.pendingSent.Length
                || test.lastSent != test.sent
                CFRealFlush()
            return
        }
        ; Seul ce chemin de dispatch gère les clics, jamais le watchdog.
        if now < test.nextAt
            return
        if !CFRealCanSend(focused, inside, test.held, test.active)
            return
        schedulerDelay := Max(0, now-test.nextAt)
        test.maxSchedulerDelayMs := Max(test.maxSchedulerDelayMs, schedulerDelay)
        if schedulerDelay >= 100
            test.slowScheduler += 1

        period := GetNextIntervalMs(test.cfg, now)
        input := CFRealInputBuffer(test.outButton)
        ; Réserver l'échéance AVANT SendInput : les messages Windows peuvent
        ; interrompre le thread AHK pendant l'appel système.
        test.nextAt := CFNextDeadline(test.nextAt, now, period)
        sendStart := CFNowMs()
        sent := DllCall("User32\SendInput", "UInt", 2,
            "Ptr", input.data.Ptr, "Int", input.stride, "UInt")
        sendDone := CFNowMs()
        sendDuration := Max(0, sendDone-sendStart)
        test.maxSendInputMs := Max(test.maxSendInputMs, sendDuration)
        if sendDuration >= 50
            test.slowSendInput += 1
        if !test.run || !test.active
            return
        if sent != 2 {
            CFRealEnd("SendInput n'a pas pu envoyer les deux événements.")
            return
        }
        test.sent += 1
        sentOffset := Max(0, sendDone-test.started)
        test.sentTicks.Push(sentOffset)
        test.pendingSent.Push(sentOffset)

        ; Ne pas additionner systématiquement la durée de SendInput
        ; à l'intervalle demandé (cela plafonnait le test à ~88 CPS).
        ; Si l'échéance est déjà dépassée ou trop proche, replanifier
        ; une seule période complète : aucun clic de rattrapage.
        if test.nextAt <= sendDone + CFDeadlineMinLead(period)
            test.nextAt := sendDone + period
        if sendDone-test.lastFlush >= 350 {
            test.lastFlush := sendDone
            CFRealFlush()
        }
    } finally {
        test.dispatching := false
    }
}
