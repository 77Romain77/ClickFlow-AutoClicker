# ClickFlow - AutoCliker

**Version stable 1.5.0 - AutoClicker pour Windows, sans application .exe à installer.**

ClickFlow est un auto-clicker Windows avec une interface graphique WebView2, un moteur AutoHotkey v2, plusieurs modes de CPS et des profils sauvegardés.

## Télécharger

Télécharger le fichier unique **[ClickFlow-v1.5.0.ahk](https://github.com/77Romain77/ClickFlow-AutoClicker/releases/tag/v1.5.0)** depuis les Releases GitHub.

**Prérequis :** Windows 10/11 64 bits, [AutoHotkey v2 64 bits](https://www.autohotkey.com/) et le runtime Microsoft WebView2 (présent sur la plupart des Windows récents).

1. Installer AutoHotkey v2 si nécessaire.
2. Télécharger `ClickFlow-v1.5.0.ahk`.
3. Double-cliquer sur ce fichier.
4. Dans l'onglet **À propos**, créer séparément les raccourcis Bureau et menu Démarrer si nécessaire.

Au premier lancement, ClickFlow extrait ses composants locaux dans `%LOCALAPPDATA%\ClickFlow\Runtime-1.5.0`. Aucun compilateur ni `.exe` ClickFlow n'est nécessaire. Il n'y a **pas de téléchargement automatique de mises à jour**.

Le ZIP source accompagné de l'ensemble des composants est fourni comme alternative dans les Releases.

## Fonctionnalités

- De 1 à 100 CPS, en modes **Fixe**, **Aléatoire** et **Naturel**.
- Mode **Naturel v1.5** : trois intensités Faible / Moyen / Élevé nettement différenciées, évolution progressive de la cadence, irrégularités entre clics, accélérations brèves et hésitations occasionnelles.
- Clic gauche, droit ou central, en complément des clics physiques.
- Déclenchement configurable par touche du clavier ou bouton de souris.
- Modes **Maintenir** et **Basculer**.
- Option **Conditionner à un bouton de souris** : déclencher les clics uniquement pendant le maintien physique d'un bouton.
- Arrêt au changement de fenêtre et arrêt d'urgence personnalisable, **F12 par défaut**.
- **Interface compacte ou étendue**, choix mémorisé.
- Profils locaux : création, duplication, renommage et suppression. Chaque profil est enregistré dans un fichier indépendant.
- Importer ou exporter un profil individuellement au format `.ini` (menu **Profils** ou profil actif).
- Statistiques de CPS et de clics générés.
- **Onglet Test CPS** : teste directement la cadence du profil ClickFlow sélectionné ou tes clics manuels, sur 2, 5, 10, 30 ou 60 secondes.
- CPS glissants sur une seconde, CPS moyens, pic, total, progression et courbe en temps réel.
- Animation lumineuse et léger effet sonore sur les clics du test, avec bouton pour désactiver le son.
- Seul le **dernier résultat terminé** est affiché pendant la session. Aucun score ni historique n'est sauvegardé sur le disque.
- Icône dédiée et raccourcis Windows facultatifs. Le menu **À propos** permet de les gérer.

## Lancer ClickFlow plusieurs fois et nettoyer les caches

Si ClickFlow est déjà ouvert, un nouveau lancement **ne ferme plus l'application en cours** : la fenêtre existante est remise au premier plan. Ceci évite le crash WebView2 observé lors d'un lancement multiple avec v1.0.0.

Après un démarrage réussi d'une nouvelle version, ClickFlow supprime automatiquement les anciens dossiers de programme de la forme `Runtime-X.Y.Z` créés par son lanceur. Il conserve le dossier courant, les paramètres, les profils, `ClickFlow.ahk`, `ClickFlow.ico`, `shortcuts.ini` et les dossiers de données WebView2. Si une ancienne version est encore ouverte, ferme-la avant de démarrer la nouvelle pour permettre le nettoyage.

## Raccourcis indépendants

Dans l'onglet **À propos**, tu peux désormais installer ou supprimer séparément :

- le raccourci du Bureau ;
- le raccourci du menu Démarrer.

L'interface lit directement la présence de chaque raccourci Windows. Elle actualise les états à chaque ouverture de cet onglet. Si tu supprimes manuellement un raccourci depuis l'Explorateur, il reste supprimé : ClickFlow ne restaure plus automatiquement les raccourcis lors d'un lancement ou d'une mise à jour. Il suffit de revenir dans **À propos** pour le réinstaller.

Les anciennes préférences `shortcuts.ini` (`Enabled=1`) n'imposent plus la création de deux raccourcis. Les raccourcis historiques sont reconnus et peuvent être gérés indépendamment, sans toucher aux autres raccourcis présents sur l'ordinateur.

## Dossiers et désinstallation

Dans l'onglet **À propos** (mode étendu), les boutons **Ouvrir les fichiers du programme** et **Ouvrir les profils et paramètres** ouvrent directement l'Explorateur Windows dans :

- `%LOCALAPPDATA%\\ClickFlow` pour le lanceur local, l'icône, les runtimes et les caches WebView2 ;
- `%APPDATA%\\ClickFlow` pour les profils (`profiles\profile-*.ini`) et paramètres (`settings.ini` et ses sauvegardes).

La désinstallation propose deux opérations distinctes, avec confirmation **dans ClickFlow** :

1. **Désinstaller - conserver les données** : supprime le programme local, les anciens runtimes et caches et les raccourcis ClickFlow, mais conserve l'ensemble des profils et paramètres dans `%APPDATA%\\ClickFlow`.
2. **Tout désinstaller et effacer** : effectue les mêmes suppressions puis supprime aussi le dossier personnel `%APPDATA%\\ClickFlow`. Cette option demande de saisir `SUPPRIMER` pour éviter une suppression accidentelle.

Un petit script AutoHotkey temporaire attend la fermeture complète de ClickFlow avant de commencer la désinstallation. Aucun nouveau `.exe` n'est généré. **Les fichiers `.ahk` téléchargés hors du dossier de ClickFlow, par exemple dans Téléchargements, ne sont pas supprimés**. Les autres fichiers éventuellement placés dans le dossier local sont conservés par précaution. AutoHotkey v2, installé indépendamment, n'est pas désinstallé.

## Profils et mises à jour

Depuis v1.5.0, les profils sont conservés dans un dossier `%APPDATA%\ClickFlow\profiles`, sous la forme `profile-1.ini`, `profile-2.ini`, etc. Le fichier `%APPDATA%\ClickFlow\settings.ini` contient les préférences globales (touche d'arrêt d'urgence, mode de fenêtre) et l'identifiant du profil sélectionné.

**Migration automatique :** les profils de la v1.1.0 et des anciennes versions sont lus une seule fois depuis `settings.ini`, puis enregistrés dans des fichiers indépendants. Les anciennes sections et les sauvegardes restent disponibles par précaution. Les fichiers exportés se réimportent individuellement, sans écraser les profils déjà présents. Si un nom existe déjà, ClickFlow ajoute un suffixe numérique.

Chaque version publiée possède un numéro et son cache de composants. Télécharger et lancer un nouveau fichier `.ahk` met à jour la copie locale utilisée par les raccourcis, sans supprimer les profils.

## Les variations du mode Naturel

Le mode Naturel ne se limite plus à déplacer lentement une cible de CPS. Il combine des variations progressives, de petites irrégularités dans le délai entre les clics, des accélérations sur quelques clics et de courtes hésitations :

- **Faible** : variations sensibles (proches de l'ancien niveau Élevé), petites irrégularités, rares hésitations.
- **Moyen** : variations plus marquées, cadence plus vivante, hésitations et accélérations occasionnelles.
- **Élevé** : variation plus nerveuse, micro-délais nettement moins réguliers, quelques accélérations et hésitations plus franches.

Pour les clics ordinaires, la cadence reste dans la plage min/max CPS configurée. Une hésitation exceptionnelle peut créer un intervalle plus long (donc un CPS observé inférieur au minimum), sans rafale artificielle de rattrapage. Si les CPS minimum et maximum sont égaux, les imperfections de timing peuvent encore être visibles. Les deux autres modes, Fixe et Aléatoire, conservent leur fonctionnement.

Dans l'onglet **Test CPS**, sélectionne un profil Naturel et teste-le sur 30 ou 60 secondes : c'est le même calcul de cadence que pour les clics réels, sans clic envoyé dans les autres fenêtres.

## Utiliser le test CPS

Depuis l'onglet **Test CPS**, choisis une durée de 2, 5, 10, 30 ou 60 secondes, puis sélectionne l'un des deux modes :

- **Profil ClickFlow** (mode par défaut) : sélectionne n'importe quel profil enregistré puis clique sur **Démarrer le test**. Le test utilise le vrai cadenceur AutoHotkey du profil (modes Fixe, Aléatoire et Naturel), avec ses réglages CPS minimum/maximum et intensité. Les événements de cadence sont transmis au graphique et au compteur sans produire de clics dans Windows. Pour ce test de vitesse, ni la touche d'activation ni la condition souris ne sont nécessaires.
- **Clics manuels** : clique avec le bouton gauche dans la grande zone bleue. Le premier clic démarre le chronomètre et compte dans les résultats.

Les deux modes affichent les CPS glissants sur la dernière seconde, les CPS moyens, le pic sur une seconde, le total, une barre de progression et une courbe en direct. Une petite animation et un clic sonore synthétique (Web Audio, sans fichier externe) accompagnent les clics. Le bouton **Son activé** permet de couper le son.

Le banc de test est séparé de l'injection Windows : il mesure les déclenchements du moteur, et non la réception de clics par un jeu ou une autre application. Les clics manuels ne sont comptabilisés que dans la zone de test. L'arrêt d'urgence et le changement d'onglet interrompent le test du profil.

**Seul le dernier essai terminé reste affiché** pendant la session. Aucun résultat ni record n'est enregistré dans les fichiers personnels.

## Code source

| Chemin | Rôle |
| --- | --- |
| `src/ClickFlow-WebView2.ahk` | Lanceur de fenêtre Windows |
| `src/ClickFlow-Backend.ahk` | Moteur CPS, raccourcis, profils, sauvegarde |
| `src/ClickFlow-ProfileStore.ahk` | Fichiers individuels, migration et import/export des profils |
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
