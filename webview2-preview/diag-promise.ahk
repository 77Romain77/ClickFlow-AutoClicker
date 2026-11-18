#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include lib\Promise.ahk
FileAppend("promise", EnvGet("CLICKFLOW_DIAG_FILE"), "UTF-8")
ExitApp()
