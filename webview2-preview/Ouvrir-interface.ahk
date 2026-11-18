#Requires AutoHotkey v2.0
#SingleInstance Force

; Fallback pour tester l'interface sans bibliotheque WebView2.
; Ouvre seulement le fichier HTML local dans le navigateur par defaut.
; Aucun clic automatique et aucune modification des profils existants.

path := A_ScriptDir "\ui\index.html"
if !FileExist(path) {
    MsgBox("Fichier d'interface introuvable : " path, "ClickFlow", "Icon!")
    ExitApp(1)
}
Run(path)
ExitApp()
