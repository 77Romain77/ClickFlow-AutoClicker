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
            throw Error("Le message natif DOWN ne reconnaît pas le nom du bouton de sortie.")
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

    ; Simulation de l'état de maintien uniquement pour provoquer un
    ; véritable SendInput marqué, puis compter son WM_LBUTTONDOWN.
    test := CF.realTest
    test.active := true
    test.held := true
    test.started := CFNowMs()
    test.endAt := test.started + 2000
    test.nextAt := test.started
    CFNaturalReset(test.cfg)
    CFRealTick()
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
    if test.received != test.sent
        throw Error("Les compteurs envoyés/reçus divergent sur le récepteur natif.")

    ; Le curseur hors du rectangle met fin au test sans nouvel envoi.
    MouseMove(NumGet(pt,0,"Int"),NumGet(pt,4,"Int")-120,0)
    Sleep(20)
    CFRealTick()
    if CF.realTest.run != 0
        throw Error("La sortie de zone n'a pas fermé le test.")
    if test.sent != 1
        throw Error("Un clic a été envoyé hors zone.")
    MouseMove(savedX,savedY,0)
    FileAppend("Native Windows SendInput receiver, tag filter, focus/zone guard and cleanup passed.",
        "*","UTF-8")
    ExitApp(0)
} catch as err {
    try CFRealEnd("erreur de test")
    try MouseMove(savedX,savedY,0)
    FileAppend("NATIVE CPS TEST FAILED: " err.Message " " err.File ":" err.Line,
        "*","UTF-8")
    ExitApp(1)
}
