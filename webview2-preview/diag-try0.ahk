#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
FileAppend("ok", EnvGet("CLICKFLOW_DIAG_FILE"), "UTF-8")
ExitApp()
try {
    x := 1
} catch as err {
    x := 2
}
