#Requires AutoHotkey v2.0
#SingleInstance Off
#ErrorStdOut "UTF-8"
#Include lib\WebView2\WebView2.ahk
#Include ClickFlow-Backend.ahk

; ClickFlow v1.9.9 - interface WebView2 + moteur AutoHotkey.
; Aucune connexion à un serveur n'est requise.
; La touche d'arrêt d'urgence est personnalisable (F12 par défaut).

 ; Un mutex par session empêche deux moteurs WebView2 de partager le même profil.
; #SingleInstance Force arrêtait brutalement l'ancien processus, ce qui
; pouvait provoquer un appel COM après libération du contrôleur WebView2.
global cfMutex := DllCall("Kernel32\CreateMutexW", "Ptr", 0, "Int", 0,
    "Str", "Local\ClickFlow-AutoCliker-OneInstance", "Ptr")
mutexAlreadyHeld := A_LastError = 183
if !cfMutex {
    MsgBox("Impossible de sécuriser le lancement de ClickFlow.", "ClickFlow", "Icon!")
    ExitApp(1)
}

; La détection de fenêtre gère aussi les versions v1.0.0 déjà ouvertes,
; qui n'avaient pas de mutex et ne doivent pas être fermées de force.
if mutexAlreadyHeld || FindRunningClickFlow() {
    RaiseRunningClickFlow()
    DllCall("Kernel32\CloseHandle", "Ptr", cfMutex)
    ExitApp()
}

htmlPath := A_ScriptDir "\ui\index.html"
dllPath := A_ScriptDir "\lib\WebView2\64bit\WebView2Loader.dll"
iconPath := A_ScriptDir "\assets\ClickFlow.ico"
if FileExist(iconPath) {
    try TraySetIcon(iconPath)
}
probe := EnvGet("CLICKFLOW_WEBVIEW_SMOKE_FILE")
if !FileExist(htmlPath) || !FileExist(dllPath) {
    MsgBox("Il manque un fichier ClickFlow. Extrais tout le contenu de l'archive ZIP.", "ClickFlow", "Icon!")
    ExitApp(1)
}
if A_PtrSize != 8 {
    MsgBox("Lance ClickFlow avec AutoHotkey v2 en 64 bits.", "ClickFlow", "Icon!")
    ExitApp(1)
}
dataRoot := EnvGet("LOCALAPPDATA")
if dataRoot = "" {
    MsgBox("Impossible de localiser le dossier LOCALAPPDATA.", "ClickFlow", "Icon!")
    ExitApp(1)
}
if probe != ""
    FileAppend("started", probe ".start", "UTF-8")

main := Gui("+Resize +MinSize460x480", "ClickFlow - AutoCliker v1.9.9")
main.MarginX := 0
main.MarginY := 0
main.OnEvent("Close", CloseClickFlow)
main.OnEvent("Size", ResizeClickFlow)
settingsPath := A_AppData "\ClickFlow\settings.ini"
compactAtStart := IniRead(settingsPath, "General", "CompactMode", "0") = "1"
; Les tailles sont des rectangles EXTERIEURS, identiques à WinMove.
startW := compactAtStart
    ? CFDesktopInt(IniRead(settingsPath, "General", "MainCompactWidth", "480"),
        480, 480, 1200)
    : CFDesktopInt(IniRead(settingsPath, "General", "MainExpandedWidth", "1120"),
        1120, 600, 2400)
startH := compactAtStart
    ? CFDesktopInt(IniRead(settingsPath, "General", "MainCompactHeight", "600"),
        600, 480, 1600)
    : CFDesktopInt(IniRead(settingsPath, "General", "MainExpandedHeight", "800"),
        800, 500, 1600)
main.Show("w" startW " h" startH)
; Position centrée sur l'écran actuel, dimensions limitées à la zone visible.
CFDesktopCenterMain(main.Hwnd, startW, startH)
; Conserver la barre Windows native (redimensionnement, fermer/réduire)
; en harmonisant sa couleur avec le thème de ClickFlow quand DWM le permet.
try CFDesktopStyleTitlebar(main.Hwnd)
if FileExist(iconPath) {
    ; WM_SETICON : la fenetre et la barre des taches utilisent notre icone,
    ; independamment de celle de l'interpreteur AutoHotkey.
    try {
        hSmall := LoadPicture(iconPath, "Icon1 w32 h32", &iconType)
        hBig := LoadPicture(iconPath, "Icon1 w48 h48", &iconType)
        if hSmall
            SendMessage(0x80, 0, hSmall, , main.Hwnd)
        if hBig
            SendMessage(0x80, 1, hBig, , main.Hwnd)
    }
}
if probe != ""
    FileAppend(main.Hwnd, probe ".hwnd", "UTF-8")

