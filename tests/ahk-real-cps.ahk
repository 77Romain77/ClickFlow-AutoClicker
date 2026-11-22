#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include ..\src\ClickFlow-Backend.ahk

; Tests Windows du vrai récepteur. Une seule injection SendInput dans
; notre propre GUI dédiée ; aucun clic vers une application extérieure.
global CF
CF.web := 0
CF.loading := true
CF.shuttingDown := false
CF.armed := false
CF.test := {active:false}
CF.realTest := {run:0,active:false,held:false}
CF.profiles := [{id:1,name:"Test natif",cfg:DefaultConfig()}]
CF.selectedId := 1
CF.cfg := CF.profiles[1].cfg
savedX:=0,savedY:=0
CoordMode("Mouse","Screen")
MouseGetPos(&savedX,&savedY)

try {
    for item in [{b:"Left",down:0x2,up:0x4,wm:0x201},
        {b:"Right",down:0x8,up:0x10,wm:0x204},
        {b:"Middle",down:0x20,up:0x40,wm:0x207}] {
        input := CFRealInputBuffer(item.b)
        if input.stride != 40 || input.data.Size != 80
            throw Error("Taille INPUT incorrecte sous Windows x64.")
        if NumGet(input.data,20,"UInt") != item.down
            || NumGet(input.data,60,"UInt") != item.up
            || NumGet(input.data,32,"UPtr") != CFRealMarker()
            || NumGet(input.data,72,"UPtr") != CFRealMarker()
            throw Error("INPUT.dwFlags/dwExtraInfo invalide pour " item.b)
        if CFRealMouseMessageId(item.b, true) != item.wm
            || CFRealMouseMessageId(item.b="Left"?"LButton":item.b="Right"?"RButton":"MButton", true) != item.wm
            || CFRealMouseDoubleMessageId(item.b) != item.wm + 2
            throw Error("Le message natif DOWN/DBLCLK ne reconnaît pas le bouton de sortie.")
    }
    if !CFRealInfoIsTagged(CFRealMarker())
        || CFRealInfoIsTagged(0)
        || CFRealInfoIsTagged(0x1234)
        throw Error("Marqueur des événements de clic mal filtré.")
    if CFRealCanSend(false,true,true,true)
        || CFRealCanSend(true,false,true,true)
        || CFRealCanSend(true,true,false,true)
        || CFRealCanSend(true,true,true,false)
        || !CFRealCanSend(true,true,true,true)
        throw Error("Un clic serait possible hors de la fenêtre native.")

    CFRealOpen(2,7,1)
    if CF.realTest.run != 7 || !IsObject(CF.realTest.zone)
        throw Error("Fenêtre native de réception absente.")
    windowGui := CF.realTest.gui
    WinActivate("ahk_id " windowGui.Hwnd)
    if !WinWaitActive("ahk_id " windowGui.Hwnd, , 2)
        throw Error("Fenêtre native non active.")
    CF.realTest.zone.GetPos(&zx,&zy,&zw,&zh)
    pt := Buffer(8,0)
    NumPut("Int",zx+zw//2,pt,0)
    NumPut("Int",zy+zh//2,pt,4)
    if !DllCall("User32\ClientToScreen","Ptr",windowGui.Hwnd,"Ptr",pt.Ptr,"Int")
        throw Error("Coordonnées du récepteur indisponibles.")
    MouseMove(NumGet(pt,0,"Int"),NumGet(pt,4,"Int"),0)
    Sleep(100)
    if !CFRealInside()
        throw Error("Le curseur n'est pas dans la zone native de test.")

    ; Raw Input distingue les appuis physiques des clics injectés.
    ; Les tests unitaires des transitions sont déterministes, mais une
    ; vraie souris physique doit être vérifiée sur le poste utilisateur.
    test := CF.realTest
    test.cfg.mode := 1
    test.cfg.min := 1
    test.cfg.max := 1
    if !test.rawRegistered
        throw Error("Raw Input n'a pas été activé pour le récepteur natif.")
    if test.HasOwnProp("hook") || test.HasOwnProp("callback")
        throw Error("Le test natif installe encore un hook bas niveau.")
    for btn in [{key:"LButton",down:1,up:2},
        {key:"RButton",down:4,up:8},
        {key:"MButton",down:16,up:32}] {
        flags := CFRealRawButtonInfo(btn.key)
        if flags.down != btn.down || flags.up != btn.up
            throw Error("Mapping Raw Input incorrect pour " btn.key)
    }
    centerX := NumGet(pt, 0, "Int")
    centerY := NumGet(pt, 4, "Int")
    if CFRealPhysicalMessage(0x201, 1, CFRealMarker(), centerX, centerY)
        || CFRealPhysicalMessage(0x201, 1, 0, centerX, centerY)
        || test.physical != 0
        throw Error("Un clic injecté a armé le test réel.")
    if CFRealPhysicalMessage(0x201, 0, 0, centerX, centerY-260)
        throw Error("Un appui hors de la zone a armé le test réel.")
    CFRealRawPhysicalButtons(0x0001, centerX, centerY)
    if !test.held || !test.pendingStart || test.physical != 1
        throw Error("Le premier appui physique dans la zone n'est pas détecté.")
    CFRealBeginPending()
    if !test.active || test.pendingStart
        throw Error("Le premier appui physique n'a pas démarré le profil.")
    CFEngineSetTimer(false)
    Sleep(120)
    if test.sent != 1
        throw Error("L'injection unique native a échoué.")
    if test.received != 1 || test.clicks.Length != 1 {
        MouseGetPos(,,&underHwnd,&underCtrl,2)
        throw Error("Windows received mismatch: sent=" test.sent
            ", received=" test.received ", anyMouse=" test.anyMouse
            ", lastMsg=" test.lastMsg ", lastHwnd=" test.lastHwnd
            ", extra=" test.lastExtra ", Gui=" test.gui.Hwnd
            ", zone=" test.zone.Hwnd ", cursorWin=" underHwnd
            ", cursorCtrl=" underCtrl)
    }
    if !test.held || CFRealPhysicalMessage(0x202, 1, CFRealMarker(), centerX, centerY)
        || CFRealPhysicalMessage(0x202, 1, 0, centerX, centerY)
        || !test.held
        throw Error("Le bouton injecté relâche le maintien physique. held=" test.held
            " rawPackets=" test.rawButtonPackets
            " rawNullIgnored=" test.rawNullIgnored
            " rawFlags=" test.rawLastButtons
            " rawDevice=" test.rawLastDevice
            " sent=" test.sent " received=" test.received)
    CFRealRawPhysicalButtons(0x0002, centerX, centerY)
    if test.held
        throw Error("Le vrai relâchement ne met pas fin au maintien.")
    CFRealReleasePending()
    if CF.engineTimerActive
        throw Error("Le cadenceur tourne encore après le relâchement.")
    if test.received != test.sent
        throw Error("Les compteurs envoyés/reçus divergent sur le récepteur natif.")
    ; Nouvel appui physique : la même fenêtre doit rester utilisable.
    CFRealRawPhysicalButtons(0x0001, centerX, centerY)
    if test.physical != 2
        throw Error("Le second appui physique n'a pas été détecté.")
    CFRealBeginPending()
    CFEngineSetTimer(false)
    Sleep(80)
    if test.sent != 2 || test.received != 2
        throw Error("Un nouvel appui ne reprend pas les clics du profil :"
            " sent=" test.sent ", received=" test.received
            ", active=" test.active ", held=" test.held
            ", pending=" test.pendingStart ", run=" test.run
            ", focused=" (WinExist("A") = test.gui.Hwnd)
            ", inside=" CFRealInside()
            ", now=" CFNowMs() ", nextAt=" test.nextAt
            ", endAt=" test.endAt
            ", lastMsg=" test.lastMsg ", extra=" test.lastExtra)

    ; Une interruption ne doit jamais réentrer dans l'envoi de clics.
    ; Le watchdog ne doit pas produire de clic supplémentaire.
    beforeDispatch := test.sent
    test.dispatching := true
    CFRealTick()
    if test.sent != beforeDispatch || test.blockedDispatch != 1
        throw Error("Le verrou anti-reentrée du banc natif est inopérant.")
    test.dispatching := false
    CFRealWatchdog()
    if test.sent != beforeDispatch
        throw Error("Le watchdog a émis un clic hors cadenceur.")

    ; Avec des clics rapprochés, Windows peut émettre WM_*DBLCLK
    ; à la place de WM_*BUTTONDOWN. Tous doivent rester comptabilisés.
    test.cfg.mode := 1
    test.cfg.min := 50
    test.cfg.max := 50
    CFNaturalReset(test.cfg)
    test.nextAt := CFNowMs()
    Loop 18 {
        CFRealTick()
        Sleep(25)
    }
    Sleep(50)
    if test.sent < 12
        throw Error("Le test 50 CPS ne déclenche pas suffisamment de clics.")
    if test.received != test.sent
        throw Error("Les messages de double-clic sont perdus : sent="
            test.sent ", received=" test.received ", lastMsg=" test.lastMsg)
    if test.sentTicks.Length != test.sent
        throw Error("Horodatages d'envoi absents : sent="
            test.sent ", timestamps=" test.sentTicks.Length)
    if test.sentTicks.Length > 1
        && test.sentTicks[2] < test.sentTicks[1]
        throw Error("Horodatages du moteur non chronologiques.")
    if test.maxSendInputMs < 0 || test.maxSchedulerDelayMs < 0
        || test.maxPostMs < 0
        throw Error("Les diagnostics de durée ont une valeur négative.")

    ; Le curseur hors du rectangle met fin au test sans nouvel envoi.
    MouseMove(NumGet(pt,0,"Int"),NumGet(pt,4,"Int")-120,0)
    Sleep(20)
    CFRealTick()
    if CF.realTest.run != 0
        throw Error("La sortie de zone n'a pas fermé le test.")
    if test.rawRegistered
        throw Error("L'abonnement Raw Input est resté actif après fermeture.")
    if test.sent != test.received
        throw Error("Un clic a été envoyé hors zone.")
    ; Une fin native doit rester récupérable, même après destruction
    ; de la fenêtre, via la commande status du bridge.
    CFRealOpen(2, 8, 1)
    done := CF.realTest
    done.active := true
    done.held := false
    done.started := CFNowMs() - 2100
    done.endAt := CFNowMs() - 100
    done.clicks := [100, 200]
    done.sentTicks := [99, 199]
    done.maxSendInputMs := 12.5
    done.maxSchedulerDelayMs := 250.1
    done.blockedDispatch := 3
    done.sent := 2
    done.received := 2
    CFRealTick()
    if CF.realTest.run != 0 || CF.realResult.run != 8
        throw Error("La fin native ne conserve pas son identifiant de test.")
    if !InStr(CF.realResult.json, '"state":"finished"')
        || !InStr(CF.realResult.json, '"ticks":[100,200]')
        || !InStr(CF.realResult.json, '"sentTicks":[99,199]')
        || !InStr(CF.realResult.json, '"maxSendInputMs":12.5')
        || !InStr(CF.realResult.json, '"maxSchedulerDelayMs":250.1')
        || !InStr(CF.realResult.json, '"blockedDispatch":3')
        throw Error("Les chronologies et les diagnostics ne sont pas récupérables.")
    CFRealStatus(8)
    if CF.realResult.run != 8
        throw Error("La demande status a effacé le résultat natif.")
    MouseMove(savedX,savedY,0)
    FileAppend("Native Raw Input DOWN/UP, injected-input filter, tagged SendInput delivery, focus/zone guard, completion recovery and cleanup passed.",
        "*","UTF-8")
    ExitApp(0)
} catch as err {
    try CFRealEnd("erreur de test")
    try MouseMove(savedX,savedY,0)
    FileAppend("NATIVE CPS TEST FAILED: " err.Message " " err.File ":" err.Line,
        "*","UTF-8")
    ExitApp(1)
}
