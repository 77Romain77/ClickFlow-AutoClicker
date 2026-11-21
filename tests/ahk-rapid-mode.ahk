#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Include ..\src\ClickFlow-Backend.ahk

; Tests sans injection Windows : rafales courtes et calibration RPM.
global CF
CF.web := 0
CF.loading := true
CF.shuttingDown := false
CF.armed := false
CF.test := {active: false}
CF.total := 0

tempDir := A_Temp "\ClickFlow-Rapid-Tests-" A_TickCount
try {
    cfg := DefaultConfig()
    cfg.mode := 4
    cfg.rapidPreset := 4
    cfg.rapidTarget := 10.0
    cfg.rapidBetween := 10.0
    cfg.rapidWithin := 5.0
    cfg.rapidRpm := 600
    seen := Map()
    CFNaturalReset(cfg)
    Loop 120 {
        CFRapidBurstReset(cfg)
        burst := CF.rapidBurstCps
        if burst < 9.0 || burst > 11.0
            throw Error("La cadence de rafale sort de la plage ±10%.")
        seen[Round(burst, 2)] := true
        if GetNextCps(cfg, 10000) != burst
            throw Error("La cadence de la rafale change avant le prochain appui.")
        Loop 30 {
            ms := GetNextIntervalMs(cfg, 10000 + A_Index * 100)
            fastest := 1000 / (burst * 1.05)
            slowest := 1000 / (burst * 0.95)
            if ms < fastest - 1 || ms > slowest + 1
                throw Error("Micro-variation de clic supérieure à ±5%.")
        }
    }
    if seen.Count < 12
        throw Error("Les différentes rafales ne varient pas suffisamment.")

    ; Zéro variation : cadence strictement déterministe à 12.5 CPS.
    cfg.rapidTarget := 12.5
    cfg.rapidRpm := 750
    cfg.rapidBetween := 0
    cfg.rapidWithin := 0
    CFNaturalReset(cfg)
    if Abs(CF.rapidBurstCps - 12.5) > 0.0001
        throw Error("Une rafale sans variation doit utiliser la cible exacte.")
    Loop 100 {
        if GetNextIntervalMs(cfg, A_Index * 80) != 80
            throw Error("12.5 CPS doivent donner un intervalle de 80 ms.")
    }

    for preset in [{id:1,b:2,w:1}, {id:2,b:4,w:2}, {id:3,b:6,w:3}] {
        cfg.rapidPreset := preset.id
        v := CFRapidVariations(cfg)
        if v.between != preset.b || v.within != preset.w
            throw Error("Pourcentages prédéfinis incorrects : " preset.id)
    }

    ; Les champs de RPM, de cible décimale et de variations sont conservés
    ; par les copies, l'export INI et le rechargement des profils.
    cfg.rapidPreset := 4
    cfg.rapidBetween := 10
    cfg.rapidWithin := 5
    cfg.rapidTarget := 12.5
    cfg.rapidRpm := 750
    copy := CopyConfig(cfg)
    if copy.rapidTarget != 12.5 || copy.rapidRpm != 750
        throw Error("Le clonage de profil perd les RPM.")
    CF.configFile := tempDir "\settings.ini"
    CF.profilesDir := tempDir "\profiles"
    CF.emergencyKey := "F12"
    DirCreate(tempDir)
    CFWriteProfile({id:1,name:"Arme 750 RPM",cfg:cfg})
    reloaded := ReadConfig(CFProfileFile(1), "Settings", DefaultConfig())
    if reloaded.mode != 4 || reloaded.rapidTarget != 12.5
        || reloaded.rapidRpm != 750 || reloaded.rapidBetween != 10
        || reloaded.rapidWithin != 5 || reloaded.rapidPreset != 4
        throw Error("La sauvegarde INI du mode rapide est incorrecte.")
    legacy := DefaultConfig()
    if legacy.mode != 1 || legacy.min != 8 || legacy.max != 14
        throw Error("Le mode par défaut historique est modifié.")

    ; Le banc de test doit réutiliser cette cadence sans SendInput.
    cfg.rapidBetween := 0
    cfg.rapidWithin := 0
    CF.profiles := [{id: 1, name: "RPM 750", cfg: CopyConfig(cfg)}]
    CF.selectedId := 1
    CFTestStart(2, 991, 1)
    CFEngineSetTimer(false)
    CFStatsSetTimer(false)
    started := CF.test.started
    Loop 201
        CFTestTick(started + (A_Index - 1) * 10)
    if CF.test.active
        throw Error("Le test de profil rapide n'est pas terminé.")
    if CF.test.clicks.Length < 22 || CF.test.clicks.Length > 27
        throw Error("12.5 CPS sur 2 secondes : déclenchements inattendus.")
    if CF.total != 0
        throw Error("Le banc de test a envoyé des clics Windows.")

    try DirDelete(tempDir, true)
    FileAppend("Rapid naturel 10/50 CPS-style bursts, RPM targets, presets, INI and CPS tester passed.", "*", "UTF-8")
    ExitApp(0)
} catch as err {
    try DirDelete(tempDir, true)
    FileAppend("RAPID MODE TEST FAILED: " err.Message, "*", "UTF-8")
    ExitApp(1)
}
