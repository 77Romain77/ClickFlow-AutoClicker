#Requires AutoHotkey v2.0
#SingleInstance Force
#ErrorStdOut "UTF-8"
#Include lib\WebView2\WebView2.ahk

; ClickFlow WebView2: lancement indépendant sans clics automatiques.
; Les profils et settings.ini ne sont pas modifiés par ce prototype.

global CW := {gui: 0, controller: 0, web: 0, handler: 0}
StartWebView()

StartWebView() {
    global CW
    probe := EnvGet("CLICKFLOW_WEBVIEW_SMOKE_FILE")
    if probe != ""
        FileAppend("script entered", probe ".start", "UTF-8")

    try {
    path := A_ScriptDir "\ui\index.html"
    dll := A_ScriptDir "\lib\WebView2\64bit\WebView2Loader.dll"
    if A_PtrSize != 8
        throw Error("AutoHotkey 64 bits est nécessaire.")
    if !FileExist(path)
        throw Error("Fichier d'interface manquant : " path)
    if !FileExist(dll)
        throw Error("WebView2Loader.dll manque dans le dossier lib.")

    CW.gui := Gui("+Resize +MinSize900x640", "ClickFlow - WebView2")
    CW.gui.MarginX := 0
    CW.gui.MarginY := 0
    CW.gui.OnEvent("Size", WebResize)
    CW.gui.OnEvent("Close", WebExit)
    CW.gui.Show("w1120 h800")
    if probe != ""
        FileAppend("gui shown", probe ".gui", "UTF-8")

    dataPath := A_LocalAppData "\ClickFlow\WebView2Preview"
    DirCreate(dataPath)
    CW.controller := WebView2.CreateControllerAsync(CW.gui.Hwnd, 0, dataPath, "", dll).await2()
    CW.web := CW.controller.CoreWebView2
    CW.handler := CW.web.WebMessageReceived(WebMessage)
    CW.controller.Fill()
    CW.web.NavigateToString(FileRead(path, "UTF-8"))
    if probe != ""
        FileAppend("ready", probe, "UTF-8")
} catch as err {
    if probe != ""
        FileAppend(err.Message, probe ".error", "UTF-8")
    else
        MsgBox("Impossible d'ouvrir la fenêtre WebView2 : " err.Message, "ClickFlow", "Icon!")
    ExitApp(1)
    }
}

WebResize(gui, state, width, height) {
    global CW
    if state != -1 && CW.controller
        try CW.controller.Fill()
}

WebMessage(sender, args) {
    if args.TryGetWebMessageAsString() = "ping"
        sender.PostWebMessageAsString("pong")
}

WebExit(*) {
    global CW
    CW.handler := 0
    CW.web := 0
    CW.controller := 0
    ExitApp()
}
