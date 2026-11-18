#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include lib\WebView2\WebView2.ahk
global CW := {gui: 0, controller: 0, web: 0, handler: 0}
FileAppend("found", EnvGet("CLICKFLOW_DIAG_FILE"), "UTF-8")
ExitApp()

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
}
