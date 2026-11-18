#Requires AutoHotkey v2.0
#SingleInstance Force
#ErrorStdOut "UTF-8"
#Include lib\WebView2\WebView2.ahk

; Test de démarrage de WebView2 - sans clics.
probe := EnvGet("CLICKFLOW_WEBVIEW_SMOKE_FILE")
if probe != ""
    FileAppend("started", probe ".first", "UTF-8")

main := Gui("+Resize", "ClickFlow - WebView2")
main.Show("w1120 h800")
main.OnEvent("Close", (*) => ExitApp())
if probe != ""
    FileAppend("window", probe ".start", "UTF-8")

loader := A_ScriptDir "\lib\WebView2\64bit\WebView2Loader.dll"
dataDir := A_LocalAppData "\ClickFlow\WebView2Preview"
DirCreate(dataDir)
controller := WebView2.CreateControllerAsync(main.Hwnd, 0, dataDir, "", loader).await2()
controller.Fill()
web := controller.CoreWebView2
web.NavigateToString(FileRead(A_ScriptDir "\ui\index.html", "UTF-8"))
if probe != ""
    FileAppend("ready", probe, "UTF-8")
