#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include lib\WebView2\WebView2.ahk
FileAppend("found", EnvGet("CLICKFLOW_DIAG_FILE"), "UTF-8")
main := Gui()
main.Show("w300 h200")
main.OnEvent("Close", (*) => ExitApp())
controller := WebView2.CreateControllerAsync(main.Hwnd).await2()
controller.Fill()
