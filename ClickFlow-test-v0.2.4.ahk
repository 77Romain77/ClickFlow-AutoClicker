#Requires AutoHotkey v2.0
#SingleInstance Force

; ClickFlow - AutoClicker | AHK experimental v0.2.4
; Un script local, sans compilation et sans injection dans les processus cibles.
; F12 = arret d'urgence. Les touches physiques ne sont pas bloquees.

InstallKeybdHook()
InstallMouseHook()
SendMode("Input")

global CF := {
    gui: 0, controls: Map(), capture: false, inputHook: 0,
    pressed: false, armed: false, target: 0, nextAt: 0,
    cpsNow: 0, naturalCps: 12, naturalTarget: 12, nextVariation: 0,
    total: 0, recent: [], lastUi: 0, lastStatus: "", loading: true,
    profiles: [], selectedId: 1, nextId: 2,
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
CF.gui.Show("w700 h862")
CF.loading := false
SaveSettings()
SetNotice("Pret. Passe sur ta fenetre cible, puis appuie sur " DisplayKey(CF.cfg.activation) ".")

BuildGui() {
    global CF
    g := Gui("-Resize -MaximizeBox", "ClickFlow - AutoClicker | AHK v0.2.4")
    g.BackColor := "0B1220"
    CF.gui := g

    ; En-tete sobre, contrastes et lisibilite.
    g.SetFont("s24 Bold cF4F7FF", "Segoe UI")
    g.AddText("x28 y17 w360 h42", "ClickFlow")
    g.SetFont("s10 Norm cA9BAD7", "Segoe UI")
    g.AddText("x30 y60 w490 h22", "AutoClicker  /  AutoHotkey v2  /  Experimental 0.2.4")
    g.SetFont("s9 Bold c78A6FF", "Segoe UI")
    g.AddText("x573 y27 w88 h22 Center", "AHK v2")
    g.SetFont("s9 Norm c8CA3BF", "Segoe UI")
    g.AddText("x495 y68 w166 h18 Right", "Sauvegarde automatique")

    ; 01 - Profils. Tous les reglages restent independants par profil.
    g.AddText("x18 y96 w664 h92 Background162236", "")
    g.SetFont("s9 Bold c8CB3FF", "Segoe UI")
    g.AddText("x36 y107 w610 h18 Background162236", "01   PROFILS")
    g.SetFont("s9 Norm cA9BAD7", "Segoe UI")
    g.AddText("x36 y133 w190 h17 Background162236", "Profil actif")
    choices := []
    for p in CF.profiles
        choices.Push(p.name)
    g.SetFont("s10 Norm cF4F7FF", "Segoe UI")
    cProfile := g.AddDropDownList("x36 y153 w249 Choose" SelectedProfileIndex(), choices)
    g.SetFont("s9 Norm c162236", "Segoe UI")
    cNewProfile := g.AddButton("x297 y150 w83 h33", "Nouveau")
    cRenameProfile := g.AddButton("x385 y150 w86 h33", "Renommer")
    cDuplicateProfile := g.AddButton("x476 y150 w87 h33", "Dupliquer")
    cDeleteProfile := g.AddButton("x568 y150 w94 h33", "Supprimer")

    ; 02 - Cadence et sliders synchronises en temps reel.
    g.AddText("x18 y201 w664 h268 Background162236", "")
    g.SetFont("s9 Bold c8CB3FF", "Segoe UI")
    g.AddText("x36 y213 w600 h18 Background162236", "02   CADENCE")
    g.SetFont("s10 Norm cF4F7FF", "Segoe UI")
    g.AddText("x36 y242 w266 h20 Background162236", "Mode CPS")
    g.AddText("x352 y242 w285 h20 Background162236", "Variation naturelle")
    cMode := g.AddDropDownList("x36 y265 w275 Choose" CF.cfg.mode, ["Fixed", "Random", "Natural"])
    cVariation := g.AddDropDownList("x352 y265 w292 Choose" CF.cfg.variation, ["Low", "Medium", "High"])

    g.AddText("x36 y307 w285 h19 Background162236", "CPS minimum / fixe")
    cMinSlider := g.AddSlider("x36 y329 w474 h33 Range1-100 AltSubmit", CF.cfg.min)
    cMinEdit := g.AddEdit("x539 y328 w105 h31 Number Center c162236", CF.cfg.min)

    g.AddText("x36 y376 w285 h19 Background162236", "CPS maximum")
    cMaxSlider := g.AddSlider("x36 y399 w474 h33 Range1-100 AltSubmit", CF.cfg.max)
    cMaxEdit := g.AddEdit("x539 y398 w105 h31 Number Center c162236", CF.cfg.max)
    g.SetFont("s9 Norm c97A7C3", "Segoe UI")
    g.AddText("x36 y440 w610 h18 Background162236", "1 a 100 CPS - la cadence reelle depend de Windows.")

    ; 03 - Activation. Les boutons natifs Windows utilisent un texte fonce.
    g.AddText("x18 y482 w664 h194 Background162236", "")
    g.SetFont("s9 Bold c8CB3FF", "Segoe UI")
    g.AddText("x36 y494 w610 h18 Background162236", "03   ACTIVATION")
    g.SetFont("s10 Norm cF4F7FF", "Segoe UI")
    g.AddText("x36 y523 w166 h18 Background162236", "Bouton clique")
    g.AddText("x219 y523 w145 h18 Background162236", "Mode")
    g.AddText("x384 y523 w260 h18 Background162236", "Raccourci")
    cButton := g.AddDropDownList("x36 y547 w165", ["Gauche", "Droit", "Central"])
    cButton.Choose(CF.cfg.clickButton = "Left" ? 1 : CF.cfg.clickButton = "Right" ? 2 : 3)
    cHold := g.AddDropDownList("x219 y547 w145", ["Hold", "Toggle"])
    cHold.Choose(CF.cfg.hold)
    g.SetFont("s10 Norm c162236", "Segoe UI")
    cCapture := g.AddButton("x384 y545 w261 h35", "Definir la touche : " DisplayKey(CF.cfg.activation))

    g.SetFont("s10 Norm cF4F7FF", "Segoe UI")
    cGate := g.AddCheckBox("x36 y591 w301 h24 Background162236", "Exiger un bouton souris maintenu")
    cGate.Value := CF.cfg.mouseGate
    cGateButton := g.AddDropDownList("x352 y591 w193", ["Clic gauche", "Clic droit", "Clic central", "Mouse 4", "Mouse 5"])
    gateIndexes := Map("LButton", 1, "RButton", 2, "MButton", 3, "XButton1", 4, "XButton2", 5)
    cGateButton.Choose(gateIndexes.Get(CF.cfg.gateButton, 2))
    cFocus := g.AddCheckBox("x36 y630 w610 h24 Background162236", "Arreter au changement de fenetre (recommande)")
    cFocus.Value := CF.cfg.focusStop

    ; 04 - Etat en temps reel : statut colore et trois compteurs distincts.
    g.AddText("x18 y689 w664 h155 Background162236", "")
    g.SetFont("s9 Bold c8CB3FF", "Segoe UI")
    g.AddText("x36 y701 w610 h18 Background162236", "04   ETAT EN TEMPS REEL")
    g.SetFont("s12 Bold cA5BDDF", "Segoe UI")
    cStatus := g.AddText("x36 y726 w421 h24 Background162236", "INACTIF")
    g.SetFont("s10 Bold c162236", "Segoe UI")
    cStop := g.AddButton("x499 y717 w147 h36", "Arreter (F12)")

    g.AddText("x36 y761 w188 h51 Background0F1A2D", "")
    g.AddText("x232 y761 w188 h51 Background0F1A2D", "")
    g.AddText("x428 y761 w218 h51 Background0F1A2D", "")
    g.SetFont("s8 Norm c91A4C7", "Segoe UI")
    g.AddText("x49 y768 w160 h16 Background0F1A2D", "CPS REELS")
    g.AddText("x245 y768 w160 h16 Background0F1A2D", "CLICS ENVOYES")
    g.AddText("x441 y768 w182 h16 Background0F1A2D", "TOUCHE D'ACTIVATION")
    g.SetFont("s12 Bold cF4F7FF", "Segoe UI")
    cStatCps := g.AddText("x49 y786 w150 h22 Background0F1A2D", "0")
    cStatClicks := g.AddText("x245 y786 w152 h22 Background0F1A2D", "0")
    cStatHotkey := g.AddText("x441 y786 w187 h22 Background0F1A2D", DisplayKey(CF.cfg.activation))

    g.SetFont("s9 Norm cA9BAD7", "Segoe UI")
    cNotice := g.AddText("x36 y819 w610 h18 Background162236", "Pret.")

    CF.controls := Map(
        "profile", cProfile, "newProfile", cNewProfile, "renameProfile", cRenameProfile,
        "duplicateProfile", cDuplicateProfile, "deleteProfile", cDeleteProfile,
        "mode", cMode, "variation", cVariation,
        "minSlider", cMinSlider, "maxSlider", cMaxSlider,
        "minEdit", cMinEdit, "maxEdit", cMaxEdit,
        "button", cButton, "hold", cHold, "capture", cCapture,
        "gate", cGate, "gateButton", cGateButton, "focus", cFocus,
        "status", cStatus, "notice", cNotice,
        "statCps", cStatCps, "statClicks", cStatClicks, "statHotkey", cStatHotkey
    )

    cProfile.OnEvent("Change", ProfileChanged)
    cNewProfile.OnEvent("Click", NewProfile)
    cRenameProfile.OnEvent("Click", RenameProfile)
    cDuplicateProfile.OnEvent("Click", DuplicateProfile)
    cDeleteProfile.OnEvent("Click", DeleteProfile)
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

    try {
        dark := 1
        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", g.Hwnd,
            "Int", 20, "Int*", dark, "Int", 4)
    }
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
    txt := Trim(CF.controls[which "Edit"].Text)
    if RegExMatch(txt, "^\d{1,3}$") && (txt + 0) >= 1 && (txt + 0) <= 100
        SetCps(which, txt + 0, true)
}

