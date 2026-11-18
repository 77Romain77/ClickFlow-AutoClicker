#Requires AutoHotkey v2.0
#SingleInstance Force
#Include lib\WebView2\WebView2.ahk

; ClickFlow - prototype graphique WebView2 v0.3.0.
; Aucun clic n'est genere. Ce script ne modifie pas settings.ini.
; Les profils de cette maquette sont temporaires.

global CW := {gui: 0, controller: 0, web: 0, event: 0}

htmlPath := A_ScriptDir "\ui\index.html"
loaderPath := A_ScriptDir "\lib\WebView2\64bit\WebView2Loader.dll"
probePath := EnvGet("CLICKFLOW_WEBVIEW_SMOKE_FILE")

try {
    if A_PtrSize != 8
        throw Error("Cette version nécessite AutoHotkey v2 en 64 bits.")
    if !FileExist(htmlPath)
        throw Error("Fichier d'interface manquant : " htmlPath)
    if !FileExist(loaderPath)
        throw Error("Composant WebView2Loader.dll manquant. Téléchargez l'archive ZIP complète.")

    g := Gui("+Resize +MinSize900x640", "ClickFlow - Prototype WebView2")
    g.MarginX := 0
    g.MarginY := 0
    g.BackColor := "090E1A"
    g.OnEvent("Size", ResizeWebView)
    g.OnEvent("Close", ClosePreview)
    g.OnEvent("Escape", ClosePreview)
    CW.gui := g
    g.Show("w1120 h800")

    userData := A_LocalAppData "\ClickFlow\WebView2Preview"
    DirCreate(userData)
    CW.controller := WebView2.CreateControllerAsync(g.Hwnd, 0, userData, "", loaderPath).await2()
    CW.web := CW.controller.CoreWebView2
    CW.event := CW.web.WebMessageReceived(HandleBridgeMessage)
    CW.controller.Fill()
    CW.web.NavigateToString(FileRead(htmlPath, "UTF-8"))

    ; Un marqueur de test permet au CI de vérifier la creation réelle du controle.
    if probePath != ""
        FileAppend("WebView2 initialized", probePath, "UTF-8")
} catch as err {
    if probePath != ""
        try FileAppend(err.Message, probePath ".error", "UTF-8")
    MsgBox("Impossible de lancer le prototype WebView2." Chr(10) Chr(10) err.Message
        Chr(10) Chr(10) "La version AutoHotkey classique de ClickFlow reste disponible.",
        "ClickFlow - WebView2", "Icon!")
    ExitApp(1)
}

ResizeWebView(gui, minMax, width, height) {
    global CW
    if minMax = -1
        return
    if CW.controller {
        try CW.controller.Fill()
    }
}

HandleBridgeMessage(sender, args) {
    ; Un ping simple prouve que l'interface HTML parle à AutoHotkey.
    ; Aucun message de cette maquette ne déclenche de clics.
    try {
        if args.TryGetWebMessageAsString() = "ping"
            sender.PostWebMessageAsString("pong")
    }
}

ClosePreview(*) {
    global CW
    CW.event := 0
    CW.web := 0
    CW.controller := 0
    ExitApp()
}