try {
    profileData := dataRoot "\ClickFlow\WebView2"
    DirCreate(profileData)
    controller := WebView2.CreateControllerAsync(main.Hwnd, 0, profileData, "", dllPath).await2()
    controller.Fill()
    web := controller.CoreWebView2
    webEvent := web.WebMessageReceived(BackendMessage)
    if probe != ""
        FileAppend("before backend", probe ".controller", "UTF-8")
    BackendInit(main.Hwnd, web)
    if probe != ""
        FileAppend("backend initialized", probe ".backend", "UTF-8")
    web.NavigateToString(FileRead(htmlPath, "UTF-8"))
    if probe != ""
        FileAppend("ready", probe, "UTF-8")
    ; Nettoyage après initialisation réussie, jamais pendant la fermeture.
    SetTimer(CleanOldRuntimeCaches, -1200)
} catch as err {
    details := err.Message " (" err.File ":" err.Line ")"
    if probe != ""
        FileAppend(details, probe ".error", "UTF-8")
    else
        MsgBox("Impossible de démarrer ClickFlow : " details, "ClickFlow", "Icon!")
    ExitApp(1)
}

FindRunningClickFlow() {
    ; La fenêtre peut être masquée par les préférences de notification.
    ; Le mutex empêche toute seconde instance même lorsqu'elle est invisible.
    SetTitleMatchMode(2)
    DetectHiddenWindows(true)
    hwnd := WinExist("ClickFlow - AutoCliker ahk_class AutoHotkeyGUI")
    DetectHiddenWindows(false)
    return hwnd
}

RaiseRunningClickFlow() {
    ; Une instance peut encore être en train d'initialiser sa fenêtre.
    Loop 35 {
        hwnd := FindRunningClickFlow()
        if hwnd {
            try WinShow("ahk_id " hwnd)
            try WinRestore("ahk_id " hwnd)
            try WinActivate("ahk_id " hwnd)
            return true
        }
        Sleep(100)
    }
    return false
}

CleanOldRuntimeCaches(*) {
    ; Seuls les caches versionnés créés par notre lanceur sont supprimés.
    ; Ne jamais toucher aux profils, aux paramètres ou au dossier WebView2.
    root := EnvGet("LOCALAPPDATA") "\ClickFlow"
    if !RegExMatch(A_ScriptDir, "i)\\Runtime-\d+\.\d+\.\d+$")
        return
    Loop Files root "\Runtime-*", "D" {
        name := A_LoopFileName
        oldDir := A_LoopFileFullPath
        if !RegExMatch(name, "^Runtime-\d+\.\d+\.\d+$")
            continue
        if StrLower(oldDir) = StrLower(A_ScriptDir)
            continue
        ; Ne pas suivre les jonctions ou les liens symboliques Windows.
        attrs := DllCall("Kernel32\GetFileAttributesW", "Str", oldDir, "UInt")
        if attrs = 0xFFFFFFFF || (attrs & 0x400)
            continue
        ; Ne supprimer que les anciens runtimes dont on connaît le format.
        if !FileExist(oldDir "\.extracted-ok")
            continue
        try DirDelete(oldDir, true)
    }
}

CloseClickFlow(*) {
    global controller, web, webEvent, CF
    if CF.closeToTray && !CF.forceExit {
        CFDesktopHide()
        return true
    }
    ; Sauvegarder et desactiver le moteur AVANT la fermeture de la fenetre.
    BackendExit()
    try webEvent := 0
    try web := 0
    try controller.Close()
    try controller := 0
    ExitApp()
}

CFDesktopMainResizePersist(*) {
    global CF
    if CF.loading || CF.shuttingDown
        return
    CFDesktopCaptureMainBounds()
    SaveSettings()
}

ResizeClickFlow(gui, state, width, height) {
    global controller, CF
    if state = -1 && CF.minimizeToTray {
        CFDesktopHide()
        return
    }
    if state != -1 {
        if IsSet(controller) && controller
            try controller.Fill()
        if !CF.loading && !CF.shuttingDown
            SetTimer(CFDesktopMainResizePersist, -350)
    }
}
