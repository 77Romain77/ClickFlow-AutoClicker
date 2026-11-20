# ClickFlow - AutoCliker

**Version stable 1.9.4 - AutoClicker pour Windows, sans application .exe à installer.**

ClickFlow est un auto-clicker Windows avec une interface graphique WebView2, un moteur AutoHotkey v2, plusieurs modes de CPS et des profils sauvegardés.

## Télécharger

Télécharger le fichier unique **[ClickFlow-v1.9.4.ahk](https://github.com/77Romain77/ClickFlow-AutoClicker/releases/tag/v1.9.4)** depuis les Releases GitHub.

**Prérequis :** Windows 10/11 64 bits, [AutoHotkey v2 64 bits](https://www.autohotkey.com/) et le runtime Microsoft WebView2 (présent sur la plupart des Windows récents).

1. Installer AutoHotkey v2 si nécessaire.
2. Télécharger `ClickFlow-v1.9.4.ahk`.
3. Double-cliquer sur ce fichier.
4. Dans l'onglet **Paramètres**, créer séparément les raccourcis Bureau et menu Démarrer si nécessaire.

Au premier lancement, ClickFlow extrait ses composants locaux dans `%LOCALAPPDATA%\ClickFlow\Runtime-1.9.4`. Aucun compilateur ni `.exe` ClickFlow n'est nécessaire. Il n'y a **pas de téléchargement automatique de mises à jour**.

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
- **Overlay de statut léger** en option : état ACTIF/EN ATTENTE/ARRÊTÉ et CPS moyens sur une période réglable de 1 à 60 secondes (5 secondes par défaut), transparent aux clics et positionnable sur plusieurs écrans.
- **Menu de l'icône de notification Windows** : ouvrir/restaurer, arrêter les clics, sélectionner un profil, afficher l'overlay et quitter.
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

## Précision du cadenceur et diagnostic (v1.9.4)

Le moteur passe d'un timer AutoHotkey périodique (arrondi par Windows à 10-15,6 ms) à une boucle coopérative utilisant de courtes attentes Win32. La résolution Windows de 1 ms est demandée uniquement pendant les clics ou le Test CPS, puis immédiatement restaurée à l'arrêt. Aucun timer moteur actif au repos. Les touches et l'interface restent traitées entre les attentes, qui ne bloquent jamais plus de 8 ms d'affilée. La précision reste dépendante de la charge du PC et des règles Windows 11 lorsque la fenêtre est masquée.

Dans Test CPS, le dernier résultat d'un profil fixe indique la cible, l'écart mesuré et l'intervalle moyen, sans clics Windows. Le champ "Diagnostic du premier clic réel" mesure l'intervalle logiciel depuis la réception du raccourci jusqu'au retour de SendInput lors d'une activation réelle dans une autre fenêtre. Ce n'est **pas** une mesure du délai matériel ni de la réaction du jeu. Aucun diagnostic n'est enregistré sur disque.

La CI ajoute trois mesures courtes (10, 50 et 100 CPS) dans le job Windows existant, sans nouveau workflow.

## Performance et latence du premier clic (v1.9.3)

Le moteur AutoHotkey n'effectue plus de vérifications de clic toutes les 10 ms lorsqu'il est au repos. Il active ce timer uniquement pendant les clics ou un Test CPS, puis le désactive immédiatement à l'arrêt. Les statistiques sont actualisées toutes les 1000 ms au repos, contre 200 ms pendant une session active.

Le premier clic est envoyé directement dans le callback de la touche d'activation (Maintenir comme Basculer), une fois les contrôles de fenêtre et de condition souris validés, sans attendre le timer. Le clic suivant est programmé à partir de cet envoi, pour conserver les CPS du profil et éviter les doubles clics. Si la condition souris n'est pas remplie, aucun premier clic n'est injecté tant qu'elle n'est pas satisfaite.

L'overlay conserve son délai de disparition d'environ 2,2 s après l'arrêt. Les raccourcis globaux, les sauvegardes, les profils et les réglages ne changent pas. Un test Windows mesure l'activité CPU du moteur au repos et vérifie le départ immédiat, la cadence et les arrêts.

## Correction de la capture des raccourcis (v1.9.4)

Dans **Paramètres > Raccourcis globaux**, clique sur la touche d'une action puis appuie sur la touche souhaitée **dans la fenêtre ClickFlow**. La frappe est lue directement par l'interface WebView2 et transmise au moteur AutoHotkey pour vérification et sauvegarde. La liste ne reste plus bloquée sur "Appuyez...". Appuie sur **Échap** pour annuler, ou sur **Aucun** pour supprimer la touche. Pour l'arrêt d'urgence, ce dernier choix désactive réellement le raccourci et laisse les commandes d'arrêt de l'interface et de la zone de notification opérationnelles.

## Arrêt d'urgence facultatif (v1.9.4)

Dans **Paramètres > Raccourcis globaux**, l'arrêt d'urgence figure maintenant avec les autres actions. Sa touche initiale reste **F12** pour les installations existantes, mais le bouton **Aucun** permet de ne définir aucune touche. La modification est la même que celle affichée sur le tableau de bord, et la préférence est conservée après redémarrage et restauration d'une sauvegarde complète.

Attention : lorsque le raccourci d'urgence est désactivé, il reste possible d'arrêter les clics avec le bouton **Arrêter les clics** de l'interface, ou depuis l'icône ClickFlow dans la zone de notification Windows. Les autres raccourcis globaux restent facultatifs et non attribués par défaut.

## Nouveautés v1.9.4 : raccourcis, sauvegarde et organisation

Dans **Paramètres > Raccourcis globaux**, tu peux attribuer une touche à chacune des actions suivantes : profil suivant, profil précédent, basculer l'overlay, ouvrir l'interface et ouvrir le Test CPS. **Toutes les actions sont sur "Aucun" par défaut** et ne font rien tant que tu ne leur attribues pas une touche. Pour retirer une touche, clique sur **Aucun**. Échap annule la capture. ClickFlow refuse les collisions avec les autres actions et les touches des profils. L'arrêt d'urgence est affiché dans cette même section : F12 par défaut, mais il peut aussi être mis sur Aucun.

Dans **Paramètres > Sauvegarde complète**, clique sur **Sauvegarder tout (.zip)** pour exporter **settings.ini et les fichiers de tous les profils**, favoris et ordre compris. Pour récupérer les données sur un autre PC, clique sur **Restaurer une sauvegarde** et sélectionne le ZIP. ClickFlow arrête les clics et demande confirmation, vérifie les fichiers avant toute modification, puis recharge les réglages. Si une erreur intervient pendant le remplacement, il tente de restaurer automatiquement les données précédentes. Les programmes, caches WebView2 et fichiers d'installation ne font pas partie de cette sauvegarde.

Dans **Paramètres > Overlay**, les nouvelles options **Taille** (mini, standard, grande) et **Afficher le nom du profil** sont indépendantes de la transparence libre, de la durée CPS, de la position et du multi-écran. La taille mini (216 x 34 px) et le nom caché restent les valeurs par défaut.

L'onglet **Paramètres** est désormais réparti en six catégories repliables : Général, Overlay, Raccourcis globaux, Raccourcis Windows, Sauvegarde complète et Maintenance.

## Durée personnalisable des CPS moyens (v1.9.4)

Dans **Paramètres > Overlay**, le champ **Période CPS moyens** accepte une durée entière de **1 à 60 secondes**. La valeur initiale est de **5 secondes**. Elle est sauvegardée dans `settings.ini` et conservée entre les lancements. L'overlay affiche la moyenne calculée à partir des clics réellement envoyés sur la période choisie (ou depuis le début de l'activation si la session est plus courte).

Le réglage change uniquement le calcul de la moyenne dans l'overlay. Il ne modifie ni la cadence des profils, ni la taille de l'overlay, ni le moniteur CPS du tableau de bord. Les mesures restent en mémoire et ne sont pas archivées.

## Lisibilité de l'overlay (v1.9.4)

Le statut et les CPS moyens sont maintenant placés sur **une seule ligne compacte** (216 x 34 pixels). L'overlay a des coins discrètement arrondis et une police ajustée à la mise à l'échelle Windows, de façon à éviter les textes coupés sans augmenter inutilement sa taille. Les six positions, le déplacement libre, la transparence de 0 à 100 % et le comportement automatique sont inchangés.

## Overlay de statut (v1.9.4)

L'ancienne mini-fenêtre flottante et sa courbe GDI sont supprimées. À la place, ClickFlow propose un **overlay discret** sans barre de titre, visible au-dessus des fenêtres classiques et des jeux en mode fenêtré ou sans bordure (le plein écran exclusif n'est pas garanti). Il affiche uniquement le statut **ACTIF / EN ATTENTE / ARRÊTÉ** et les **CPS moyens sur les 5 dernières secondes**, calculés à partir des clics réellement envoyés par ClickFlow. Aucun score ni historique n'est conservé sur le disque.