RestoreEdit(which) {
    global CF
    if CF.loading
        return
    CF.controls[which "Edit"].Text := CF.cfg.%which%
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
            CF.controls[field "Edit"].Text := CF.cfg.%field%
    }
    CF.loading := false
    SetTimer(SaveSettings, -350)
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

    waiting := CF.armed && CF.cfg.mouseGate && !GetKeyState(CF.cfg.gateButton, "P")
    state := CF.capture ? "CHOIX DU RACCOURCI" : CF.armed ? (waiting ? "ARME - EN ATTENTE" : "ACTIF") : "INACTIF"
    color := CF.capture ? "8CB3FF" : waiting ? "FFC56A" : CF.armed ? "66D9B1" : "A5BDDF"

    if CF.lastStatus != state {
        CF.controls["status"].Text := state
        CF.controls["status"].SetFont("c" color)
        CF.lastStatus := state
    }

    CF.controls["statCps"].Text := CF.recent.Length
    CF.controls["statClicks"].Text := CF.total
    CF.controls["statHotkey"].Text := DisplayKey(CF.cfg.activation)
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
    FinishCapture(Format("vk{:02X}", vk))
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
    CF.controls["capture"].Text := "Definir la touche : " DisplayKey(CF.cfg.activation)
    if key != "" {
        SaveSettings()
        SetNotice("Activation definie : " DisplayKey(CF.cfg.activation) ".")
    } else if old = CF.cfg.activation {
        SetNotice("Capture annulee. Activation conservee : " DisplayKey(old) ".")
    }
}

