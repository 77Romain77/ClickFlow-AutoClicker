#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include ..\src\ClickFlow-Backend.ahk

; Tests de migration et d'import indépendants de la session Windows de l'utilisateur.
global CF
parent := A_Temp "\ClickFlow-Profiles-Test-" A_TickCount
CF.configFile := parent "\settings.ini"
CF.profilesDir := parent "\profiles"
CF.emergencyKey := "F12"
CF.compactMode := false
CF.loading := true

try {
    DirCreate(parent)
    ; Deux profils au format ClickFlow v1.1.0.
    IniWrite("1,2", CF.configFile, "Profiles", "Ids")
    IniWrite("2", CF.configFile, "Profiles", "Selected")
    IniWrite("3", CF.configFile, "Profiles", "NextId")
    IniWrite("Principal", CF.configFile, "Profile_1", "Name")
    IniWrite("12", CF.configFile, "Profile_1", "min")
    IniWrite("18", CF.configFile, "Profile_1", "max")
    IniWrite("Gaming", CF.configFile, "Profile_2", "Name")
    IniWrite("22", CF.configFile, "Profile_2", "min")
    IniWrite("27", CF.configFile, "Profile_2", "max")
    IniWrite("F7", CF.configFile, "Profile_2", "activation")

    LoadSettings()
    if CF.profiles.Length != 2 || CF.selectedId != 2 || CF.cfg.min != 22
        throw Error("Les profils v1.1 n'ont pas été chargés.")
    CF.loading := false
    SaveSettings()
    one := CFProfileFile(1)
    two := CFProfileFile(2)
    if !FileExist(one) || !FileExist(two)
        throw Error("La migration n'a pas généré un fichier par profil.")
    if IniRead(two, "ClickFlowProfile", "FormatVersion", "") != "1"
        throw Error("Le format du fichier individuel est invalide.")
    if IniRead(CF.configFile, "Profile_2", "Name", "") != "Gaming"
        throw Error("La migration a effacé le format historique.")

    ; Les fichiers sont bien rechargés de façon indépendante.
    IniWrite("31", two, "Settings", "min")
    LoadSettings()
    if CF.selectedId != 2 || CF.cfg.min != 31 || CF.profiles.Length != 2
        throw Error("Le rechargement des fichiers individuels a échoué.")

    CF.profiles[1].name := "Principal modifié"
    SaveSettings()
    if IniRead(one, "ClickFlowProfile", "Name", "") != "Principal modifié"
        throw Error("La modification individuelle n'a pas été conservée.")
    if IniRead(two, "ClickFlowProfile", "Name", "") != "Gaming"
        throw Error("Modifier un profil a altéré le second.")

    ; Copier le profil Gaming pour simuler un fichier exporté puis importé.
    externalFile := parent "\gaming-export.ini"
    FileCopy(two, externalFile)
    imported := CFImportProfileFromFile(externalFile)
    if imported.id != 3 || imported.name != "Gaming (2)"
        throw Error("L'import ne respecte pas les identifiants et noms existants.")
    CF.selectedId := imported.id
    CF.cfg := imported.cfg
    SaveSettings()
    if !FileExist(CFProfileFile(3))
        throw Error("Le profil importé n'a pas été sauvegardé.")

    ; Retirer un seul fichier ne doit pas modifier les autres profils.
    FileDelete(one)
    LoadSettings()
    if CF.profiles.Length != 2 || !CFProfileById(2) || !CFProfileById(3)
        throw Error("La suppression individuelle a touché d'autres profils.")

    invalid := parent "\invalid.ini"
    FileAppend("[Other]" Chr(10) "Name=Unknown", invalid, "UTF-8")
    rejected := false
    try CFImportProfileFromFile(invalid)
    catch
        rejected := true
    if !rejected
        throw Error("Un fichier non ClickFlow a été accepté.")

    ; Une fois migré, un ancien contenu du fichier global ne réapparaît pas
    ; quand les profils individuels ont été explicitement retirés.
    FileDelete(CFProfileFile(2))
    FileDelete(CFProfileFile(3))
    LoadSettings()
    if CF.profiles.Length != 1 || CF.profiles[1].name != "Principal"
        throw Error("Des anciens profils ont ressurgi après migration.")

    try DirDelete(parent, true)
    FileAppend("Profile migration, independent storage and import passed.", "*", "UTF-8")
    ExitApp(0)
} catch as err {
    FileAppend("PROFILE REGRESSION FAILED: " err.Message, "*", "UTF-8")
    try DirDelete(parent, true)
    ExitApp(1)
}
