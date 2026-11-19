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

VERSION = "1.5.0"

RUNTIME_FILES = [
    "ClickFlow-WebView2.ahk",
    "ClickFlow-Backend.ahk",
    "ClickFlow-CpsTest.ahk",
    "ClickFlow-ProfileStore.ahk",
    "ClickFlow-Maintenance.ahk",
    "ClickFlow-Uninstall.ahk",
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

; ClickFlow v1.5.0 : un seul script a telecharger, AutoHotkey v2 x64 requis.
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
runtimeDir := appDir "\Runtime-1.5.0"
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
        FileAppend("1.5.0", readyFlag, "UTF-8")
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

; Les raccourcis Bureau / menu Démarrer sont gérés individuellement depuis
; l'onglet "À propos" du moteur AutoHotkey (ClickFlow-Backend.ahk).
; Ne pas les créer à chaque lancement : si l'utilisateur supprime l'un d'eux
; à la main, il doit rester absent. Les anciens réglages Enabled=1 ne
; déclenchent plus aucune restauration silencieuse.
Run('"' A_AhkPath '" "' launchFile '"')
ExitApp()

;--BEGIN-CLICKFLOW-PAYLOAD--
'''

FOOTER = ";--END-CLICKFLOW-PAYLOAD--\n"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path("stage"))
    parser.add_argument("--output", type=Path, default=Path("ClickFlow-v1.5.0.ahk"))
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
