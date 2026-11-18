#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include lib\WebView2\WebView2.ahk
global CW := {gui: 0, controller: 0, web: 0, handler: 0}
FileAppend("found", EnvGet("CLICKFLOW_DIAG_FILE"), "UTF-8")
ExitApp()

try {
    DirCreate(dataPath)
    CW.controller := WebView2.CreateControllerAsync(CW.gui.Hwnd, 0, dataPath, "", dll).await2()
    CW.web := CW.controller.CoreWebView2
    CW.handler := CW.web.WebMessageReceived((*) => 0)
    CW.controller.Fill()
    CW.web.NavigateToString(FileRead(path, "UTF-8"))
    if probe != ""
        FileAppend("ready", probe, "UTF-8")
} catch as err {
} catch as err {
 ExitApp()
}
