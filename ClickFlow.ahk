#Requires AutoHotkey v2.0
#SingleInstance Force

; ClickFlow - AutoClicker | AHK experimental v0.2
; Un script local, sans compilation et sans injection dans les processus cibles.
; F12 = arret d'urgence. Les touches physiques ne sont pas bloquees.

InstallKeybdHook()
InstallMouseHook()
SendMode("Input")

global CF := {
    gui: 0, controls: Map(), capture: false, inputHook: 0,
    pressed: false, armed: false, target: 0, nextAt: 0,
    cpsNow: 0, naturalCps: 12, naturalTarget: 12, nextVariation: 0,
    total: 0, recent: [], lastUi: 0, loading: true,
    configFile: A_AppData "\ClickFlow\settings.ini",
    cfg: { mode: 1, variation: 2, min: 8, max: 14,
           clickButton: "Left", activation: "F6", hold: 1,
           mouseGate: 0, gateButton: "RButton", focusStop: 1 }
}

LoadSettings()
BuildGui()
RegisterActivation()
Hotkey("~*F12", EmergencyStop, "On")
SetTimer(EngineTick, 10)
SetTimer(UpdateStats, 200)
OnExit(Cleanup)
CF.gui.Show("w674 h684")
CF.loading := false
SetNotice("Pret. Passe sur ta fenetre cible, puis appuie sur " CF.cfg.activation ".")

BuildGui() {
    global CF
    g := Gui(, "ClickFlow - AutoClicker | AutoHotkey v2")
    g.BackColor := "0D1320"
    CF.gui := g

    g.SetFont("s22 Bold cF0F4FF", "Segoe UI")
    g.AddText("x26 y20 w610 h42", "ClickFlow")
    g.SetFont("s10 Norm c91A6C6", "Segoe UI")
    g.AddText("x28 y66 w600 h22", "AutoClicker  |  AutoHotkey v2  |  Experimental 0.2")
    g.AddText("x28 y97 w610 h21", "CADENCE")
    g.SetFont("s10 Norm cF0F4FF", "Segoe UI")

    g.AddText("x28 y130 w220 h22", "Mode CPS")
    cMode := g.AddDropDownList("x28 y155 w260 Choose" CF.cfg.mode " c121827", ["Fixed", "Random", "Natural"])
    g.AddText("x318 y130 w210 h22", "Variation (Natural)")
    cVariation := g.AddDropDownList("x318 y155 w296 Choose" CF.cfg.variation " c121827", ["Low", "Medium", "High"])

    g.AddText("x28 y216 w310 h22", "CPS minimum / fixe")
    cMinSlider := g.AddSlider("x28 y242 w457 h31 Range1-100", CF.cfg.min)
    cMinEdit := g.AddEdit("x515 y241 w98 h29 Number c101827", CF.cfg.min)

    g.AddText("x28 y289 w310 h22", "CPS maximum")
    cMaxSlider := g.AddSlider("x28 y317 w457 h31 Range1-100", CF.cfg.max)
    cMaxEdit := g.AddEdit("x515 y316 w98 h29 Number c101827", CF.cfg.max)

    g.SetFont("s9 Norm c91A6C6", "Segoe UI")
    g.AddText("x28 y362 w620 h20", "Les valeurs vont de 1 a 100 CPS. La cadence reelle depend de Windows.")
    g.SetFont("s10 Norm cF0F4FF", "Segoe UI")

    g.AddText("x28 y394 w250 h20", "Bouton genere")
    cButton := g.AddDropDownList("x28 y419 w176 c101827", ["Gauche", "Droit", "Central"])
    cButton.Choose(CF.cfg.clickButton = "Left" ? 1 : CF.cfg.clickButton = "Right" ? 2 : 3)
    g.AddText("x225 y394 w250 h20", "Mode d'activation")
    cHold := g.AddDropDownList("x225 y419 w145 c101827", ["Hold", "Toggle"])
    cHold.Choose(CF.cfg.hold)
    cCapture := g.AddButton("x394 y416 w218 h33", "Touche : " CF.cfg.activation)

    cGate := g.AddCheckBox("x28 y473 w286 h23", "Exiger un bouton souris maintenu")
    cGate.Value := CF.cfg.mouseGate
    cGateButton := g.AddDropDownList("x323 y472 w180 c101827", ["Clic gauche", "Clic droit", "Clic central", "Mouse 4", "Mouse 5"])
    gateIndexes := Map("LButton", 1, "RButton", 2, "MButton", 3, "XButton1", 4, "XButton2", 5)
    cGateButton.Choose(gateIndexes.Get(CF.cfg.gateButton, 2))
    cFocus := g.AddCheckBox("x28 y510 w600 h24", "Arreter au changement de fenetre (recommande)")
    cFocus.Value := CF.cfg.focusStop

    g.SetFont("s10 Bold cF0F4FF", "Segoe UI")
    cStatus := g.AddText("x28 y553 w614 h28", "INACTIF")
    g.SetFont("s9 Norm c91A6C6", "Segoe UI")
    cStats := g.AddText("x28 y586 w580 h23", "CPS reels : 0     Clics : 0")
    cNotice := g.AddText("x28 y615 w614 h32", "")
    g.SetFont("s10 Norm cF0F4FF", "Segoe UI")
    cStop := g.AddButton("x485 y552 w127 h35", "Arreter (F12)")

    CF.controls := Map(
        "mode", cMode, "variation", cVariation,
        "minSlider", cMinSlider, "maxSlider", cMaxSlider,
        "minEdit", cMinEdit, "maxEdit", cMaxEdit,
        "button", cButton, "hold", cHold, "capture", cCapture,
        "gate", cGate, "gateButton", cGateButton, "focus", cFocus,
        "status", cStatus, "stats", cStats, "notice", cNotice
    )

    cMode.OnEvent("Change", ConfigChanged)
    cVariation.OnEvent("Change", ConfigChanged)
    cButton.OnEvent("Change", ConfigChanged)
    cHold.OnEvent("Change", ConfigChanged)
    cGateButton.OnEvent("Change", ConfigChanged)
    cGate.OnEvent("Click", ConfigChanged)
    cFocus.OnEvent("Click", ConfigChanged)
    cMinSlider.OnEvent("Change", (*) => SliderChanged("min"))
    cMaxSlider.OnEvent("Change", (*) => SliderChanged("max"))
    cMinEdit.OnEvent("Change", (*) => EditChanged("min"))
    cMaxEdit.OnEvent("Change", (*) => EditChanged("max"))
    cMinEdit.OnEvent("LoseFocus", (*) => RestoreEdit("min"))
    cMaxEdit.OnEvent("LoseFocus", (*) => RestoreEdit("max"))
    cCapture.OnEvent("Click", StartCapture)
    cStop.OnEvent("Click", EmergencyStop)
    g.OnEvent("Close", CloseApp)
    g.OnEvent("Escape", CloseApp)
    UpdateModeControls()
}

