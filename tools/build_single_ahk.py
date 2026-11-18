#!/usr/bin/env python3
"""Create one ClickFlow .ahk that bundles the WebView2 runtime assets offline.

AutoHotkey v2 x64 and the Windows WebView2 runtime remain prerequisites.
The first launch extracts components under LOCALAPPDATA, then starts ClickFlow.
"""
from __future__ import annotations

import argparse
import base64
import io
from pathlib import Path
import textwrap
import zipfile

VERSION = "1.0.0"

RUNTIME_FILES = [
    "ClickFlow-WebView2.ahk",
    "ClickFlow-Backend.ahk",
    "ui/index.html",
    "lib/ComVar.ahk",
    "lib/Promise.ahk",
    "lib/WebView2/WebView2.ahk",
    "lib/WebView2/64bit/WebView2Loader.dll",
    "lib/LICENSE-thqby",
    "assets/ClickFlow.ico",
]

BOOTSTRAP = r'''#Requires AutoHotkey v2.0
#SingleInstance Force
#ErrorStdOut "UTF-8"

; ClickFlow v1.0.0 : un seul script a telecharger, AutoHotkey v2 x64 requis.
; Les composants sont extraits en local, sans EXE ClickFlow et sans telechargement.

if A_PtrSize != 8 {
    MsgBox("ClickFlow nécessite AutoHotkey v2 en 64 bits.", "ClickFlow", "Icon!")
    ExitApp(1)
}
localAppData := EnvGet("LOCALAPPDATA")
if localAppData = "" {
    MsgBox("Impossible de trouver LOCALAPPDATA.", "ClickFlow", "Icon!")
    ExitApp(1)
}
appDir := localAppData "\ClickFlow"
runtimeDir := appDir "\Runtime-1.0.0"
launchFile := runtimeDir "\ClickFlow-WebView2.ahk"
readyFlag := runtimeDir "\.extracted-ok"
stableScript := appDir "\ClickFlow.ahk"
stableIcon := appDir "\ClickFlow.ico"
shortcutsIni := appDir "\shortcuts.ini"

if !FileExist(readyFlag) || !FileExist(launchFile) || !FileExist(runtimeDir "\assets\ClickFlow.ico") {
    try {
        DirCreate(runtimeDir)
        thisScript := FileRead(A_ScriptFullPath, "UTF-8")
        startMarker := ";" "--BEGIN-CLICKFLOW-PAYLOAD--"
        endMarker := ";" "--END-CLICKFLOW-PAYLOAD--"
        first := InStr(thisScript, startMarker)
        last := InStr(thisScript, endMarker)
        if first = 0 || last <= first
            throw Error("Archive ClickFlow manquante ou incomplète.")
        encoded := RegExReplace(SubStr(thisScript, first + StrLen(startMarker),
            last - first - StrLen(startMarker)), "[;\s]", "")
        size := 0
        if !DllCall("Crypt32\CryptStringToBinaryW", "WStr", encoded,
            "UInt", StrLen(encoded), "UInt", 1, "Ptr", 0, "UInt*", &size,
            "Ptr", 0, "Ptr", 0, "Int")
            throw Error("Décodage de l'archive impossible.")
        decoded := Buffer(size)
        if !DllCall("Crypt32\CryptStringToBinaryW", "WStr", encoded,
            "UInt", StrLen(encoded), "UInt", 1, "Ptr", decoded.Ptr,
            "UInt*", &size, "Ptr", 0, "Ptr", 0, "Int")
            throw Error("L'archive intégrée est incorrecte.")
        zipFile := runtimeDir "\clickflow-runtime.zip"
        try FileDelete(readyFlag)
        output := FileOpen(zipFile, "w")
        if !output
            throw Error("Impossible de créer l'archive temporaire.")
        output.RawWrite(decoded)
        output.Close()
        tarExe := A_WinDir "\System32\tar.exe"
        if !FileExist(tarExe)
            throw Error("L'utilitaire tar.exe de Windows est introuvable.")
        exitCode := RunWait('"' tarExe '" -xf "' zipFile '" -C "' runtimeDir '"', , "Hide")
        if exitCode != 0 || !FileExist(launchFile)
            throw Error("Extraction impossible (code " exitCode ").")
        FileDelete(zipFile)
        FileAppend("1.0.0", readyFlag, "UTF-8")
    } catch as err {
        MsgBox("Impossible de préparer ClickFlow : " err.Message, "ClickFlow", "Icon!")
        ExitApp(1)
    }
}

; Une copie stable permet aux raccourcis Windows de survivre aux nouvelles
; versions du fichier unique, même si le fichier téléchargé est supprimé.
try {
    DirCreate(appDir)
    if StrLower(A_ScriptFullPath) != StrLower(stableScript)
        FileCopy(A_ScriptFullPath, stableScript, true)
    FileCopy(runtimeDir "\assets\ClickFlow.ico", stableIcon, true)
} catch as err {
    ; ClickFlow reste utilisable, même si une politique Windows interdit
    ; de créer un raccourci ou la copie d'installation.
    if EnvGet("CLICKFLOW_WEBVIEW_SMOKE_FILE") = ""
        MsgBox("ClickFlow fonctionne, mais sa copie locale n'a pas pu être créée : "
            err.Message, "ClickFlow", "Icon!")
}

; Les chemins des raccourcis sont toujours ceux de l'utilisateur courant.
; Les variables de test permettent aux tests GitHub Actions d'éviter de
; modifier le vrai bureau et le vrai menu Démarrer du runner.
desktopDir := EnvGet("CLICKFLOW_SHORTCUT_TEST_DESKTOP")
startDir := EnvGet("CLICKFLOW_SHORTCUT_TEST_STARTMENU")
if desktopDir = ""
    desktopDir := A_Desktop
if startDir = ""
    startDir := A_Programs

if A_Args.Length && A_Args[1] = "--shortcuts" {
    try {
        InstallClickFlowShortcuts()
        if EnvGet("CLICKFLOW_WEBVIEW_SMOKE_FILE") = ""
            MsgBox("Raccourcis ClickFlow - AutoCliker créés sur le Bureau et dans le menu Démarrer.",
                "ClickFlow", "Iconi")
    } catch as err {
        probeFile := EnvGet("CLICKFLOW_WEBVIEW_SMOKE_FILE")
        if probeFile != ""
            FileAppend(err.Message, probeFile ".shortcut-error", "UTF-8")
        else
            MsgBox("Impossible de créer les raccourcis : " err.Message, "ClickFlow", "Icon!")
        ExitApp(1)
    }
    ExitApp()
}
if A_Args.Length && A_Args[1] = "--remove-shortcuts" {
    try {
        RemoveClickFlowShortcuts()
        if EnvGet("CLICKFLOW_WEBVIEW_SMOKE_FILE") = ""
            MsgBox("Raccourcis ClickFlow - AutoCliker supprimés.", "ClickFlow", "Iconi")
    } catch as err {
        probeFile := EnvGet("CLICKFLOW_WEBVIEW_SMOKE_FILE")
        if probeFile != ""
            FileAppend(err.Message, probeFile ".shortcut-error", "UTF-8")
        else
            MsgBox("Erreur : " err.Message, "ClickFlow", "Icon!")
        ExitApp(1)
    }
    ExitApp()
}

; Premier lancement : demander une seule fois si l'utilisateur souhaite
; les raccourcis. Aucun raccourci n'est imposé sans son accord.
savedChoice := IniRead(shortcutsIni, "Shortcuts", "Enabled", "")
testAction := EnvGet("CLICKFLOW_SHORTCUTS_TEST_ACTION")
if testAction = "create" {
    InstallClickFlowShortcuts()
} else if testAction = "remove" {
    try RemoveClickFlowShortcuts()
} else if savedChoice = "" && EnvGet("CLICKFLOW_WEBVIEW_SMOKE_FILE") = "" {
    answer := MsgBox("Créer un raccourci ClickFlow - AutoCliker sur le Bureau et dans le menu Démarrer ?"
        Chr(10) "Ils ouvriront toujours ta copie locale de ClickFlow.",
        "ClickFlow - AutoCliker", "YesNo Icon?")
    IniWrite(answer = "Yes" ? "1" : "0", shortcutsIni, "Shortcuts", "Enabled")
    if answer = "Yes" {
        try InstallClickFlowShortcuts()
        catch as err
            MsgBox("Impossible de créer les raccourcis : " err.Message, "ClickFlow", "Icon!")
    }
} else if savedChoice = "1" {
    ; Restaurer les raccourcis si une version précédente a été remplacée.
    try InstallClickFlowShortcuts()
}

Run('"' A_AhkPath '" "' launchFile '"')
ExitApp()

InstallClickFlowShortcuts() {
    global stableScript, stableIcon, appDir, desktopDir, startDir, shortcutsIni
    if !FileExist(stableScript) || !FileExist(stableIcon)
        throw Error("La copie locale de ClickFlow ou son icône est absente.")
    DirCreate(desktopDir)
    DirCreate(startDir)
    args := '"' stableScript '"'
    ; Migration des anciens raccourcis "ClickFlow" publiés avant v1.0.0.
    ; On ne touche qu'aux raccourcis qui ciblent notre script local.
    RemoveLegacyClickFlowShortcut(desktopDir)
    RemoveLegacyClickFlowShortcut(startDir)
    FileCreateShortcut(A_AhkPath, desktopDir "\ClickFlow - AutoCliker.lnk", appDir,
        args, "ClickFlow - AutoCliker", stableIcon)
    FileCreateShortcut(A_AhkPath, startDir "\ClickFlow - AutoCliker.lnk", appDir,
        args, "ClickFlow - AutoCliker", stableIcon)
    IniWrite("1", shortcutsIni, "Shortcuts", "Enabled")
}

RemoveLegacyClickFlowShortcut(dir) {
    global stableScript
    file := dir "\ClickFlow.lnk"
    if !FileExist(file)
        return
    try {
        link := ComObject("WScript.Shell").CreateShortcut(file)
        if InStr(StrLower(link.Arguments), StrLower(stableScript))
            FileDelete(file)
    }
}

RemoveClickFlowShortcuts() {
    global desktopDir, startDir
    for dir in [desktopDir, startDir] {
        newFile := dir "\ClickFlow - AutoCliker.lnk"
        if FileExist(newFile)
            FileDelete(newFile)
        RemoveLegacyClickFlowShortcut(dir)
    }
}

;--BEGIN-CLICKFLOW-PAYLOAD--
'''

FOOTER = ";--END-CLICKFLOW-PAYLOAD--\n"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path("stage"))
    parser.add_argument("--output", type=Path, default=Path("ClickFlow-v1.0.0.ahk"))
    args = parser.parse_args()
    root: Path = args.root
    for rel in RUNTIME_FILES:
        if not (root / rel).is_file():
            raise SystemExit(f"Missing runtime asset: {root / rel}")
    data = io.BytesIO()
    with zipfile.ZipFile(data, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for rel in RUNTIME_FILES:
            archive.write(root / rel, arcname=rel)
    payload = base64.b64encode(data.getvalue()).decode("ascii")
    chunks = (";" + chunk + "\n" for chunk in textwrap.wrap(payload, 112))
    args.output.write_text(BOOTSTRAP + "".join(chunks) + FOOTER, encoding="utf-8")
    print(f"Created {args.output} ({args.output.stat().st_size} bytes), "
          f"with {len(RUNTIME_FILES)} embedded files, ZIP {len(data.getvalue())} bytes.")


if __name__ == "__main__":
    main()
