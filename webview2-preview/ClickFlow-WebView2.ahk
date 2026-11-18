#Requires AutoHotkey v2.0
#SingleInstance Force
#ErrorStdOut "UTF-8"
#Include lib\WebView2\WebView2.ahk

; Démarrage du prototype graphique ClickFlow.
; Cette version ne génère pas encore de clics et ne touche pas aux profils.

global CW := {gui: 0, controller: 0, web: 0, event: 0}
diag := EnvGet("CLICKFLOW_WEBVIEW_SMOKE_FILE")
if diag != ""
    FileAppend("started", diag ".first", "UTF-8")

pagePath := A_ScriptDir "\ui\index.html"
dllPath := A_ScriptDir "\lib\WebView2\64bit\WebView2Loader.dll"
if !FileExist(pagePath) {
    MsgBox("Interface HTML introuvable.", "ClickFlow", "Icon!")
    ExitApp()
}
if !FileExist(dllPath) {
    MsgBox("WebView2Loader.dll manquant. Extrais bien tout le ZIP.", "ClickFlow", "Icon!")
    ExitApp()
}

CW.gui := Gui("+Resize +MinSize900x640", "ClickFlow - WebView2")
CW.gui.MarginX := 0
CW.gui.MarginY := 0
CW.gui.OnEvent("Size", ResizeBrowser)
CW.gui.OnEvent("Close", CloseBrowser)
CW.gui.Show("w1120 h800")

if diag != ""
    FileAppend("script opened", diag ".start", "UTF-8")

dataDir := A_LocalAppData "\ClickFlow\WebView2Preview"
DirCreate(dataDir)
CW.controller := WebView2.CreateControllerAsync(CW.gui.Hwnd, 0, dataDir, "", dllPath).await2()
CW.web := CW.controller.CoreWebView2
CW.event := CW.web.WebMessageReceived(ReceiveBrowserMessage)
CW.controller.Fill()
CW.web.NavigateToString(FileRead(pagePath, "UTF-8"))

if diag != ""
    FileAppend("ready", diag, "UTF-8")

ResizeBrowser(gui, state, width, height) {
    global CW
    if state != -1 && CW.controller
        CW.controller.Fill()
}

ReceiveBrowserMessage(sender, args) {
    if args.TryGetWebMessageAsString() = "ping"
        sender.PostWebMessageAsString("pong")
}

CloseBrowser(*) {
    global CW
    CW.event := 0
    CW.web := 0
    CW.controller := 0
    ExitApp()
}