UpdateModeControls() {
    global CF
    CF.controls["variation"].Enabled := CF.cfg.mode = 3
    CF.controls["maxSlider"].Enabled := CF.cfg.mode != 1
    CF.controls["maxEdit"].Enabled := CF.cfg.mode != 1
    CF.controls["gateButton"].Enabled := CF.cfg.mouseGate = 1
}

ConfigChanged(*) {
    global CF
    if CF.loading
        return
    StopAll("Configuration modifiee. Reactive le raccourci.")
    c := CF.controls
    CF.cfg.mode := c["mode"].Value
    CF.cfg.variation := c["variation"].Value
    CF.cfg.hold := c["hold"].Value
    CF.cfg.clickButton := ["Left", "Right", "Middle"][c["button"].Value]
    CF.cfg.mouseGate := c["gate"].Value
    CF.cfg.gateButton := ["LButton", "RButton", "MButton", "XButton1", "XButton2"][c["gateButton"].Value]
    CF.cfg.focusStop := c["focus"].Value
    UpdateModeControls()
    SaveSettings()
}

SliderChanged(which) {
    global CF
    if CF.loading
        return
    control := CF.controls[which "Slider"]
    SetCps(which, Round(control.Value))
}

EditChanged(which) {
    global CF
    if CF.loading
        return
    txt := Trim(CF.controls[which "Edit"].Value)
    if RegExMatch(txt, "^\d{1,3}$") && (txt + 0) >= 1 && (txt + 0) <= 100
        SetCps(which, txt + 0, true)
}

RestoreEdit(which) {
    global CF
    if CF.loading
        return
    CF.controls[which "Edit"].Value := CF.cfg.%which%
}

SetCps(which, value, fromEdit := false) {
    global CF
    if value < 1 || value > 100
        return
    StopAll("Cadence modifiee. Reactive le raccourci.")
    CF.loading := true
    CF.cfg.%which% := value
    if CF.cfg.min > CF.cfg.max {
        if which = "min"
            CF.cfg.max := value
        else
            CF.cfg.min := value
    }
    for field in ["min", "max"] {
        CF.controls[field "Slider"].Value := CF.cfg.%field%
        if !(fromEdit && field = which)
            CF.controls[field "Edit"].Value := CF.cfg.%field%
    }
    CF.loading := false
    SaveSettings()
}

