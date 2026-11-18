# ClickFlow - AutoClicker

Un autoclicker Windows léger, avec une interface sombre, plusieurs modes CPS, des raccourcis configurables et des profils sauvegardés.

> **Statut :** prototype 0.1.0. Aucune promesse d'indétectabilité ni de compatibilité avec les systèmes anti-triche. Respectez les règles des jeux et des applications utilisés.

## Fonctionnalités

- Fréquence de 1 à 100 CPS, réglable par sliders et par saisie numérique.
- Modes **Fixed**, **Random** et **Natural** (variations progressives, trois intensités).
- Bouton généré : gauche, droit ou central. Les clics physiques continuent de fonctionner en parallèle.
- Capture d'une touche clavier ou d'un bouton souris (gauche, droit, central, Mouse 4 ou Mouse 5).
- Activation **Hold** (maintien) ou **Toggle** (bascule), avec condition facultative de maintien d'un bouton de souris.
- Arrêt au changement de fenêtre (activé par défaut). Aucune reprise automatique après ce changement.
- Arrêt d'urgence global, F12 par défaut. Les raccourcis ne sont pas interceptés, ils conservent leur action normale dans Windows et les applications.
- Profils locaux : créer, renommer, dupliquer et supprimer.
- Statistiques : CPS sur la dernière seconde, total de clics générés.
- Icône dans la zone de notification Windows, raccourcis actifs même lorsque la fenêtre est masquée.
- Installateur avec mises à jour Velopack depuis les GitHub Releases, et archive portable autonome.

## Installer / essayer

Les versions publiées sont disponibles dans [Releases](https://github.com/77Romain77/ClickFlow-AutoClicker/releases).

- **Setup** : installation par utilisateur, sans compte ni service. Les réglages sont stockés dans `%LOCALAPPDATA%\\ClickFlow\\settings.json`. Recherche et téléchargement automatiques des mises à jour au démarrage si l'option est activée ; application au lancement suivant.
- **Portable** : extraire le ZIP dans un dossier inscriptible puis ouvrir `ClickFlow.exe`. Les réglages sont dans le même dossier que le programme. La mise à jour automatique de l'archive portable n'est pas prise en charge.

La première version n'est pas encore signée numériquement ; Windows SmartScreen peut afficher un avertissement. Les applications exécutées avec élévation de privilèges peuvent ignorer les clics provenant d'un processus non élevé.

## Compiler

Sur **Windows 10 ou 11**, avec le **SDK .NET 10** :

```powershell
dotnet restore ClickFlow/ClickFlow.csproj
dotnet run --project ClickFlow/ClickFlow.csproj
```

Pour produire un dossier autonome Windows x64 :

```powershell
dotnet publish ClickFlow/ClickFlow.csproj -c Release -r win-x64 --self-contained true -o publish
```

Un workflow GitHub Actions compile le projet sur Windows et fournit un artefact portable de test à chaque push sur `main`.

## Publier une version

La publication est automatisée à chaque tag `vMAJOR.MINOR.PATCH` (par exemple `v0.1.0`) :

1. Compiler l'application autonome pour Windows x64.
2. Fabriquer le ZIP portable.
3. Créer l'installateur Velopack et le flux de mise à jour `releases.win.json`.
4. Publier le tout sur une GitHub Release.

La version du tag doit correspondre à la version de l'application ; GitHub Actions la fournit pendant la publication. Publier un tag seulement après validation du workflow de compilation.

## Architecture

- `ClickFlow/MainWindow.xaml` : interface WPF.
- `ClickFlow/MainWindow.xaml.cs` : interactions, profil actif et sécurité liée à la fenêtre cible.
- `ClickFlow/Services/PhysicalInputMonitor.cs` : raccourcis et détection des entrées physiques par hooks Windows, sans les bloquer.
- `ClickFlow/Services/ClickEngine.cs` : moteur CPS et génération des clics Win32.
- `ClickFlow/Services/SettingsStore.cs` : sauvegarde JSON locale.
- `ClickFlow/Services/UpdateService.cs` : Velopack et GitHub Releases.

## Limites connues

- Windows uniquement ; architecture win-x64 pour les releases actuelles.
- Les jeux utilisant des entrées brutes, certaines fenêtres protégées et les logiciels anti-triche peuvent bloquer les clics générés.
- L'intervalle entre les clics dépend de la précision de planification Windows ; le CPS mesuré peut différer légèrement de la valeur demandée.
- Aucune option de contournement d'un anti-triche, d'injection dans un processus cible ou de masquage du programme n'est incluse.

## Licence

MIT. Voir [LICENSE](LICENSE).
