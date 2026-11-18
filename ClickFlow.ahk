#Requires AutoHotkey v2.0
#SingleInstance Force

; ClickFlow - AutoClicker
; Prototype de compatibilite AutoHotkey v2.
; Cette version n'envoie aucun clic et n'installe aucun raccourci global.

cfGui := Gui(, "ClickFlow - AutoClicker | Test AutoHotkey v2")
cfGui.BackColor := "0D1320"
cfGui.SetFont("s22 Bold cF0F4FF", "Segoe UI")
cfGui.AddText("x24 y20 w515 h42", "ClickFlow")

cfGui.SetFont("s10 Norm c9AACC6", "Segoe UI")
cfGui.AddText("x26 y66 w520 h24", "AutoClicker  |  Prototype AHK v2")

cfGui.SetFont("s10 Norm cF0F4FF", "Segoe UI")
cfGui.AddText("x26 y112 w250 h22", "Profil")
cfGui.AddDropDownList("x26 y138 w245 Choose1", ["Profil de test"])

cfGui.AddText("x26 y186 w260 h22", "CPS (apercu de l'interface)")
cpsSlider := cfGui.AddSlider("x26 y218 w360 h32 Range1-100", 12)
cpsEdit := cfGui.AddEdit("x418 y216 w90 h27 Number", "12")

cfGui.SetFont("s10 Norm cF0F4FF", "Segoe UI")
testButton := cfGui.AddButton("x26 y282 w230 h40", "Tester les controles")
closeButton := cfGui.AddButton("x272 y282 w155 h40", "Fermer")

cfGui.SetFont("s9 Norm c9AACC6", "Segoe UI")
statusText := cfGui.AddText("x26 y342 w510 h52", "Pret : ce prototype ne genere aucun clic.")

cpsSlider.OnEvent("Change", SliderChanged)
testButton.OnEvent("Click", TestControls)
closeButton.OnEvent("Click", (*) => ExitApp())
cfGui.OnEvent("Close", (*) => ExitApp())
cfGui.OnEvent("Escape", (*) => ExitApp())

cfGui.Show("w552 h410")

SliderChanged(*) {
    global cpsSlider, cpsEdit
    cpsEdit.Value := cpsSlider.Value
}

TestControls(*) {
    global cpsSlider, cpsEdit, statusText

    input := Trim(cpsEdit.Value)
    if !RegExMatch(input, "^\d{1,3}$") || (input + 0) < 1 || (input + 0) > 100 {
        statusText.Text := "Entre une valeur CPS entre 1 et 100."
        return
    }

    cps := input + 0
    cpsSlider.Value := cps
    statusText.Text := "Test reussi ! Valeur : " cps " CPS. Aucun clic envoye."
}