DefaultConfig() {
    return {mode: 1, variation: 2, min: 8, max: 14,
        clickButton: "Left", activation: "F6", hold: 1,
        mouseGate: 0, gateButton: "RButton", focusStop: 1}
}

CopyConfig(cfg) {
    return {mode: cfg.mode, variation: cfg.variation, min: cfg.min, max: cfg.max,
        clickButton: cfg.clickButton, activation: cfg.activation, hold: cfg.hold,
        mouseGate: cfg.mouseGate, gateButton: cfg.gateButton, focusStop: cfg.focusStop}
}

SelectedProfileIndex() {
    global CF
    for index, profile in CF.profiles {
        if profile.id = CF.selectedId
            return index
    }
    return 1
}

ReadConfig(file, section, base) {
    cfg := CopyConfig(base)
    if !FileExist(file)
        return cfg
    for field in ["mode", "variation", "min", "max", "hold", "mouseGate", "focusStop"] {
        value := IniRead(file, section, field, cfg.%field%)
        if RegExMatch(value, "^\d+$")
            cfg.%field% := value + 0
    }
    for field in ["clickButton", "activation", "gateButton"]
        cfg.%field% := IniRead(file, section, field, cfg.%field%)

    cfg.mode := Max(1, Min(3, cfg.mode))
    cfg.variation := Max(1, Min(3, cfg.variation))
    cfg.min := Max(1, Min(100, cfg.min))
    cfg.max := Max(cfg.min, Min(100, cfg.max))
    cfg.hold := Max(1, Min(2, cfg.hold))
    cfg.mouseGate := cfg.mouseGate ? 1 : 0
    cfg.focusStop := cfg.focusStop ? 1 : 0
    if !HasValue(["Left", "Right", "Middle"], cfg.clickButton)
        cfg.clickButton := "Left"
    if !HasValue(["LButton", "RButton", "MButton", "XButton1", "XButton2"], cfg.gateButton)
        cfg.gateButton := "RButton"
    if cfg.activation = "" || cfg.activation = "!" || cfg.activation = "F12" || cfg.activation = "vk7B"
        cfg.activation := "F6"
    return cfg
}

