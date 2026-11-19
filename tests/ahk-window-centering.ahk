#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include ..\src\ClickFlow-Backend.ahk

; Le démarrage doit rester entièrement visible même en configuration
; 1800x1200 sur un petit écran Windows CI ou après retrait d'un moniteur.
try {
    g := Gui("+Resize +MinSize460x480", "ClickFlow-center-test")
    g.Show("w700 h520")
    rect := CFDesktopCenterMain(g.Hwnd, 1800, 1200)
    WinGetPos(&x, &y, &w, &h, "ahk_id " g.Hwnd)
    CFDesktopMonitorArea(rect.monitor, &left, &top, &right, &bottom)
    if x < left - 2 || y < top - 2
        || x + w > right + 2 || y + h > bottom + 2
        throw Error("La fenêtre est hors de l'écran " x "," y " " w "x" h)
    if Abs(x - (left + Floor((right - left - w) / 2))) > 4
        throw Error("La fenêtre n'est pas centrée horizontalement.")
    if Abs(y - (top + Floor((bottom - top - h) / 2))) > 4
        throw Error("La fenêtre n'est pas centrée verticalement.")
    ; Une fenêtre de taille normale doit aussi être centrée et visible.
    CFDesktopCenterMain(g.Hwnd, 670, 530)
    WinGetPos(&x, &y, &w, &h, "ahk_id " g.Hwnd)
    if x < left - 2 || y < top - 2
        || x + w > right + 2 || y + h > bottom + 2
        throw Error("Le recentrage d'une fenêtre normale a échoué.")
    g.Destroy()
    FileAppend("Main window always centers within a visible monitor work area passed.", "*", "UTF-8")
    ExitApp(0)
} catch as err {
    FileAppend("CENTERING TEST FAILED: " err.Message " " err.File ":" err.Line, "*", "UTF-8")
    ExitApp(1)
}
