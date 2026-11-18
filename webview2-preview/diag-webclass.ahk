#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include lib\WebView2\WebView2.ahk
FileAppend("found", EnvGet("CLICKFLOW_DIAG_FILE"), "UTF-8")
ExitApp()
unused := WebView2
