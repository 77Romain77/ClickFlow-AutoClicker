#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include lib\ComVar.ahk
FileAppend("comvar", EnvGet("CLICKFLOW_DIAG_FILE"), "UTF-8")
ExitApp()
