#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"

; Integration regression: run the actual detached uninstall helper with fake
; APPDATA/LOCALAPPDATA. The test never touches the user's real folders.
root := A_Temp "\ClickFlowUninstallHelperCI-" A_TickCount
localBase := root "\Local"
roamingBase := root "\Roaming"
desktop := root "\Desktop"
start := root "\Start"
sourceRoot := A_ScriptDir "\..\src"
try {
    EnvSet("LOCALAPPDATA", localBase)
    EnvSet("APPDATA", roamingBase)
    EnvSet("CLICKFLOW_SHORTCUT_TEST_DESKTOP", desktop)
    EnvSet("CLICKFLOW_SHORTCUT_TEST_STARTMENU", start)
    EnvSet("CLICKFLOW_UNINSTALL_CI", "1")

    for mode in ["keep", "all"] {
        app := localBase "\ClickFlow"
        roaming := roamingBase "\ClickFlow"
        DirCreate(app "\Runtime-1.1.0")
        DirCreate(app "\WebView2")
        DirCreate(roaming)
        DirCreate(desktop)
        DirCreate(start)
        FileAppend("runtime", app "\Runtime-1.1.0\app.txt", "UTF-8")
        FileAppend("cache", app "\WebView2\cache.txt", "UTF-8")
        FileAppend("launcher", app "\ClickFlow.ahk", "UTF-8")
        FileAppend("settings", roaming "\settings.ini", "UTF-8")

        helperDir := root "\Helper-" mode
        DirCreate(helperDir)
        helper := helperDir "\ClickFlow-Uninstall.ahk"
        FileCopy(sourceRoot "\ClickFlow-Uninstall.ahk", helper, true)
        FileCopy(sourceRoot "\ClickFlow-Maintenance.ahk",
            helperDir "\ClickFlow-Maintenance.ahk", true)
        ; Use a non-existent PID to simulate the application's completed close.
        exitCode := RunWait('"' A_AhkPath '" "' helper '" ' mode ' 999998', , "Hide")
        if exitCode
            throw Error("Detached helper failed in " mode " mode. Exit: " exitCode)
        if DirExist(app "\Runtime-1.1.0") || FileExist(app "\ClickFlow.ahk")
            throw Error("Detached helper did not delete the installed program.")
        if mode = "keep" && !FileExist(roaming "\settings.ini")
            throw Error("Detached helper removed saved profiles in keep mode.")
        if mode = "all" && DirExist(roaming)
            throw Error("Detached helper did not remove profiles in all mode.")
    }

    FileAppend("Detached helper keep/all modes passed.", "*", "UTF-8")
    try DirDelete(root, true)
    ExitApp(0)
} catch as err {
    FileAppend("HELPER REGRESSION FAILED: " err.Message, "*", "UTF-8")
    ExitApp(1)
}
