# Contribuer à ClickFlow

## Environnement

- Windows 10/11 avec AutoHotkey v2 x64
- Python 3 (uniquement pour générer le fichier unique et l'icône)
- Runtime Microsoft WebView2

Le code ne requiert aucun SDK .NET et ne génère aucun exécutable ClickFlow.

## Générer la release localement

Le workflow `.github/workflows/windows.yml` montre exactement les étapes. Il télécharge le chargeur Microsoft WebView2Loader x64 dans `src/lib/WebView2/64bit/`, puis :

```powershell
python tools/make_icon.py --output src/assets/ClickFlow.ico
New-Item -ItemType Directory -Force stage/ui | Out-Null
Copy-Item src/* stage/ -Recurse -Force
Copy-Item ui/index.html stage/ui/index.html
python tools/build_single_ahk.py --root stage --output ClickFlow-v1.7.0.ahk
```

La sortie unique intègre les fichiers du dossier `stage` et les extrait localement à la première exécution.

## Vérifications

Les tests Windows du workflow assurent :

- Validation des hooks physiques de souris.
- Vérification AutoHotkey de la sauvegarde de la touche d'urgence et du mode compact.
- Démarrage réel de WebView2 et communication JS/AutoHotkey.
- Fermeture propre par le bouton Windows de fermeture (WM_CLOSE).
- Construction et démarrage du fichier unique.
- Création, migration et suppression des raccourcis avec l'icône ClickFlow.

Un essai manuel sur Windows reste nécessaire avant toute version stable, notamment pour les clics physiques.

## Versionnement

Utiliser `MAJOR.MINOR.PATCH`. **Chaque modification publiée** doit changer de version dans les sources concernées : `VERSION`, lanceur, interface, script de build et workflow.

Pour publier une nouvelle release stable, fusionner un commit sur `main` dont le titre est exactement `release: vMAJOR.MINOR.PATCH`, après validation des tests. Le workflow génère les archives et publie la release GitHub. Aucun auto-update n'est prévu pour le moment.