LoadSettings() {
    global CF
    file := CF.configFile
    ; Conserve les reglages precedents dans le profil Principal.
    savedIds := FileExist(file) ? IniRead(file, "Profiles", "Ids", "") : ""
    if savedIds = "" {
        first := ReadConfig(file, "ClickFlow", DefaultConfig())
        CF.profiles := [{id: 1, name: "Principal", cfg: first}]
        CF.cfg := first
        CF.selectedId := 1
        CF.nextId := 2
        return
    }

    CF.profiles := []
    maxId := 0
    for raw in StrSplit(savedIds, ",") {
        raw := Trim(raw)
        if !RegExMatch(raw, "^\d+$")
            continue
        id := raw + 0
        if id < 1
            continue
        duplicate := false
        for prior in CF.profiles {
            if prior.id = id
                duplicate := true
        }
        if duplicate
            continue
        section := "Profile_" id
        name := Trim(IniRead(file, section, "Name", "Profil " id))
        if name = ""
            name := "Profil " id
        cfg := ReadConfig(file, section, DefaultConfig())
        CF.profiles.Push({id: id, name: name, cfg: cfg})
        maxId := Max(maxId, id)
    }
    if CF.profiles.Length = 0 {
        first := ReadConfig(file, "ClickFlow", DefaultConfig())
        CF.profiles.Push({id: 1, name: "Principal", cfg: first})
        maxId := 1
    }

    CF.selectedId := IniRead(file, "Profiles", "Selected", CF.profiles[1].id) + 0
    CF.nextId := Max(maxId + 1, IniRead(file, "Profiles", "NextId", maxId + 1) + 0)
    found := false
    for p in CF.profiles {
        if p.id = CF.selectedId {
            CF.cfg := p.cfg
            found := true
            break
        }
    }
    if !found {
        CF.selectedId := CF.profiles[1].id
        CF.cfg := CF.profiles[1].cfg
    }
}

SaveSettings(*) {
    global CF
    if CF.loading
        return
    try {
        DirCreate(A_AppData "\ClickFlow")
        ids := ""
        for p in CF.profiles {
            ids .= (ids = "" ? "" : ",") p.id
            section := "Profile_" p.id
            IniWrite(p.name, CF.configFile, section, "Name")
            for field in ["mode", "variation", "min", "max", "hold", "mouseGate",
                "focusStop", "clickButton", "activation", "gateButton"] {
                IniWrite(p.cfg.%field%, CF.configFile, section, field)
            }
        }
        IniWrite(ids, CF.configFile, "Profiles", "Ids")
        IniWrite(CF.selectedId, CF.configFile, "Profiles", "Selected")
        IniWrite(CF.nextId, CF.configFile, "Profiles", "NextId")
    } catch as err {
        SetNotice("Sauvegarde impossible : " err.Message)
    }
}

UpdateProfileList() {
    global CF
    oldLoading := CF.loading
    CF.loading := true
    menu := CF.controls["profile"]
    menu.Delete()
    names := []
    for p in CF.profiles
        names.Push(p.name)
    menu.Add(names)
    menu.Choose(SelectedProfileIndex())
    CF.loading := oldLoading
}

UpdateControlsForProfile() {
    global CF
    oldLoading := CF.loading
    CF.loading := true
    c := CF.controls
    cfg := CF.cfg
    c["mode"].Choose(cfg.mode)
    c["variation"].Choose(cfg.variation)
    c["minSlider"].Value := cfg.min
    c["maxSlider"].Value := cfg.max
    c["minEdit"].Text := cfg.min
    c["maxEdit"].Text := cfg.max
    c["button"].Choose(cfg.clickButton = "Left" ? 1 : cfg.clickButton = "Right" ? 2 : 3)
    c["hold"].Choose(cfg.hold)
    c["gate"].Value := cfg.mouseGate
    index := 1
    for i, key in ["LButton", "RButton", "MButton", "XButton1", "XButton2"] {
        if cfg.gateButton = key
            index := i
    }
    c["gateButton"].Choose(index)
    c["focus"].Value := cfg.focusStop
    c["capture"].Text := "Definir la touche : " DisplayKey(cfg.activation)
    c["statHotkey"].Text := DisplayKey(cfg.activation)
    UpdateModeControls()
    CF.loading := oldLoading
}

