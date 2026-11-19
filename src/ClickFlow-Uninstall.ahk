#Requires AutoHotkey v2.0
#SingleInstance Off
#ErrorStdOut "UTF-8"
#Include ClickFlow-Maintenance.ahk

CFDebug(stage) {
    if EnvGet("CLICKFLOW_UNINSTALL_CI") = "1"
        try FileAppend(stage Chr(10), A_Temp "\ClickFlowUninstallChild-Debug.txt", "UTF-8")
}

CFDebug("started: args=" A_Args.Length " ci=" EnvGet("CLICKFLOW_UNINSTALL_CI"))

; Run only after confirmation inside ClickFlow. This helper lives in %TEMP%,
; outside the installation folder, so the active runtime can be removed safely.
if A_Args.Length != 2 || (A_Args[1] != "keep" && A_Args[1] != "all")
    ExitApp(2)
mode := A_Args[1]
CFDebug("mode=" mode)
pid := A_Args[2]
if !RegExMatch(pid, "^\d{1,9}$") || (pid + 0) < 1
    ExitApp(2)

; Never delete files used by a running WebView2 instance.
; If the parent has already closed, don't wait for an absent PID.
CFDebug("before process check pid=" pid)
if ProcessExist(pid + 0)
    try ProcessWaitClose(pid + 0, 20)
CFDebug("after process check")
if ProcessExist(pid + 0) {
    MsgBox("ClickFlow n'a pas pu se fermer. Aucun fichier n'a été supprimé.",
        "ClickFlow - Désinstallation", "Icon!")
    ExitApp(3)
}

try {
    CFDebug("before cleanup")
    CFMaintenanceCleanup(mode, CFMaintenancePaths())
    CFDebug("after cleanup")
    message := mode = "keep"
        ? "ClickFlow a été désinstallé. Les profils et paramètres personnels ont été conservés dans %APPDATA%\ClickFlow."
        : "ClickFlow et ses données personnelles ont été supprimés."
    if EnvGet("CLICKFLOW_UNINSTALL_CI") = "1"
        CFDebug("CI uninstall " mode " completed")
    else
        MsgBox(message Chr(10) Chr(10)
            "Le fichier .ahk téléchargé, s'il se trouve ailleurs, doit être supprimé manuellement.",
            "ClickFlow - Désinstallation terminée", "Iconi")
} catch as err {
    if EnvGet("CLICKFLOW_UNINSTALL_CI") = "1"
        CFDebug("CI uninstall failed: " err.Message)
    else
        MsgBox("La désinstallation n'a pas pu être entièrement terminée : " err.Message
            Chr(10) Chr(10) "Tu peux relancer ClickFlow pour réessayer.",
            "ClickFlow - Désinstallation", "Icon!")
    ExitApp(4)
}

; Cleanup our temporary helper after it has run.
try {
    FileDelete(A_ScriptDir "\ClickFlow-Maintenance.ahk")
    FileDelete(A_ScriptFullPath)
    DirDelete(A_ScriptDir)
}
CFDebug("before exit")
ExitApp()
