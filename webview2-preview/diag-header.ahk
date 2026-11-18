#Requires AutoHotkey v2.0
#SingleInstance Force
#ErrorStdOut "UTF-8"
#Include lib\WebView2\WebView2.ahk

global CW := {gui: 0, controller: 0, web: 0, event: 0}
htmlPath := A_ScriptDir "\ui\index.html"
loaderPath := A_ScriptDir "\lib\WebView2\64bit\WebView2Loader.dll"
probePath := EnvGet("CLICKFLOW_DIAG_FILE")
if probePath != ""
    FileAppend("header", probePath, "UTF-8")
ExitApp()