RegisterActivation() {
    global CF
    name := CF.cfg.activation
    Hotkey("~*" name, ActivationDown, "On")
    Hotkey("~*" name " Up", ActivationUp, "On")
}

UnregisterActivation() {
    global CF
    try Hotkey("~*" CF.cfg.activation, "Off")
    try Hotkey("~*" CF.cfg.activation " Up", "Off")
}

ActivationDown(*) {
    global CF
    if CF.capture || CF.pressed
        return
    CF.pressed := true
    if CF.armed {
        if CF.cfg.hold = 2
            StopAll("Arret par raccourci.")
        return
    }

    current := WinExist("A")
    if !current || current = CF.gui.Hwnd {
        SetNotice("Active d'abord la fenetre cible, puis utilise le raccourci.")
        return
    }

    CF.armed := true
    CF.target := current
    CF.nextAt := A_TickCount
    CF.naturalCps := (CF.cfg.min + CF.cfg.max) / 2
    CF.naturalTarget := CF.naturalCps
    CF.nextVariation := 0
    SetNotice("Clics actifs dans la fenetre choisie. F12 pour arreter.")
}

ActivationUp(*) {
    global CF
    CF.pressed := false
    if CF.cfg.hold = 1 && CF.armed
        StopAll("Touche relachee.")
}

EmergencyStop(*) {
    global CF
    if CF.capture {
        FinishCapture("")
        return
    }
    StopAll("Arret d'urgence (F12).")
}

StopAll(message) {
    global CF
    CF.armed := false
    CF.target := 0
    CF.nextAt := 0
    CF.cpsNow := 0
    SetNotice(message)
}

SetNotice(message) {
    global CF
    if CF.controls.Has("notice")
        CF.controls["notice"].Text := message
}

EngineTick() {
    global CF
    if !CF.armed || CF.capture
        return

    current := WinExist("A")
    if !current || current = CF.gui.Hwnd {
        StopAll("Arret : la fenetre ClickFlow a repris le focus.")
        return
    }
    if CF.cfg.focusStop && current != CF.target {
        StopAll("Arret : changement de fenetre detecte.")
        return
    }
    if CF.cfg.hold = 1 && !GetKeyState(CF.cfg.activation, "P") {
        StopAll("Arret : touche d'activation relachee.")
        return
    }
    if CF.cfg.mouseGate && !GetKeyState(CF.cfg.gateButton, "P") {
        CF.cpsNow := 0
        CF.nextAt := A_TickCount
        return
    }

    now := A_TickCount
    if now < CF.nextAt
        return
    cps := GetNextCps()
    CF.cpsNow := cps

    ; Les clics sont envoyes a la position actuelle du curseur.
    ; SendInput n'intercepte pas les clics manuels et n'injecte rien dans le jeu.
    SendInput("{Click " CF.cfg.clickButton "}")
    CF.total += 1
    CF.recent.Push(now)
    ; Evite les rafales de rattrapage apres une interruption.
    CF.nextAt := now + Max(10, Round(1000 / cps))
}

GetNextCps() {
    global CF
    minimum := CF.cfg.min
    maximum := CF.cfg.max
    if CF.cfg.mode = 1
        return minimum
    if CF.cfg.mode = 2
        return Random(minimum, maximum)

    now := A_TickCount
    if now >= CF.nextVariation {
        intensity := CF.cfg.variation
        radius := (maximum - minimum) * (intensity = 1 ? 0.22 : intensity = 2 ? 0.38 : 0.5)
        center := (minimum + maximum) / 2
        low := Max(minimum, Round(center - radius))
        high := Min(maximum, Round(center + radius))
        CF.naturalTarget := Random(low, high)
        CF.nextVariation := now + Random(350, 1100)
    }
    CF.naturalCps += (CF.naturalTarget - CF.naturalCps) * 0.2
    return Max(minimum, Min(maximum, CF.naturalCps))
}

UpdateStats() {
    global CF
    now := A_TickCount
    while CF.recent.Length && CF.recent[1] < now - 1000
        CF.recent.RemoveAt(1)

    state := CF.armed ? (CF.cfg.mouseGate && !GetKeyState(CF.cfg.gateButton, "P")
        ? "ARME - attente du bouton souris" : "ACTIF") : "INACTIF"
    CF.controls["status"].Text := state
    CF.controls["stats"].Text := "CPS reels : " CF.recent.Length
        "     Clics envoyes : " CF.total "     Touche : " CF.cfg.activation
}