ProfileChanged(*) {
    global CF
    if CF.loading
        return
    index := CF.controls["profile"].Value
    if index < 1 || index > CF.profiles.Length
        return
    if CF.profiles[index].id = CF.selectedId
        return
    SelectProfile(index)
}

SelectProfile(index) {
    global CF
    if index < 1 || index > CF.profiles.Length
        return
    StopAll("Changement de profil : clics arretes.")
    UnregisterActivation()
    oldCfg := CF.cfg
    oldId := CF.selectedId
    CF.selectedId := CF.profiles[index].id
    CF.cfg := CF.profiles[index].cfg
    CF.pressed := false
    try {
        RegisterActivation()
    } catch as err {
        CF.cfg.activation := "F6"
        try {
            RegisterActivation()
        } catch {
            CF.cfg := oldCfg
            CF.selectedId := oldId
            RegisterActivation()
            UpdateProfileList()
            SetNotice("Raccourci invalide : " err.Message)
            return
        }
    }
    UpdateProfileList()
    UpdateControlsForProfile()
    SaveSettings()
    SetNotice("Profil actif : " CF.profiles[index].name ".")
}

PromptProfileName(title, suggested, ignoreId := 0) {
    global CF
    result := InputBox("Nom du profil (36 caracteres maximum) :", title, "w420 h145", suggested)
    if result.Result != "OK"
        return ""
    name := Trim(StrReplace(StrReplace(result.Value, Chr(10), " "), Chr(13), " "))
    if name = "" || StrLen(name) > 36 {
        MsgBox("Le nom doit contenir entre 1 et 36 caracteres.", "ClickFlow", "Icon!")
        return ""
    }
    for p in CF.profiles {
        if p.id != ignoreId && StrLower(p.name) = StrLower(name) {
            MsgBox("Un profil porte deja ce nom.", "ClickFlow", "Icon!")
            return ""
        }
    }
    return name
}

NewProfile(*) {
    global CF
    name := PromptProfileName("Creer un profil", "Profil " CF.nextId)
    if name = ""
        return
    id := CF.nextId
    CF.nextId += 1
    CF.profiles.Push({id: id, name: name, cfg: DefaultConfig()})
    SelectProfile(CF.profiles.Length)
}

DuplicateProfile(*) {
    global CF
    current := CF.profiles[SelectedProfileIndex()]
    name := PromptProfileName("Dupliquer le profil", current.name " - copie")
    if name = ""
        return
    id := CF.nextId
    CF.nextId += 1
    CF.profiles.Push({id: id, name: name, cfg: CopyConfig(CF.cfg)})
    SelectProfile(CF.profiles.Length)
}

RenameProfile(*) {
    global CF
    current := CF.profiles[SelectedProfileIndex()]
    name := PromptProfileName("Renommer le profil", current.name, current.id)
    if name = ""
        return
    current.name := name
    UpdateProfileList()
    SaveSettings()
    SetNotice("Profil renomme : " name ".")
}

DeleteProfile(*) {
    global CF
    if CF.profiles.Length < 2 {
        SetNotice("Il faut conserver au moins un profil.")
        return
    }
    index := SelectedProfileIndex()
    profile := CF.profiles[index]
    if MsgBox("Supprimer le profil '" profile.name "' ?", "ClickFlow", "YesNo Icon?") != "Yes"
        return
    StopAll("Profil supprime.")
    UnregisterActivation()
    CF.profiles.RemoveAt(index)
    try IniDelete(CF.configFile, "Profile_" profile.id)
    nextIndex := Min(index, CF.profiles.Length)
    CF.selectedId := CF.profiles[nextIndex].id
    CF.cfg := CF.profiles[nextIndex].cfg
    CF.pressed := false
    try RegisterActivation()
    catch {
        CF.cfg.activation := "F6"
        RegisterActivation()
    }
    UpdateProfileList()
    UpdateControlsForProfile()
    SaveSettings()
    SetNotice("Profil supprime : " profile.name ".")
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

DisplayKey(key) {
    if SubStr(key, 1, 2) = "vk" {
        try return GetKeyName(key)
    }
    return key
}
