#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include lib\WebView2\WebView2.ahk
FileAppend("include", EnvGet("CLICKFLOW_DIAG_FILE"), "UTF-8")
ExitApp()
