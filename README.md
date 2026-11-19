# ClickFlow - AutoCliker

**Version stable 1.0.3 - AutoClicker pour Windows, sans application .exe à installer.**

ClickFlow est un auto-clicker Windows avec une interface graphique WebView2, un moteur AutoHotkey v2, plusieurs modes de CPS et des profils sauvegardés.

## Télécharger

Télécharger le fichier unique **[ClickFlow-v1.0.3.ahk](https://github.com/77Romain77/ClickFlow-AutoClicker/releases/tag/v1.0.3)** depuis les Releases GitHub.

**Prérequis :** Windows 10/11 64 bits, [AutoHotkey v2 64 bits](https://www.autohotkey.com/) et le runtime Microsoft WebView2 (présent sur la plupart des Windows récents).

1. Installer AutoHotkey v2 si nécessaire.
2. Télécharger `ClickFlow-v1.0.3.ahk`.
3. Double-cliquer sur ce fichier.
4. Dans **À propos**, ajouter les raccourcis Bureau et menu Démarrer si souhaité.

Au premier lancement, ClickFlow extrait ses composants locaux dans `%LOCALAPPDATA%\ClickFlow\Runtime-1.0.3`. Aucun compilateur ni `.exe` ClickFlow n'est nécessaire. Il n'y a **pas de téléchargement automatique de mises à jour**.

Le ZIP source accompagné de l'ensemble des composants est fourni comme alternative dans les Releases.

## Fonctionnalités

- De 1 à 100 CPS, en modes **Fixe**, **Aléatoire** et **Naturel**.
- Clic gauche, droit ou central, en complément des clics physiques.
- Déclenchement configurable par touche du clavier ou bouton de souris.
- Modes **Maintenir** et **Basculer**.
- Option **Conditionner à un bouton de souris** : déclencher les clics uniquement pendant le maintien physique d'un bouton.
- Arrêt au changement de fenêtre et arrêt d'urgence personnalisable, **F12 par défaut**.
- **Interface compacte ou étendue**, choix mémorisé.
- Profils locaux : création, duplication, renommage, suppression et sauvegarde.
- Statistiques de CPS et de clics générés.
- Icône dédiée et raccourcis Windows facultatifs. Le menu **À propos** permet de les gérer.
- Boutons pour ouvrir les dossiers du logiciel et des profils.
- Désinstallation depuis **À propos**, avec conservation des profils ou suppression complète des données ClickFlow.

## Lancer ClickFlow plusieurs fois et nettoyer les caches

Si ClickFlow est déjà ouvert, un nouveau lancement **ne ferme plus l'application en cours** : la fenêtre existante est remise au premier plan. Ceci évite le crash WebView2 observé lors d'un lancement multiple avec v1.0.0.

Après un démarrage réussi d'une nouvelle version, ClickFlow supprime automatiquement les anciens dossiers de programme de la forme `Runtime-X.Y.Z` créés par son lanceur. Il conserve le dossier courant, les paramètres, les profils, `ClickFlow.ahk`, `ClickFlow.ico`, `shortcuts.ini` et les dossiers de données WebView2. Si une ancienne version est encore ouverte, ferme-la avant de démarrer la nouvelle pour permettre le nettoyage.

## Raccourcis indépendants

Dans l'onglet **À propos**, tu peux désormais installer ou supprimer séparément :

- le raccourci du Bureau ;
- le raccourci du menu Démarrer.

L'interface lit directement la présence de chaque raccourci Windows. Elle actualise les états à chaque ouverture de cet onglet. Si tu supprimes manuellement un raccourci depuis l'Explorateur, il reste supprimé : ClickFlow ne restaure plus automatiquement les raccourcis lors d'un lancement ou d'une mise à jour. Il suffit de revenir dans **À propos** pour le réinstaller.

Les anciennes préférences `shortcuts.ini` (`Enabled=1`) n'imposent plus la création de deux raccourcis. Les raccourcis historiques sont reconnus et peuvent être gérés indépendamment, sans toucher aux autres raccourcis présents sur l'ordinateur.

## Profils et mises à jour

Les réglages se trouvent dans `%APPDATA%\ClickFlow\settings.ini`, séparément du programme. Une sauvegarde de sécurité `settings.ini.backup-webview2` est créée lors de la première utilisation WebView2 si nécessaire.

Chaque version publiée possède un numéro et son cache de composants. Télécharger et lancer un nouveau fichier `.ahk` met à jour la copie locale utilisée par les raccourcis, sans supprimer les profils.

## Emplacements et désinstallation

Dans l'onglet **À propos**, tu peux ouvrir directement les deux emplacements :

- **Profils et réglages** : `%APPDATA%\ClickFlow` (`settings.ini` et `settings.ini.backup-webview2`).
- **Fichiers du logiciel** : `%LOCALAPPDATA%\ClickFlow` (fichier unique local, icône, runtimes et cache WebView2).

Deux modes de désinstallation sont proposés, avec confirmation en tapant **SUPPRIMER** :

- **Désinstaller en gardant mes profils** : fermeture de ClickFlow, suppression des raccourcis qui lui appartiennent et du dossier local du programme, tout en préservant `%APPDATA%\ClickFlow`.
- **Tout supprimer, y compris mes profils** : mêmes opérations, puis suppression de `%APPDATA%\ClickFlow` et de ses sauvegardes.

Le nettoyage se fait après la fermeture du moteur, pour permettre la libération de WebView2. Les raccourcis d'autres logiciels ne sont jamais supprimés. AutoHotkey v2 et le runtime Microsoft WebView2 sont des prérequis partagés, ils ne sont pas désinstallés.

Un fichier `ClickFlow-vX.Y.Z.ahk` téléchargé dans **Téléchargements** ou dans un dossier externe reste présent après l'opération. Il doit être supprimé manuellement si nécessaire.
## Code source

| Chemin | Rôle |
| --- | --- |
| `src/ClickFlow-WebView2.ahk` | Lanceur de fenêtre Windows |
| `src/ClickFlow-Backend.ahk` | Moteur CPS, raccourcis, profils, sauvegarde et outils de maintenance |
| `src/ClickFlow-Uninstall.ahk` | Désinstallation après fermeture, avec ou sans sauvegardes |
| `src/lib/` | Dépendances WebView2/AutoHotkey et licence de thqby |
| `ui/index.html` | Interface HTML/CSS/JavaScript |
| `tools/build_single_ahk.py` | Création du fichier `.ahk` unique |
| `tools/make_icon.py` | Génération de l'icône Windows |
| `tests/` | Vérifications automatiques AutoHotkey |
| `.github/workflows/windows.yml` | Build, validation et publication Windows |

Pour reconstruire le fichier unique, consulter [CONTRIBUTING.md](CONTRIBUTING.md).

## Versions historiques

L'ancienne tentative en C#/WPF produisant un `.exe` a été déplacée dans la branche **[archive/dotnet-wpf](https://github.com/77Romain77/ClickFlow-AutoClicker/tree/archive/dotnet-wpf)**. Elle ne fait plus partie de `main` et ne sera plus compilée par le workflow officiel.

Les anciennes releases (notamment v0.1.0 et les prototypes v0.3.x) sont conservées pour l'historique. Voir [docs/ARCHIVES.md](docs/ARCHIVES.md).

## Sécurité et limites

ClickFlow ne contourne pas les anti-triches et ne garantit pas la compatibilité avec tous les jeux ou applications. Respecter leurs règles. Les clics simulés peuvent être ignorés par certains programmes et la fréquence réelle dépend des minuteries Windows. **Ne pas désactiver Smart App Control** pour installer ClickFlow.

Licence MIT : [LICENSE](LICENSE). La bibliothèque WebView2 de thqby possède sa licence propre dans `src/lib/LICENSE-thqby`.
