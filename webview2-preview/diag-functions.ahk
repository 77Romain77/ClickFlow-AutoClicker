#Requires AutoHotkey v2.0
#SingleInstance Force
#ErrorStdOut "UTF-8"
#Include lib\WebView2\WebView2.ahk

global CW := {gui: 0, controller: 0, web: 0, handler: 0}
FileAppend("found", EnvGet("CLICKFLOW_DIAG_FILE"), "UTF-8")
ExitApp()


WebResize(gui, state, width, height) {
    global CW
    if state != -1 && CW.controller
        try CW.controller.Fill()
}

WebMessage(sender, args) {
    if args.TryGetWebMessageAsString() = "ping"
        sender.PostWebMessageAsString("pong")
}

WebExit(*) {
    global CW
    CW.handler := 0
    CW.web := 0
    CW.controller := 0
    ExitApp()
}