StartCapture(*) {
    global CF
    StopAll("Selection de la touche...")
    CF.capture := true
    CF.controls["capture"].Text := "Appuie sur une touche..."
    UnregisterActivation()
    ; Interception pour ecouter uniquement : ne bloque pas les touches.
    ih := InputHook("V")
    ih.KeyOpt("{All}", "N")
    ih.OnKeyDown := CapturedKey
    CF.inputHook := ih
    for key in ["LButton", "RButton", "MButton", "XButton1", "XButton2"]
        Hotkey("~*" key, CapturedMouse.Bind(key), "On")
    ih.Start()
    SetNotice("Appuie sur une touche clavier ou souris. Echap pour annuler.")
}

CapturedKey(ih, vk, sc) {
    global CF
    if !CF.capture
        return
    name := GetKeyName(Format("vk{:02X}sc{:03X}", vk, sc))
    if name = "Esc" || name = "Escape" {
        FinishCapture("")
        return
    }
    if name = "F12" {
        FinishCapture("")
        SetNotice("F12 est reservee pour l'arret d'urgence.")
        return
    }
    if name = "" || InStr("|Shift|LShift|RShift|Ctrl|LCtrl|RCtrl|Alt|LAlt|RAlt|LWin|RWin|", "|" name "|")
        return
    FinishCapture(name)
}

CapturedMouse(key, *) {
    global CF
    if CF.capture
        FinishCapture(key)
}

FinishCapture(key) {
    global CF
    if !CF.capture
        return
    CF.capture := false
    if IsObject(CF.inputHook)
        CF.inputHook.Stop()
    CF.inputHook := 0
    for mouseKey in ["LButton", "RButton", "MButton", "XButton1", "XButton2"]
        try Hotkey("~*" mouseKey, "Off")

    old := CF.cfg.activation
    if key != ""
        CF.cfg.activation := key
    try {
        RegisterActivation()
    } catch as err {
        CF.cfg.activation := old
        RegisterActivation()
        SetNotice("Touche non prise en charge : " err.Message)
        key := ""
    }
    CF.pressed := false
    CF.controls["capture"].Text := "Touche : " CF.cfg.activation
    if key != "" {
        SaveSettings()
        SetNotice("Activation definie : " CF.cfg.activation ".")
    } else if old = CF.cfg.activation {
        SetNotice("Capture annulee. Activation conservee : " old ".")
    }
}

LoadSettings() {
    global CF
    file := CF.configFile
    if !FileExist(file)
        return

    for field in ["mode", "variation", "min", "max", "hold", "mouseGate", "focusStop"] {
        try {
            value := IniRead(file, "ClickFlow", field, CF.cfg.%field%)
            if RegExMatch(value, "^\d+$")
                CF.cfg.%field% := value + 0
        }
    }
    CF.cfg.mode := Max(1, Min(3, CF.cfg.mode))
    CF.cfg.variation := Max(1, Min(3, CF.cfg.variation))
    CF.cfg.min := Max(1, Min(100, CF.cfg.min))
    CF.cfg.max := Max(CF.cfg.min, Min(100, CF.cfg.max))
    CF.cfg.hold := Max(1, Min(2, CF.cfg.hold))
    CF.cfg.mouseGate := CF.cfg.mouseGate ? 1 : 0
    CF.cfg.focusStop := CF.cfg.focusStop ? 1 : 0

    for field in ["clickButton", "activation", "gateButton"]
        try CF.cfg.%field% := IniRead(file, "ClickFlow", field, CF.cfg.%field%)

    if !HasValue(["Left", "Right", "Middle"], CF.cfg.clickButton)
        CF.cfg.clickButton := "Left"
    if !HasValue(["LButton", "RButton", "MButton", "XButton1", "XButton2"], CF.cfg.gateButton)
        CF.cfg.gateButton := "RButton"
    if CF.cfg.activation = "F12" || CF.cfg.activation = ""
        CF.cfg.activation := "F6"
}

SaveSettings() {
    global CF
    if CF.loading
        return
    try {
        DirCreate(A_AppData "\ClickFlow")
        for field in ["mode", "variation", "min", "max", "hold", "mouseGate",
            "focusStop", "clickButton", "activation", "gateButton"] {
            IniWrite(CF.cfg.%field%, CF.configFile, "ClickFlow", field)
        }
    } catch as err {
        SetNotice("Impossible de sauvegarder les reglages : " err.Message)
    }
}

HasValue(array, value) {
    for item in array
        if item = value
            return true
    return false
}

CloseApp(*) {
    StopAll("Fermeture.")
    ExitApp()
}

Cleanup(*) {
    global CF
    try SetTimer(EngineTick, 0)
    try SetTimer(UpdateStats, 0)
    CF.armed := false
}
