# ClickFlow - AutoCliker

**Version stable 1.7.1 - AutoClicker pour Windows, sans application .exe à installer.**

ClickFlow est un auto-clicker Windows avec une interface graphique WebView2, un moteur AutoHotkey v2, plusieurs modes de CPS et des profils sauvegardés.

## Télécharger

Télécharger le fichier unique **[ClickFlow-v1.7.1.ahk](https://github.com/77Romain77/ClickFlow-AutoClicker/releases/tag/v1.7.1)** depuis les Releases GitHub.

**Prérequis :** Windows 10/11 64 bits, [AutoHotkey v2 64 bits](https://www.autohotkey.com/) et le runtime Microsoft WebView2 (présent sur la plupart des Windows récents).

1. Installer AutoHotkey v2 si nécessaire.
2. Télécharger `ClickFlow-v1.7.1.ahk`.
3. Double-cliquer sur ce fichier.
4. Dans l'onglet **Paramètres**, créer séparément les raccourcis Bureau et menu Démarrer si nécessaire.

Au premier lancement, ClickFlow extrait ses composants locaux dans `%LOCALAPPDATA%\ClickFlow\Runtime-1.7.1`. Aucun compilateur ni `.exe` ClickFlow n'est nécessaire. Il n'y a **pas de téléchargement automatique de mises à jour**.

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
- **Tableau de bord : mini-moniteur CPS** des 30 dernières secondes, état et CPS actuels, sans aucun historique disque.
- **Test CPS : réglages rapides** du profil sélectionné (mode, CPS min/max, intensité), avec brouillon modifiable, vérification puis Appliquer / Annuler.
- **Mini-fenêtre flottante Windows** toujours visible en option : profil, état, CPS, total, boutons Ouvrir et STOP.
- **Menu de l'icône de notification Windows** : ouvrir/restaurer, arrêter les clics, sélectionner un profil, afficher la mini-fenêtre et quitter.
- **Profils sous forme de cartes** avec favoris, ordre personnalisable, actions Activer / Tester / Exporter. Favoris et ordre sont conservés dans les fichiers des profils.
- **Onglet Paramètres dédié** pour les préférences, la gestion des raccourcis Windows, les dossiers et la désinstallation.
- Profils locaux : création, duplication, renommage et suppression. Chaque profil est enregistré dans un fichier indépendant.
- Importer ou exporter un profil individuellement au format `.ini` (menu **Profils** ou profil actif).
- Statistiques de CPS et de clics générés.
- **Onglet Test CPS** : teste directement la cadence du profil ClickFlow sélectionné ou tes clics manuels, sur 2, 5, 10, 30 ou 60 secondes.
- CPS glissants sur une seconde, CPS moyens, pic, total, progression et courbe en temps réel.
- Animation lumineuse et léger effet sonore sur les clics du test, avec bouton pour désactiver le son.
- Seul le **dernier résultat terminé** est affiché pendant la session. Aucun score ni historique n'est sauvegardé sur le disque.
- Icône dédiée et raccourcis Windows facultatifs. Le menu **À propos** permet de les gérer.

## Ajustements ergonomiques (v1.7.1)

La mini-fenêtre est plus compacte (310 x 150 au premier lancement sans taille déjà enregistrée), sans les deux gros boutons en bas. En haut, deux petits contrôles assortis au thème permettent de **basculer la courbe CPS** (CPS/OFF) ou **STOP**. Un double-clic sur le nom du profil restaure la fenêtre complète; le menu de notification propose toujours "Ouvrir l'interface". La courbe repose désormais sur un véritable contrôle bitmap Windows, ce qui corrige son absence d'affichage en v1.7.0. Elle est activée par défaut lorsqu'aucune préférence antérieure n'existe, et peut être désactivée. Les dimensions et positions déjà enregistrées sont respectées.

Le mode compact est maintenant un panneau spécifique, en petites cartes et police réduite, avec : sélection du profil, statistiques CPS/clics, arrêt, choix Fixe/Aléatoire/Naturel, valeurs CPS min/max, intensité Naturel, commandes de capture des raccourcis et courbe optionnelle. Le mode étendu et les paramètres historiques restent disponibles.

Dans les cartes de profils, l'intensité du mode Naturel apparaît sur la même ligne que le mode et la plage CPS. La touche d'activation reste seule sur la ligne suivante.

La barre de titre de l'application principale et de la mini-fenêtre utilise les options DWM de Windows pour adopter un fond sombre, lorsque prises en charge par la version de Windows. Les boutons natifs Réduire, Agrandir et Fermer restent gérés par Windows; leur forme ne peut pas être librement personnalisée sans une barre de titre entièrement dessinée par l'application.

## Ergonomie de la mini-fenêtre et du mode compact (v1.7.1)

La **mini-fenêtre** peut être redimensionnée en tirant ses bords ou ses coins (minimum 280 x 180 pixels). Sa largeur, sa hauteur et sa position sont conservées dans les paramètres généraux de ClickFlow. Si l'écran change et que sa position n'est plus accessible, elle est recentrée automatiquement. Le nom du profil a maintenant une zone prévue pour deux lignes.

Le bouton **Interface** restaure la fenêtre principale de ClickFlow. Le bouton **STOP** arrête les clics. En haut à droite, le bouton **Courbe** active ou désactive une représentation graphique des CPS réels des 30 dernières secondes, calculée dans le processus AutoHotkey existant. Quand la fenêtre est trop petite, un message indique de l'agrandir. Aucun graphique ni score n'est conservé sur le disque.

Dans **Paramètres**, tu peux aussi activer la courbe de la mini-fenêtre, régler son opacité (70, 80, 90 ou 100 %) et décider si elle reste au premier plan. La fermeture vers la zone de notification reste désactivée par défaut.

Le **mode compact** n'est plus un tableau de bord simplement raccourci : c'est un panneau de commande qui donne directement accès au profil, à l'état du moteur, aux CPS en direct, aux CPS min/max, aux trois modes, à l'intensité du mode Naturel, au raccourci d'activation, à la touche d'arrêt d'urgence et au bouton STOP. La courbe compacte peut être masquée séparément dans Paramètres. Les options avancées, les imports, les exports et les profils détaillés restent dans le mode étendu.

Les cartes de profils présentent désormais la réorganisation dans une zone dédiée avec deux flèches de taille stable. Le menu Windows utilise exclusivement les noms de profils enregistrés, sans préfixe numérique interne.

## Espace de travail et zone de notification (v1.7.1)

Le tableau de bord peut montrer une courbe des CPS envoyés sur les **30 dernières secondes**. Cette courbe est locale à la session et ne sauvegarde ni score ni historique. L'affichage est désactivable dans **Paramètres**. La fenêtre flottante, accessible depuis le tableau de bord, Paramètres ou le menu de notification, affiche le profil courant, son état et le nombre de clics. Elle possède un bouton STOP et un bouton pour ouvrir l'interface principale.

ClickFlow propose un menu dans la zone de notification Windows, à côté de l'horloge. Il permet de restaurer la fenêtre, de stopper les clics, de choisir un profil et de **quitter** complètement. Dans Paramètres, tu peux activer séparément **Réduire dans la zone de notification** et **Fermer vers la zone de notification**. Ces deux options sont désactivées par défaut : sans les activer, le bouton X quitte ClickFlow comme avant. Si tu actives la fermeture vers la zone de notification, le bouton X ne quitte plus l'application : utilise **Quitter ClickFlow** dans le menu de l'icône.

Le nouvel écran Profils comporte des cartes avec le mode CPS, le raccourci, un favori et des boutons **Activer**, **Tester**, **Exporter** et **Monter / Descendre**. L'ordre et les favoris sont enregistrés dans chaque fichier `profile-<id>.ini`, et les anciens profils sont importés sans perte de leurs réglages.

Dans le Test CPS, sélectionne un profil puis modifie les paramètres dans le panneau de réglages rapides. Ils restent **en brouillon** jusqu'au clic sur **Appliquer au profil**. Le bouton **Annuler** restaure les valeurs existantes. Le test du profil reste bloqué tant que le brouillon contient des modifications non appliquées. Les changements n'affectent que le profil choisi et conservent son raccourci et ses options de sécurité. Le test lui-même n'injecte aucun clic Windows.

## Lancer ClickFlow plusieurs fois et nettoyer les caches

Si ClickFlow est déjà ouvert, un nouveau lancement **ne ferme plus l'application en cours** : la fenêtre existante est remise au premier plan. Ceci évite le crash WebView2 observé lors d'un lancement multiple avec v1.0.0.

Après un démarrage réussi d'une nouvelle version, ClickFlow supprime automatiquement les anciens dossiers de programme de la forme `Runtime-X.Y.Z` créés par son lanceur. Il conserve le dossier courant, les paramètres, les profils, `ClickFlow.ahk`, `ClickFlow.ico`, `shortcuts.ini` et les dossiers de données WebView2. Si une ancienne version est encore ouverte, ferme-la avant de démarrer la nouvelle pour permettre le nettoyage.

## Raccourcis indépendants

Dans l'onglet **Paramètres**, tu peux installer ou supprimer séparément :

- le raccourci du Bureau ;
- le raccourci du menu Démarrer.

L'interface lit directement la présence de chaque raccourci Windows. Elle actualise les états à chaque ouverture de cet onglet. Si tu supprimes manuellement un raccourci depuis l'Explorateur, il reste supprimé : ClickFlow ne restaure plus automatiquement les raccourcis lors d'un lancement ou d'une mise à jour. Il suffit de revenir dans **Paramètres** pour le réinstaller.

Les anciennes préférences `shortcuts.ini` (`Enabled=1`) n'imposent plus la création de deux raccourcis. Les raccourcis historiques sont reconnus et peuvent être gérés indépendamment, sans toucher aux autres raccourcis présents sur l'ordinateur.

## Dossiers et désinstallation

Dans l'onglet **Paramètres** (mode étendu), les boutons **Ouvrir les fichiers du programme** et **Ouvrir les profils et paramètres** ouvrent directement l'Explorateur Windows dans :

- `%LOCALAPPDATA%\\ClickFlow` pour le lanceur local, l'icône, les runtimes et les caches WebView2 ;
- `%APPDATA%\\ClickFlow` pour les profils (`profiles\profile-*.ini`) et paramètres (`settings.ini` et ses sauvegardes).

La désinstallation propose deux opérations distinctes, avec confirmation **dans ClickFlow** :

1. **Désinstaller - conserver les données** : supprime le programme local, les anciens runtimes et caches et les raccourcis ClickFlow, mais conserve l'ensemble des profils et paramètres dans `%APPDATA%\\ClickFlow`.
2. **Tout désinstaller et effacer** : effectue les mêmes suppressions puis supprime aussi le dossier personnel `%APPDATA%\\ClickFlow`. Cette option demande de saisir `SUPPRIMER` pour éviter une suppression accidentelle.

Un petit script AutoHotkey temporaire attend la fermeture complète de ClickFlow avant de commencer la désinstallation. Aucun nouveau `.exe` n'est généré. **Les fichiers `.ahk` téléchargés hors du dossier de ClickFlow, par exemple dans Téléchargements, ne sont pas supprimés**. Les autres fichiers éventuellement placés dans le dossier local sont conservés par précaution. AutoHotkey v2, installé indépendamment, n'est pas désinstallé.

## Profils et mises à jour

Depuis v1.7.1, les profils sont conservés dans un dossier `%APPDATA%\ClickFlow\profiles`, sous la forme `profile-1.ini`, `profile-2.ini`, etc. Le fichier `%APPDATA%\ClickFlow\settings.ini` contient les préférences globales (touche d'arrêt d'urgence, mode de fenêtre) et l'identifiant du profil sélectionné.

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