L'overlay est **transparent aux clics** : il ne bloque pas la souris. Par défaut, il s'affiche pendant la période d'activation et disparaît environ 2 secondes après l'arrêt. Dans **Paramètres**, on peut activer l'affichage permanent.

Dans **Paramètres > Overlay**, tu peux :
- choisir l'une des **6 positions** : haut gauche, haut milieu, haut droite, bas gauche, bas milieu ou bas droite ;
- choisir le **moniteur**, lorsque plusieurs écrans sont connectés ;
- ajuster la **marge de 0 à 100 pixels** ;
- saisir **n'importe quelle transparence entière de 0 à 100 %** (0 % rend l'overlay invisible) ;
- cliquer sur **Déplacer librement l'overlay**, puis le glisser avec la souris à l'endroit exact souhaité et cliquer sur **Terminer le placement**. Cette opération réactive immédiatement la transparence aux clics. La position personnalisée est mémorisée.

L'icône de notification Windows permet toujours d'activer/désactiver l'overlay, changer de profil, arrêter les clics et ouvrir l'interface principale. Les profils existants sont conservés.

La fenêtre principale de ClickFlow **s'ouvre centrée** sur un moniteur disponible. Sa taille est limitée à la zone visible pour éviter une fenêtre à moitié hors écran après un changement de résolution ou de moniteur. Chaque mode compact/étendu conserve sa taille propre.

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

Depuis v1.9.4, les profils sont conservés dans un dossier `%APPDATA%\ClickFlow\profiles`, sous la forme `profile-1.ini`, `profile-2.ini`, etc. Le fichier `%APPDATA%\ClickFlow\settings.ini` contient les préférences globales (touche d'arrêt d'urgence, mode de fenêtre) et l'identifiant du profil sélectionné.

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
