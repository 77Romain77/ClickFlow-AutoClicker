#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include lib\WebView2\WebView2.ahk
global CW := {gui: 0, controller: 0, web: 0, handler: 0}
FileAppend("found", EnvGet("CLICKFLOW_DIAG_FILE"), "UTF-8")
ExitApp()

try {
} catch as err {
    if probe != ""
        FileAppend(err.Message, probe ".error", "UTF-8")
    else
        MsgBox("Impossible d'ouvrir la fenêtre WebView2 : " err.Message, "ClickFlow", "Icon!")
    ExitApp(1)
}
