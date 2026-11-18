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

VERSION = "0.3.5"

RUNTIME_FILES = [
    "ClickFlow-WebView2.ahk",
    "ClickFlow-Backend.ahk",
    "ui/index.html",
    "lib/ComVar.ahk",
    "lib/Promise.ahk",
    "lib/WebView2/WebView2.ahk",
    "lib/WebView2/64bit/WebView2Loader.dll",
    "lib/LICENSE-thqby",
]

BOOTSTRAP = r'''#Requires AutoHotkey v2.0
#SingleInstance Force
#ErrorStdOut "UTF-8"

; ClickFlow v0.3.5 - fichier unique Windows (AutoHotkey v2 64 bits requis).
; Tous les composants sont integrés et extraits localement au premier lancement.
; Cette extraction ne modifie pas les profils deja enregistrés.

if A_PtrSize != 8 {
    MsgBox("ClickFlow demande AutoHotkey v2 en 64 bits.", "ClickFlow", "Icon!")
    ExitApp(1)
}
localAppData := EnvGet("LOCALAPPDATA")
if localAppData = "" {
    MsgBox("Impossible de trouver le dossier LOCALAPPDATA.", "ClickFlow", "Icon!")
    ExitApp(1)
}
runtimeDir := localAppData "\ClickFlow\Runtime-0.3.5"
launchFile := runtimeDir "\ClickFlow-WebView2.ahk"
readyFlag := runtimeDir "\.extracted-ok"
if !FileExist(readyFlag) || !FileExist(launchFile) {
    try {
        DirCreate(runtimeDir)
        thisScript := FileRead(A_ScriptFullPath, "UTF-8")
        startMarker := ";--BEGIN-CLICKFLOW-PAYLOAD--"
        endMarker := ";--END-CLICKFLOW-PAYLOAD--"
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
            throw Error("L'extraction des composants a échoué (code " exitCode ").")
        FileDelete(zipFile)
        FileAppend("0.3.5", readyFlag, "UTF-8")
    } catch as err {
        MsgBox("Impossible de préparer ClickFlow : " err.Message
            Chr(10) Chr(10) "Le moteur reste disponible dans la version en ZIP.",
            "ClickFlow", "Icon!")
        ExitApp(1)
    }
}
; Le navigateur externe n'est jamais ouvert.
Run('"' A_AhkPath '" "' launchFile '"')
ExitApp()

;--BEGIN-CLICKFLOW-PAYLOAD--
'''

FOOTER = ";--END-CLICKFLOW-PAYLOAD--\n"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path("webview2-preview"))
    parser.add_argument("--output", type=Path, default=Path("ClickFlow-v0.3.5.ahk"))
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
