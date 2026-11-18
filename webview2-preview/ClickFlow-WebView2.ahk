#Requires AutoHotkey v2.0
#SingleInstance Force
#ErrorStdOut "UTF-8"
#Include lib\WebView2\WebView2.ahk
#Include ClickFlow-Backend.ahk

; ClickFlow v0.3.3 - interface WebView2 + moteur AutoHotkey.
; Aucune connexion à un serveur n'est requise.
; Utiliser F12 pour arrêter immédiatement les clics.

htmlPath := A_ScriptDir "\ui\index.html"
dllPath := A_ScriptDir "\lib\WebView2\64bit\WebView2Loader.dll"
probe := EnvGet("CLICKFLOW_WEBVIEW_SMOKE_FILE")
if !FileExist(htmlPath) || !FileExist(dllPath) {
    MsgBox("Il manque un fichier ClickFlow. Extrais tout le contenu de l'archive ZIP.", "ClickFlow", "Icon!")
    ExitApp(1)
}
if A_PtrSize != 8 {
    MsgBox("Lance ClickFlow avec AutoHotkey v2 en 64 bits.", "ClickFlow", "Icon!")
    ExitApp(1)
}
dataRoot := EnvGet("LOCALAPPDATA")
if dataRoot = "" {
    MsgBox("Impossible de localiser le dossier LOCALAPPDATA.", "ClickFlow", "Icon!")
    ExitApp(1)
}
if probe != ""
    FileAppend("started", probe ".start", "UTF-8")

main := Gui("+Resize +MinSize900x640", "ClickFlow - AutoClicker v0.3.3")
main.MarginX := 0
main.MarginY := 0
main.OnEvent("Close", CloseClickFlow)
main.OnEvent("Size", ResizeClickFlow)
main.Show("w1120 h800")
if probe != ""
    FileAppend(main.Hwnd, probe ".hwnd", "UTF-8")

profileData := dataRoot "\ClickFlow\WebView2"
DirCreate(profileData)
controller := WebView2.CreateControllerAsync(main.Hwnd, 0, profileData, "", dllPath).await2()
controller.Fill()
web := controller.CoreWebView2

; Conserver la référence à l'abonnement WebView2 pour que le lien reste actif.
webEvent := web.WebMessageReceived(BackendMessage)
BackendInit(main.Hwnd, web)
web.NavigateToString(FileRead(htmlPath, "UTF-8"))
if probe != ""
    FileAppend("ready", probe, "UTF-8")

CloseClickFlow(*) {
    global controller, web, webEvent
    ; Sauvegarder et desactiver le moteur AVANT la fermeture de la fenetre.
    BackendExit()
    try webEvent := 0
    try web := 0
    try controller.Close()
    try controller := 0
    ExitApp()
}

ResizeClickFlow(gui, state, width, height) {
    global controller
    if state != -1 && IsSet(controller) && controller
        try controller.Fill()
}
