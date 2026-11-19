#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include ..\src\ClickFlow-Backend.ahk

; Test CPS - vérifie les records sans lancer le moteur ni envoyer de clics.
global CF
base := A_Temp "\clickflow-cps-records-" A_TickCount
CF.cpsRecordsFile := base "\cps-records.ini"
CF.web := 0
try {
    if CFGetBestCpsClicks(5) != 0
        throw Error("Le record initial doit être zéro.")
    if CFSaveCpsResult(5, 17) != 17
        throw Error("Le premier record n'a pas été enregistré.")
    if CFSaveCpsResult(5, 8) != 17
        throw Error("Un résultat plus faible a écrasé le record.")
    if CFSaveCpsResult(5, 24) != 24
        throw Error("Le nouveau record n'a pas été enregistré.")
    if CFSaveCpsResult(2, 9) != 9
        throw Error("Le record pour 2 secondes n'a pas été enregistré.")
    if CFGetBestCpsClicks(5) != 24 || CFGetBestCpsClicks(2) != 9
        throw Error("Les records des différentes durées ne sont pas indépendants.")
    for duration in ["0","3","9","90","600"] {
        rejected := false
        try CFSaveCpsResult(duration, 5)
        catch
            rejected := true
        if !rejected
            throw Error("Durée CPS non autorisée : " duration)
    }
    rejected := false
    try CFSaveCpsResult(5, "-1")
    catch
        rejected := true
    if !rejected
        throw Error("Un nombre de clics négatif a été accepté.")
    if IniRead(CF.cpsRecordsFile,"Records","Best5",0) != "24"
        throw Error("Le fichier des records contient une mauvaise valeur.")
    DirDelete(base, true)
    FileAppend("CPS record persistence and duration validation passed.", "*", "UTF-8")
    ExitApp(0)
} catch as err {
    try DirDelete(base, true)
    FileAppend("CPS RECORDS TEST FAILURE: " err.Message, "*", "UTF-8")
    ExitApp(1)
}
